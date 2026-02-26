import fs from 'fs/promises';
import path from 'path';
import { JobRecord } from '../../domain/entities/job_record';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

export class LocalStorageDataSource {
  constructor(private readonly storagePath: string) { }

  jobPath(jobId: string): string {
    return path.join(this.storagePath, 'jobs', `${jobId}.json`);
  }

  async saveJob(job: JobRecord): Promise<void> {
    const payload = JSON.stringify(job, null, 2);
    await fs.writeFile(this.jobPath(job.jobId), payload, 'utf-8');
    logger.debug('storage_job_saved', `Job ${job.jobId} saved`, {
      layer: 'data',
      jobId: job.jobId,
      data: { status: job.status, progress: job.progress, payloadBytes: payload.length },
    });
  }

  async loadJob(jobId: string): Promise<JobRecord | null> {
    try {
      const raw = await fs.readFile(this.jobPath(jobId), 'utf-8');
      return JSON.parse(raw) as JobRecord;
    } catch (err: unknown) {
      if ((err as NodeJS.ErrnoException).code === 'ENOENT') {
        logger.debug('storage_job_not_found', `Job file not found for ${jobId}`, {
          layer: 'data',
          jobId,
        });
        return null;
      }
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('storage_job_read_failed', `Failed to read/parse job ${jobId}: ${msg}`, {
        layer: 'data',
        jobId,
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
      });
      throw new AppError('JOB_LOAD_FAILED', `Failed to load job: ${msg}`, 500);
    }
  }

  async ensureDirectories(): Promise<void> {
    const dirs = ['captions', 'videos', 'clips', 'jobs'];
    await Promise.all(
      dirs.map((d) => fs.mkdir(path.join(this.storagePath, d), { recursive: true })),
    );
  }
}
