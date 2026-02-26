import ffmpeg from 'fluent-ffmpeg';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

export interface IFfmpegDataSource {
  cutClip(inputPath: string, startSec: number, durationSec: number, outputPath: string): Promise<void>;
}

export interface ClipOptions {
  preset: string;
  crf: number;
  maxHeight: number;
  fps: number;
  audioBitrate: string;
}

export class FfmpegDataSource implements IFfmpegDataSource {
  constructor(private readonly options: ClipOptions) { }

  async checkDependencies(): Promise<void> {
    return new Promise((resolve, reject) => {
      ffmpeg.getAvailableCodecs((err, _codecs) => {
        if (err) {
          logger.error('ffmpeg_dependency_check_failed', `ffmpeg not found or not working: ${err.message}`, { layer: 'data' });
          reject(new AppError('DEPENDENCY_MISSING', `ffmpeg is required but could not be executed: ${err.message}`, 500));
        } else {
          resolve();
        }
      });
    });
  }

  cutClip(inputPath: string, startSec: number, durationSec: number, outputPath: string): Promise<void> {
    const start = Date.now();
    logger.info('ffmpeg_cut_clip_start', 'Starting ffmpeg cut', {
      layer: 'data',
      data: { inputPath, startSec, durationSec, outputPath, options: this.options },
    });

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .setStartTime(startSec)
        .setDuration(durationSec)
        .output(outputPath)
        .videoCodec('libx264')
        .audioCodec('aac')
        .outputOptions([
          '-preset', this.options.preset,
          '-crf', this.options.crf.toString(),
          '-vf', `scale='min(1280,iw)':-2,fps=${this.options.fps}`,
          '-pix_fmt', 'yuv420p',
          '-b:a', this.options.audioBitrate,
          '-movflags', '+faststart',
        ])
        .on('end', () => {
          logger.info('ffmpeg_cut_clip_done', 'Clip cut successfully', {
            layer: 'data',
            durationMs: Date.now() - start,
            data: { outputPath },
          });
          resolve();
        })
        .on('error', (err: Error) => {
          logger.error('ffmpeg_cut_clip_failed', err.message, {
            layer: 'data',
            durationMs: Date.now() - start,
            ...(err.stack ? { stack: err.stack } : {}),
            data: { inputPath, startSec, durationSec, outputPath },
          });
          reject(new AppError('CLIP_CUT_FAILED', `FFmpeg error: ${err.message}`, 500));
        })
        .run();
    });
  }
}
