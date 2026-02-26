import fs from 'fs/promises';
import path from 'path';
import { JobRecord } from '../../domain/entities/job_record.js';

export class LocalStorageDataSource {
  constructor(private readonly storagePath: string) {}

  jobPath(jobId: string): string {
    return path.join(this.storagePath, 'jobs', `${jobId}.json`);
  }

  async saveJob(job: JobRecord): Promise<void> {
    await fs.writeFile(this.jobPath(job.jobId), JSON.stringify(job, null, 2), 'utf-8');
  }

  async loadJob(jobId: string): Promise<JobRecord | null> {
    try {
      const raw = await fs.readFile(this.jobPath(jobId), 'utf-8');
      return JSON.parse(raw) as JobRecord;
    } catch {
      return null;
    }
  }

  async ensureDirectories(): Promise<void> {
    const dirs = ['captions', 'videos', 'clips', 'jobs'];
    await Promise.all(
      dirs.map((d) => fs.mkdir(path.join(this.storagePath, d), { recursive: true })),
    );
  }
}
