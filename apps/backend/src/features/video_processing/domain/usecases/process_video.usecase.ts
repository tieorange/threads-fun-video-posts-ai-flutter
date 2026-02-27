import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { AiMomentsPayload } from '../entities/ai_moments_payload';
import { ClipArtifact, JobRecord } from '../entities/job_record';
import { IJobRepository } from '../repositories/job_repository.interface';
import { IVideoRepository } from '../repositories/video_repository.interface';
import { IFfmpegDataSource } from '../../data/datasources/ffmpeg.datasource';
import { logger } from '../../../../core/logging/logger';
import { config } from '../../../../core/config/env';

export class ProcessVideoUseCase {
  constructor(
    private readonly videoRepository: IVideoRepository,
    private readonly jobRepository: IJobRepository,
    private readonly ffmpegDataSource: IFfmpegDataSource,
    private readonly clipsStoragePath: string,
  ) { }

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
    const abortController = new AbortController();
    try {
      await this.updateJob(job, { status: 'running', progress: 10 });
      logger.info('job_running', 'Job started, fetching metadata', { layer: 'domain', jobId });

      // Fetch metadata first to get videoId for caching
      const metadata = await this.videoRepository.getMetadata(job.youtubeUrl);
      const videoId = metadata.videoId;

      let videoPath: string;
      const cachedPath = await this.videoRepository.getCachedVideoPath(videoId);

      if (cachedPath) {
        logger.info('job_cache_hit', 'Using cached video', { layer: 'domain', jobId, data: { videoId, cachedPath } });
        videoPath = await this.videoRepository.symlinkFromCache(videoId, jobId);
        await this.updateJob(job, { progress: 50 });
      } else {
        logger.info('job_cache_miss', 'Downloading video', { layer: 'domain', jobId, data: { videoId } });
        const dlStart = Date.now();
        videoPath = await this.withTimeout(
          this.videoRepository.downloadVideo(job.youtubeUrl, jobId, (percent) => {
            const downloadProgress = 10 + Math.round((percent / 100) * 40);
            this.updateJob(job, { progress: downloadProgress }).catch((e: unknown) => {
              logger.warn('job_progress_update_failed', String(e), { layer: 'domain', jobId });
            });
          }, abortController.signal),
          config.processDownloadTimeoutMs,
          'DOWNLOAD_TIMEOUT',
          `Video download timed out after ${config.processDownloadTimeoutMs}ms`,
          abortController,
        );

        // Link to cache for future use
        await this.videoRepository.linkToCache(jobId, videoId);

        await this.updateJob(job, { progress: 50 });
        logger.info('job_download_done', 'Video downloaded and cached', {
          layer: 'domain',
          jobId,
          durationMs: Date.now() - dlStart,
          data: { videoPath, videoId },
        });
      }

      const clips: ClipArtifact[] = [];
      const total = payload.moments.length;
      let completedCount = 0;

      // Implement bounded concurrency
      const concurrency = config.processClipConcurrency;
      const queue = [...payload.moments];
      const activePromises: Promise<void>[] = [];

      const processNext = async (): Promise<void> => {
        if (queue.length === 0) return;
        const moment = queue.shift();
        if (!moment) return;

        const momentIndex = payload.moments.indexOf(moment);
        const outputFile = `${jobId}_${moment.id}.mp4`;
        const outputPath = path.join(this.clipsStoragePath, outputFile);
        const durationSec = moment.endSec - moment.startSec;

        logger.info('job_clip_start', `Cutting clip ${momentIndex + 1}/${total}`, {
          layer: 'domain',
          jobId,
          data: { momentId: moment.id, startSec: moment.startSec, durationSec },
        });

        const clipStart = Date.now();
        await this.withTimeout(
          this.ffmpegDataSource.cutClip(videoPath, moment.startSec, durationSec, outputPath, abortController.signal),
          config.processClipCutTimeoutMs,
          'CLIP_TIMEOUT',
          `Clip cut timed out after ${config.processClipCutTimeoutMs}ms`,
          abortController,
        );

        clips.push({
          momentId: moment.id,
          startSec: moment.startSec,
          endSec: moment.endSec,
          downloadUrl: `/media/clips/${outputFile}`,
        });

        completedCount++;
        const progress = 50 + Math.round((completedCount / total) * 50);
        logger.info('job_clip_done', `Clip ${momentIndex + 1}/${total} done`, {
          layer: 'domain',
          jobId,
          durationMs: Date.now() - clipStart,
          data: { momentId: moment.id, outputFile, progress },
        });

        // Update job record with latest clips and progress
        await this.updateJob(job, { progress, clips: [...clips] });

        // Process next in queue
        await processNext();
      };

      // Start initial batch of workers
      for (let i = 0; i < Math.min(concurrency, total); i++) {
        activePromises.push(processNext());
      }

      await Promise.all(activePromises);

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

  private async withTimeout<T>(
    promise: Promise<T>,
    timeoutMs: number,
    code: string,
    message: string,
    abortController?: AbortController,
  ): Promise<T> {
    let timeoutId: NodeJS.Timeout | null = null;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timeoutId = setTimeout(() => {
        if (abortController) {
          abortController.abort();
        }
        reject(new Error(`${code}: ${message}`));
      }, timeoutMs);
    });

    try {
      return await Promise.race([promise, timeoutPromise]) as T;
    } finally {
      if (timeoutId) clearTimeout(timeoutId);
    }
  }
}
