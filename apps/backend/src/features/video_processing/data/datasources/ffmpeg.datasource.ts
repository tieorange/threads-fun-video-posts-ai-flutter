import ffmpeg from 'fluent-ffmpeg';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

export interface IFfmpegDataSource {
  cutClip(inputPath: string, startSec: number, durationSec: number, outputPath: string): Promise<void>;
}

export class FfmpegDataSource implements IFfmpegDataSource {
  cutClip(inputPath: string, startSec: number, durationSec: number, outputPath: string): Promise<void> {
    const start = Date.now();
    logger.info('ffmpeg_cut_clip_start', 'Starting ffmpeg cut', {
      layer: 'data',
      data: { inputPath, startSec, durationSec, outputPath },
    });

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .setStartTime(startSec)
        .setDuration(durationSec)
        .output(outputPath)
        .videoCodec('libx264')
        .audioCodec('aac')
        .outputOptions([
          '-preset', 'veryfast',
          '-crf', '24',
          '-vf', "scale='min(1280,iw)':-2,fps=30",
          '-pix_fmt', 'yuv420p',
          '-b:a', '96k',
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
