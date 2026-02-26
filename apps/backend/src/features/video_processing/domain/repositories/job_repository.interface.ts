import { JobRecord } from '../entities/job_record';

export interface IJobRepository {
  save(job: JobRecord): Promise<void>;
  findById(jobId: string): Promise<JobRecord | null>;
  findAll(): Promise<JobRecord[]>;
  update(job: JobRecord): Promise<void>;
  delete(jobId: string): Promise<void>;
}
