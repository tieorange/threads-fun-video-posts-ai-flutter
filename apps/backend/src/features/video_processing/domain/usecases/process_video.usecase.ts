import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { AiMomentsPayload } from '../entities/ai_moments_payload.js';
import { ClipArtifact, JobRecord } from '../entities/job_record.js';
import { IJobRepository } from '../repositories/job_repository.interface.js';
import { IVideoRepository } from '../repositories/video_repository.interface.js';
import { IFfmpegDataSource } from '../../data/datasources/ffmpeg.datasource.js';

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
    this.runAsync(job, payload).catch((err: unknown) => {
      console.error(`[Job ${jobId}] fatal error:`, err);
    });

    return jobId;
  }

  private async runAsync(job: JobRecord, payload: AiMomentsPayload): Promise<void> {
    try {
      await this.updateJob(job, { status: 'running', progress: 10 });

      const videoPath = await this.videoRepository.downloadVideo(job.youtubeUrl, job.jobId);
      await this.updateJob(job, { progress: 30 });

      const clips: ClipArtifact[] = [];
      const total = payload.moments.length;

      for (let i = 0; i < total; i++) {
        const moment = payload.moments[i];
        if (!moment) continue;

        const outputFile = `${job.jobId}_${moment.id}.mp4`;
        const outputPath = path.join(this.clipsStoragePath, outputFile);
        const durationSec = moment.endSec - moment.startSec;

        await this.ffmpegDataSource.cutClip(videoPath, moment.startSec, durationSec, outputPath);

        clips.push({
          momentId: moment.id,
          startSec: moment.startSec,
          endSec: moment.endSec,
          downloadUrl: `/media/clips/${outputFile}`,
        });

        const progress = 30 + Math.round(((i + 1) / total) * 65);
        await this.updateJob(job, { progress, clips: [...clips] });
      }

      await this.updateJob(job, { status: 'done', progress: 100, clips });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unknown error';
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
