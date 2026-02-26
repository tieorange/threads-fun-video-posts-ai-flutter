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

  private async _writeAtomic(filePath: string, payload: string): Promise<void> {
    const tempPath = `${filePath}.tmp-${process.pid}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    await fs.writeFile(tempPath, payload, 'utf-8');
    await fs.rename(tempPath, filePath);
  }

  private async _sleep(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms));
  }

  private _isRetryableParseError(err: unknown): boolean {
    return err instanceof SyntaxError && /Unexpected end of JSON input/i.test(err.message);
  }

  async saveJob(job: JobRecord): Promise<void> {
    const payload = JSON.stringify(job, null, 2);
    await this._writeAtomic(this.jobPath(job.jobId), payload);
    logger.debug('storage_job_saved', `Job ${job.jobId} saved`, {
      layer: 'data',
      jobId: job.jobId,
      data: { status: job.status, progress: job.progress, payloadBytes: payload.length },
    });
  }

  async loadJob(jobId: string): Promise<JobRecord | null> {
    const filePath = this.jobPath(jobId);
    try {
      const raw = await fs.readFile(filePath, 'utf-8');
      return JSON.parse(raw) as JobRecord;
    } catch (err: unknown) {
      if (this._isRetryableParseError(err)) {
        logger.warn('storage_job_read_retry', `Parse failed for ${jobId}, retrying once`, {
          layer: 'data',
          jobId,
          data: { reason: err instanceof Error ? err.message : String(err) },
        });
        try {
          await this._sleep(25);
          const raw = await fs.readFile(filePath, 'utf-8');
          return JSON.parse(raw) as JobRecord;
        } catch (retryErr: unknown) {
          err = retryErr;
        }
      }
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

  async loadAllJobs(): Promise<JobRecord[]> {
    const jobsDir = path.join(this.storagePath, 'jobs');
    try {
      const entries = await fs.readdir(jobsDir, { withFileTypes: true });
      const files = entries
        .filter((entry) => entry.isFile() && entry.name.endsWith('.json'))
        .map((entry) => path.join(jobsDir, entry.name));

      const jobs: JobRecord[] = [];
      for (const filePath of files) {
        try {
          const raw = await fs.readFile(filePath, 'utf-8');
          jobs.push(JSON.parse(raw) as JobRecord);
        } catch (err: unknown) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.warn('storage_job_parse_skipped', `Skipping invalid job file: ${msg}`, {
            layer: 'data',
            data: { filePath },
          });
        }
      }
      return jobs;
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.error('storage_jobs_list_failed', `Failed to list jobs: ${msg}`, {
        layer: 'data',
        ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
      });
      throw new AppError('JOB_LOAD_FAILED', `Failed to list jobs: ${msg}`, 500);
    }
  }

  async ensureDirectories(): Promise<void> {
    const dirs = ['captions', 'videos', 'clips', 'jobs'];
    await Promise.all(
      dirs.map((d) => fs.mkdir(path.join(this.storagePath, d), { recursive: true })),
    );
  }
}
