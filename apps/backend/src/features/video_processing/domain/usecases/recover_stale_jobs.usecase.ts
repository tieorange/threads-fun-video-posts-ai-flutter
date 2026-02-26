import { IJobRepository } from '../repositories/job_repository.interface';
import { logger } from '../../../../core/logging/logger';

export class RecoverStaleJobsUseCase {
  constructor(private readonly jobRepository: IJobRepository) {}

  async execute(): Promise<number> {
    const jobs = await this.jobRepository.findAll();
    const staleJobs = jobs.filter((j) => j.status === 'queued' || j.status === 'running');

    for (const job of staleJobs) {
      job.status = 'failed';
      job.error = 'Job interrupted by server restart. Please run again.';
      job.updatedAt = new Date().toISOString();
      await this.jobRepository.update(job);

      logger.warn('job_recovered_as_failed', 'Recovered stale job as failed', {
        layer: 'domain',
        jobId: job.jobId,
        data: { previousStatus: 'queued/running' },
      });
    }

    if (staleJobs.length > 0) {
      logger.info('stale_jobs_recovered', 'Recovered stale jobs at startup', {
        layer: 'domain',
        data: { recoveredCount: staleJobs.length },
      });
    }

    return staleJobs.length;
  }
}
