import ytDlp from 'yt-dlp-exec';
import path from 'path';
import { Language } from '../../domain/entities/ai_moments_payload';
import { TranscriptSegment } from '../../domain/entities/transcript_segment';
import { VideoMetadata } from '../../domain/entities/video_metadata';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

interface YtDlpMetadata {
  id: string;
  title: string;
  duration: number;
  webpage_url: string;
}

interface SubtitleFormat {
  ext: string;
  url: string;
  name?: string;
}

const LANG_MAP: Record<Language, string[]> = {
  uk: ['uk', 'ukr'],
  uk_18: ['uk', 'ukr'],
  en: ['en', 'en-US', 'en-GB'],
  ru: ['ru', 'rus'],
};

export class YtDlpDataSource {
  constructor(private readonly storagePath: string) { }

  async getMetadata(url: string): Promise<VideoMetadata> {
    const start = Date.now();
    logger.info('yt_dlp_get_metadata_start', 'Fetching video metadata', { layer: 'data', data: { url } });
    try {
      const info = await ytDlp(url, {
        dumpSingleJson: true,
        noWarnings: true,
        noCheckCertificate: true,
        skipDownload: true,
      }) as YtDlpMetadata;

      logger.info('yt_dlp_get_metadata_done', 'Metadata fetched', {
        layer: 'data',
        durationMs: Date.now() - start,
        data: { videoId: info.id, title: info.title, durationSec: info.duration },
      });

      return {
        videoId: info.id,
        title: info.title,
        durationSec: info.duration,
        sourceUrl: info.webpage_url,
      };
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('yt_dlp_get_metadata_failed', msg, {
        layer: 'data',
        durationMs: Date.now() - start,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
        data: { url },
      });
      throw new AppError('TRANSCRIPT_FETCH_FAILED', `Failed to fetch metadata: ${msg}`, 502);
    }
  }

  async getCaptions(url: string, language: Language): Promise<TranscriptSegment[]> {
    const start = Date.now();
    logger.info('yt_dlp_get_captions_start', 'Fetching captions', { layer: 'data', data: { url, language } });
    try {
      const langCodes = LANG_MAP[language];

      const info = await ytDlp(url, {
        dumpSingleJson: true,
        noWarnings: true,
        skipDownload: true,
        writeSub: true,
        writeAutoSub: true,
        subLang: langCodes.join(','),
        subFormat: 'json3',
      }) as { automatic_captions?: Record<string, SubtitleFormat[]>; subtitles?: Record<string, SubtitleFormat[]> };

      const captions = info.subtitles ?? info.automatic_captions ?? {};
      const formats = this.findBestCaptions(captions, langCodes);
      const json3Format = formats.find((f) => f.ext === 'json3');

      if (!json3Format) {
        logger.warn('yt_dlp_get_captions_empty', 'No json3 captions found', {
          layer: 'data',
          durationMs: Date.now() - start,
          data: { url, language, langCodes },
        });
        return [];
      }

      const response = await fetch(json3Format.url);
      if (!response.ok) {
        throw new Error(`Failed to download json3 subtitles: ${response.statusText}`);
      }

      const subtitleData = await response.json() as {
        events?: Array<{
          tStartMs?: number;
          dDurationMs?: number;
          segs?: Array<{ utf8?: string }>;
        }>;
      };

      const segments: TranscriptSegment[] = [];
      for (const event of subtitleData.events || []) {
        if (!event.segs) continue;
        const text = event.segs.map((s) => s.utf8 || '').join('').trim();
        if (!text || text === '\\n') continue;

        const startSec = (event.tStartMs || 0) / 1000;
        const durationSec = (event.dDurationMs || 0) / 1000;
        segments.push({
          startSec,
          endSec: startSec + durationSec,
          text,
        });
      }

      logger.info('yt_dlp_get_captions_done', 'Captions fetched', {
        layer: 'data',
        durationMs: Date.now() - start,
        data: { segmentCount: segments.length },
      });

      return segments;
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('yt_dlp_get_captions_failed', msg, {
        layer: 'data',
        durationMs: Date.now() - start,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
        data: { url, language },
      });
      throw new AppError('TRANSCRIPT_FETCH_FAILED', `Failed to fetch captions: ${msg}`, 502);
    }
  }

  async downloadVideo(url: string, jobId: string): Promise<string> {
    const outputPath = path.join(this.storagePath, 'videos', `${jobId}.%(ext)s`);
    const start = Date.now();
    logger.info('yt_dlp_download_start', 'Downloading video', { layer: 'data', jobId, data: { url } });
    try {
      await ytDlp(url, {
        output: outputPath,
        format: 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        mergeOutputFormat: 'mp4',
        noWarnings: true,
        noCheckCertificate: true,
      });
      const finalPath = path.join(this.storagePath, 'videos', `${jobId}.mp4`);
      logger.info('yt_dlp_download_done', 'Video downloaded', {
        layer: 'data',
        jobId,
        durationMs: Date.now() - start,
        data: { finalPath },
      });
      return finalPath;
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('yt_dlp_download_failed', msg, {
        layer: 'data',
        jobId,
        durationMs: Date.now() - start,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
        data: { url },
      });
      throw new AppError('DOWNLOAD_FAILED', `Failed to download video: ${msg}`, 502);
    }
  }

  private findBestCaptions(
    captions: Record<string, SubtitleFormat[]>,
    langCodes: string[],
  ): SubtitleFormat[] {
    for (const code of langCodes) {
      const formats = captions[code];
      if (formats && formats.length > 0) {
        return formats;
      }
    }
    return [];
  }
}
