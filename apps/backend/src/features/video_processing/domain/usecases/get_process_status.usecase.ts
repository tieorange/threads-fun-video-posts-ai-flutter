import { JobRecord } from '../entities/job_record.js';
import { IJobRepository } from '../repositories/job_repository.interface.js';
import { AppError } from '../../../../core/errors/app_error.js';

export class GetProcessStatusUseCase {
  constructor(private readonly jobRepository: IJobRepository) {}

  async execute(jobId: string): Promise<JobRecord> {
    const job = await this.jobRepository.findById(jobId);
    if (!job) {
      throw new AppError('JOB_NOT_FOUND', `Job ${jobId} not found.`, 404);
    }
    return job;
  }
}
