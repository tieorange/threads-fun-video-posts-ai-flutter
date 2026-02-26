import { JobRecord } from '../entities/job_record';
import { IJobRepository } from '../repositories/job_repository.interface';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

export class GetProcessStatusUseCase {
  constructor(private readonly jobRepository: IJobRepository) {}

  async execute(jobId: string): Promise<JobRecord> {
    const job = await this.jobRepository.findById(jobId);
    if (!job) {
      logger.warn('job_not_found', `Job ${jobId} not found`, { layer: 'domain', jobId });
      throw new AppError('JOB_NOT_FOUND', `Job ${jobId} not found.`, 404);
    }
    return job;
  }
}
