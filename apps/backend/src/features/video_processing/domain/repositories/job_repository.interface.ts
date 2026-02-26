import { JobRecord } from '../entities/job_record.js';

export interface IJobRepository {
  save(job: JobRecord): Promise<void>;
  findById(jobId: string): Promise<JobRecord | null>;
  update(job: JobRecord): Promise<void>;
}
