import spawn from 'cross-spawn';
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

interface YtDlpSubtitlesInfo {
  automatic_captions?: Record<string, SubtitleFormat[]>;
  subtitles?: Record<string, SubtitleFormat[]>;
}

interface CaptionCandidate {
  langCode: string;
  source: 'subtitles' | 'automatic_captions';
  format: SubtitleFormat;
}

const SUPPORTED_CAPTION_EXT_PRIORITY = ['json3', 'vtt'];

const LANG_MAP: Record<Language, string[]> = {
  uk: ['uk', 'ukr'],
  uk_18: ['uk', 'ukr'],
  en: ['en', 'en-US', 'en-GB'],
  ru: ['ru', 'rus'],
};

export class YtDlpDataSource {
  constructor(private readonly storagePath: string) { }

  async checkDependencies(): Promise<void> {
    try {
      await ytDlp('--version', { version: true });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('yt_dlp_dependency_check_failed', `yt-dlp not found or not working: ${msg}`, { layer: 'data' });
      throw new AppError('DEPENDENCY_MISSING', `yt-dlp is required but could not be executed: ${msg}`, 500);
    }
  }

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
        subLang: 'all',
      }) as YtDlpSubtitlesInfo;

      const manualCaptions = info.subtitles ?? {};
      const automaticCaptions = info.automatic_captions ?? {};
      const candidate = this.selectCaptionCandidate(
        manualCaptions,
        automaticCaptions,
        langCodes,
      );

      if (!candidate) {
        logger.warn('yt_dlp_get_captions_empty', 'No supported caption tracks found', {
          layer: 'data',
          durationMs: Date.now() - start,
          data: {
            url,
            language,
            langCodes,
            availableSubtitleLangs: Object.keys(manualCaptions),
            availableAutoCaptionLangs: Object.keys(automaticCaptions),
          },
        });
        return [];
      }

      const response = await fetch(candidate.format.url);
      if (!response.ok) {
        throw new Error(`Failed to download subtitles: ${response.status} ${response.statusText}`);
      }

      const subtitleBody = await response.text();
      const ext = candidate.format.ext.toLowerCase();
      const segments = ext === 'json3'
        ? this.parseJson3Captions(subtitleBody)
        : this.parseVttCaptions(subtitleBody);

      logger.info('yt_dlp_get_captions_done', 'Captions fetched', {
        layer: 'data',
        durationMs: Date.now() - start,
        data: {
          segmentCount: segments.length,
          selectedLangCode: candidate.langCode,
          selectedSource: candidate.source,
          selectedExt: candidate.format.ext,
        },
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

  async downloadVideo(url: string, jobId: string, onProgress?: (percent: number) => void): Promise<string> {
    const outputPath = path.join(this.storagePath, 'videos', `${jobId}.%(ext)s`);
    const start = Date.now();
    logger.info('yt_dlp_download_start', 'Downloading video with progress tracking', { layer: 'data', jobId, data: { url } });

    try {
      return await new Promise<string>((resolve, reject) => {
        const args = [
          url,
          '--output', outputPath,
          '--format', 'bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best',
          '--merge-output-format', 'mp4',
          '--no-warnings',
          '--no-check-certificate',
          '--newline',
        ];

        const child = spawn('yt-dlp', args);

        child.stdout?.on('data', (data: Buffer) => {
          const line = data.toString().trim();
          // Example: [download]  10.0% of 100.00MiB at 10.00MiB/s ETA 00:09
          const match = line.match(/\[download\]\s+(\d+\.\d+)%/);
          if (match && match[1]) {
            const percent = parseFloat(match[1]);
            onProgress?.(percent);
          }
        });

        child.stderr?.on('data', (data: Buffer) => {
          const line = data.toString().trim();
          if (line && !line.includes('WARNING')) {
            logger.warn('yt_dlp_download_stderr', line, { layer: 'data', jobId });
          }
        });

        child.on('close', (code: number | null) => {
          if (code === 0) {
            const finalPath = path.join(this.storagePath, 'videos', `${jobId}.mp4`);
            logger.info('yt_dlp_download_done', 'Video downloaded successfully', {
              layer: 'data',
              jobId,
              durationMs: Date.now() - start,
              data: { finalPath },
            });
            resolve(finalPath);
          } else {
            reject(new AppError('DOWNLOAD_FAILED', `yt-dlp exited with code ${code}`, 502));
          }
        });

        child.on('error', (err: Error) => {
          reject(new AppError('DOWNLOAD_FAILED', `Failed to start yt-dlp: ${err.message}`, 502));
        });
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('yt_dlp_download_failed', msg, {
        layer: 'data',
        jobId,
        durationMs: Date.now() - start,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
        data: { url },
      });
      throw err instanceof AppError ? err : new AppError('DOWNLOAD_FAILED', `Failed to download video: ${msg}`, 502);
    }
  }

  private selectCaptionCandidate(
    subtitles: Record<string, SubtitleFormat[]>,
    automaticCaptions: Record<string, SubtitleFormat[]>,
    preferredLangCodes: string[],
  ): CaptionCandidate | null {
    const preferredManual = this.pickCandidateByLangCodes(
      subtitles,
      preferredLangCodes,
      'subtitles',
    );
    if (preferredManual) return preferredManual;

    const preferredAuto = this.pickCandidateByLangCodes(
      automaticCaptions,
      preferredLangCodes,
      'automatic_captions',
    );
    if (preferredAuto) return preferredAuto;

    const anyManual = this.pickAnyCandidate(subtitles, 'subtitles');
    if (anyManual) return anyManual;

    return this.pickAnyCandidate(automaticCaptions, 'automatic_captions');
  }

  private pickCandidateByLangCodes(
    captions: Record<string, SubtitleFormat[]>,
    langCodes: string[],
    source: 'subtitles' | 'automatic_captions',
  ): CaptionCandidate | null {
    for (const code of langCodes) {
      const formats = captions[code];
      const format = this.pickSupportedFormat(formats);
      if (format) {
        return { langCode: code, source, format };
      }
    }
    return null;
  }

  private pickAnyCandidate(
    captions: Record<string, SubtitleFormat[]>,
    source: 'subtitles' | 'automatic_captions',
  ): CaptionCandidate | null {
    for (const [langCode, formats] of Object.entries(captions)) {
      const format = this.pickSupportedFormat(formats);
      if (format) {
        return { langCode, source, format };
      }
    }
    return null;
  }

  private pickSupportedFormat(formats?: SubtitleFormat[]): SubtitleFormat | null {
    if (!formats || formats.length === 0) return null;

    for (const ext of SUPPORTED_CAPTION_EXT_PRIORITY) {
      const match = formats.find((f) => f.ext.toLowerCase() === ext);
      if (match) return match;
    }
    return null;
  }

  private parseJson3Captions(rawJson: string): TranscriptSegment[] {
    const subtitleData = JSON.parse(rawJson) as {
      events?: Array<{
        tStartMs?: number;
        dDurationMs?: number;
        segs?: Array<{ utf8?: string }>;
      }>;
    };

    const segments: TranscriptSegment[] = [];
    for (const event of subtitleData.events || []) {
      if (!event.segs) continue;

      const text = this.normalizeCaptionText(
        event.segs.map((s) => s.utf8 || '').join(''),
      );
      if (!text) continue;

      const startSec = (event.tStartMs || 0) / 1000;
      const durationSec = (event.dDurationMs || 0) / 1000;
      const endSec = durationSec > 0 ? startSec + durationSec : startSec + 2;
      segments.push({
        startSec,
        endSec,
        text,
      });
    }

    return segments;
  }

  private parseVttCaptions(rawVtt: string): TranscriptSegment[] {
    const blocks = rawVtt.replace(/\r/g, '').split(/\n{2,}/);
    const segments: TranscriptSegment[] = [];

    for (const block of blocks) {
      const lines = block
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line.length > 0);
      if (lines.length === 0) continue;
      const firstLine = lines[0];
      if (!firstLine) continue;
      if (firstLine === 'WEBVTT' || firstLine.startsWith('NOTE')) continue;

      const timelineIndex = lines.findIndex((line) => line.includes('-->'));
      if (timelineIndex < 0) continue;
      const timelineLine = lines[timelineIndex];
      if (!timelineLine) continue;

      const [rawStart, rawEndAndMeta] = timelineLine.split('-->');
      if (!rawStart || !rawEndAndMeta) continue;

      const startSec = this.parseVttTimestamp(rawStart.trim());
      const endToken = rawEndAndMeta.trim().split(' ')[0] ?? '';
      if (!endToken) continue;
      const parsedEndSec = this.parseVttTimestamp(endToken);
      if (startSec == null || parsedEndSec == null) continue;

      const captionLines = lines.slice(timelineIndex + 1);
      const text = this.normalizeCaptionText(
        captionLines.join(' ').replace(/<[^>]*>/g, ''),
      );
      if (!text) continue;

      const endSec = parsedEndSec > startSec ? parsedEndSec : startSec + 2;
      segments.push({
        startSec,
        endSec,
        text,
      });
    }

    return segments;
  }

  private parseVttTimestamp(value: string): number | null {
    const normalized = value.replace(',', '.');
    const parts = normalized.split(':');
    const numbers = parts.map((part) => Number(part));
    if (numbers.some((n) => Number.isNaN(n))) return null;

    if (numbers.length === 3) {
      const hours = numbers[0];
      const minutes = numbers[1];
      const seconds = numbers[2];
      if (hours == null || minutes == null || seconds == null) return null;
      return hours * 3600 + minutes * 60 + seconds;
    }
    if (numbers.length === 2) {
      const minutes = numbers[0];
      const seconds = numbers[1];
      if (minutes == null || seconds == null) return null;
      return minutes * 60 + seconds;
    }
    if (numbers.length === 1) {
      return numbers[0] ?? null;
    }
    return null;
  }

  private normalizeCaptionText(value: string): string {
    return value.replace(/\\n/g, ' ').replace(/\s+/g, ' ').trim();
  }
}
