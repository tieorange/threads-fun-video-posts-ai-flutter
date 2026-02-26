import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { AiMomentsPayload } from '../entities/ai_moments_payload';
import { ClipArtifact, JobRecord } from '../entities/job_record';
import { IJobRepository } from '../repositories/job_repository.interface';
import { IVideoRepository } from '../repositories/video_repository.interface';
import { IFfmpegDataSource } from '../../data/datasources/ffmpeg.datasource';
import { logger } from '../../../../core/logging/logger';

export class ProcessVideoUseCase {
  constructor(
    private readonly videoRepository: IVideoRepository,
    private readonly jobRepository: IJobRepository,
    private readonly ffmpegDataSource: IFfmpegDataSource,
    private readonly clipsStoragePath: string,
  ) {}

  async execute(youtubeUrl: string, payload: AiMomentsPayload): Promise<string> {
    const jobId = `job_${new Date().toISOString().slice(0, 10).replace(/-/g, '')}_${uuidv4().slice(0, 8)}`;
    const now = new Date().toISOString();

    const job: JobRecord = {
      jobId,
      status: 'queued',
      progress: 0,
      youtubeUrl,
      moments: payload.moments,
      clips: [],
      error: null,
      createdAt: now,
      updatedAt: now,
    };

    await this.jobRepository.save(job);
    logger.info('job_created', 'Job saved, starting async run', {
      layer: 'domain',
      jobId,
      data: { youtubeUrl, momentCount: payload.moments.length },
    });

    this.runAsync(job, payload).catch((err: unknown) => {
      logger.error('job_fatal_error', err instanceof Error ? err.message : 'Unknown error', {
        layer: 'domain',
        jobId,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
      });
    });

    return jobId;
  }

  private async runAsync(job: JobRecord, payload: AiMomentsPayload): Promise<void> {
    const { jobId } = job;
    try {
      await this.updateJob(job, { status: 'running', progress: 10 });
      logger.info('job_running', 'Job started, downloading video', { layer: 'domain', jobId });

      const dlStart = Date.now();
      const videoPath = await this.videoRepository.downloadVideo(job.youtubeUrl, jobId);
      await this.updateJob(job, { progress: 30 });
      logger.info('job_download_done', 'Video downloaded', {
        layer: 'domain',
        jobId,
        durationMs: Date.now() - dlStart,
        data: { videoPath },
      });

      const clips: ClipArtifact[] = [];
      const total = payload.moments.length;

      for (let i = 0; i < total; i++) {
        const moment = payload.moments[i];
        if (!moment) continue;

        const outputFile = `${jobId}_${moment.id}.mp4`;
        const outputPath = path.join(this.clipsStoragePath, outputFile);
        const durationSec = moment.endSec - moment.startSec;

        logger.info('job_clip_start', `Cutting clip ${i + 1}/${total}`, {
          layer: 'domain',
          jobId,
          data: { momentId: moment.id, startSec: moment.startSec, durationSec },
        });

        const clipStart = Date.now();
        await this.ffmpegDataSource.cutClip(videoPath, moment.startSec, durationSec, outputPath);

        clips.push({
          momentId: moment.id,
          startSec: moment.startSec,
          endSec: moment.endSec,
          downloadUrl: `/media/clips/${outputFile}`,
        });

        const progress = 30 + Math.round(((i + 1) / total) * 65);
        logger.info('job_clip_done', `Clip ${i + 1}/${total} done`, {
          layer: 'domain',
          jobId,
          durationMs: Date.now() - clipStart,
          data: { momentId: moment.id, outputFile, progress },
        });
        await this.updateJob(job, { progress, clips: [...clips] });
      }

      await this.updateJob(job, { status: 'done', progress: 100, clips });
      logger.info('job_done', 'All clips cut, job complete', {
        layer: 'domain',
        jobId,
        data: { clipCount: clips.length },
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      logger.error('job_failed', message, {
        layer: 'domain',
        jobId,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
      });
      await this.updateJob(job, { status: 'failed', error: message });
    }
  }

  private async updateJob(
    job: JobRecord,
    patch: Partial<Pick<JobRecord, 'status' | 'progress' | 'clips' | 'error'>>,
  ): Promise<void> {
    Object.assign(job, { ...patch, updatedAt: new Date().toISOString() });
    await this.jobRepository.update(job);
  }
}
