import ffmpeg from 'fluent-ffmpeg';
import { AppError } from '../../../../core/errors/app_error.js';

export interface IFfmpegDataSource {
  cutClip(inputPath: string, startSec: number, durationSec: number, outputPath: string): Promise<void>;
}

export class FfmpegDataSource implements IFfmpegDataSource {
  cutClip(inputPath: string, startSec: number, durationSec: number, outputPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .setStartTime(startSec)
        .setDuration(durationSec)
        .output(outputPath)
        .videoCodec('libx264')
        .audioCodec('aac')
        .outputOptions(['-movflags faststart'])
        .on('end', () => resolve())
        .on('error', (err: Error) => {
          reject(new AppError('CLIP_CUT_FAILED', `FFmpeg error: ${err.message}`, 500));
        })
        .run();
    });
  }
}
