import { JobRecord } from '../../domain/entities/job_record.js';
import { IJobRepository } from '../../domain/repositories/job_repository.interface.js';
import { LocalStorageDataSource } from '../datasources/local_storage.datasource.js';

export class JobRepositoryImpl implements IJobRepository {
  constructor(private readonly storage: LocalStorageDataSource) {}

  save(job: JobRecord): Promise<void> {
    return this.storage.saveJob(job);
  }

  findById(jobId: string): Promise<JobRecord | null> {
    return this.storage.loadJob(jobId);
  }

  update(job: JobRecord): Promise<void> {
    return this.storage.saveJob(job);
  }
}
