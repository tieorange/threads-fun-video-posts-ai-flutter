import { JobRecord } from '../../domain/entities/job_record';
import { IJobRepository } from '../../domain/repositories/job_repository.interface';
import { LocalStorageDataSource } from '../datasources/local_storage.datasource';

export class JobRepositoryImpl implements IJobRepository {
  constructor(private readonly storage: LocalStorageDataSource) {}

  save(job: JobRecord): Promise<void> {
    return this.storage.saveJob(job);
  }

  findById(jobId: string): Promise<JobRecord | null> {
    return this.storage.loadJob(jobId);
  }

  findAll(): Promise<JobRecord[]> {
    return this.storage.loadAllJobs();
  }

  update(job: JobRecord): Promise<void> {
    return this.storage.saveJob(job);
  }
}
