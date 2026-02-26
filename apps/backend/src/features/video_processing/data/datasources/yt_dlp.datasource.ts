import ytDlp from 'yt-dlp-exec';
import path from 'path';
import { Language } from '../../domain/entities/ai_moments_payload.js';
import { TranscriptSegment } from '../../domain/entities/transcript_segment.js';
import { VideoMetadata } from '../../domain/entities/video_metadata.js';
import { AppError } from '../../../../core/errors/app_error.js';

interface YtDlpMetadata {
  id: string;
  title: string;
  duration: number;
  webpage_url: string;
}

interface SubtitleEntry {
  start: number;
  end: number;
  text: string;
}

const LANG_MAP: Record<Language, string[]> = {
  uk: ['uk', 'ukr'],
  uk_18: ['uk', 'ukr'],
  en: ['en', 'en-US', 'en-GB'],
  ru: ['ru', 'rus'],
};

export class YtDlpDataSource {
  constructor(private readonly storagePath: string) {}

  async getMetadata(url: string): Promise<VideoMetadata> {
    try {
      const info = await ytDlp(url, {
        dumpSingleJson: true,
        noWarnings: true,
        noCallHome: true,
        noCheckCertificate: true,
        preferFreeFormats: true,
        skipDownload: true,
      }) as YtDlpMetadata;

      return {
        videoId: info.id,
        title: info.title,
        durationSec: info.duration,
        sourceUrl: info.webpage_url,
      };
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new AppError('TRANSCRIPT_FETCH_FAILED', `Failed to fetch metadata: ${msg}`, 502);
    }
  }

  async getCaptions(url: string, language: Language): Promise<TranscriptSegment[]> {
    try {
      const langCodes = LANG_MAP[language];
      const tempDir = path.join(this.storagePath, 'captions');

      const info = await ytDlp(url, {
        dumpSingleJson: true,
        noWarnings: true,
        skipDownload: true,
        writeAutoSub: true,
        subLang: langCodes.join(','),
        subFormat: 'json3',
        paths: tempDir,
      }) as { automatic_captions?: Record<string, SubtitleEntry[]>; subtitles?: Record<string, SubtitleEntry[]> };

      const captions = info.automatic_captions ?? info.subtitles ?? {};
      const entries = this.findBestCaptions(captions, langCodes);

      if (entries.length === 0) {
        return [];
      }

      return entries.map((e) => ({
        startSec: e.start,
        endSec: e.end,
        text: e.text.trim(),
      }));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new AppError('TRANSCRIPT_FETCH_FAILED', `Failed to fetch captions: ${msg}`, 502);
    }
  }

  async downloadVideo(url: string, jobId: string): Promise<string> {
    const outputPath = path.join(this.storagePath, 'videos', `${jobId}.%(ext)s`);
    try {
      await ytDlp(url, {
        output: outputPath,
        format: 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        noWarnings: true,
        noCallHome: true,
        noCheckCertificate: true,
      });
      return path.join(this.storagePath, 'videos', `${jobId}.mp4`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new AppError('DOWNLOAD_FAILED', `Failed to download video: ${msg}`, 502);
    }
  }

  private findBestCaptions(
    captions: Record<string, SubtitleEntry[]>,
    langCodes: string[],
  ): SubtitleEntry[] {
    for (const code of langCodes) {
      const entries = captions[code];
      if (entries && entries.length > 0) {
        return entries;
      }
    }
    return [];
  }
}
