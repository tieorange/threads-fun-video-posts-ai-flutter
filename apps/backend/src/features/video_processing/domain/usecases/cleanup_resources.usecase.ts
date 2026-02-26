import { IJobRepository } from '../repositories/job_repository.interface';
import { logger } from '../../../../core/logging/logger';

export class CleanupResourcesUseCase {
    constructor(private readonly jobRepository: IJobRepository) { }

    async execute(): Promise<void> {
        const start = Date.now();
        logger.info('cleanup_resources_start', 'Starting background resource cleanup', { layer: 'domain' });

        try {
            const jobs = await this.jobRepository.findAll();

            // Cleanup criteria:
            // 1. Failed jobs older than 1 hour
            // 2. Done jobs older than 24 hours (optional, maybe keep for longer?)
            // For now, let's focus on cleaning up Failed/Stale jobs that are older than 1 hour

            const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();

            const toCleanup = jobs.filter(job => {
                if (job.status === 'failed' && job.updatedAt < oneHourAgo) return true;
                return false;
            });

            for (const job of toCleanup) {
                logger.info('cleanup_job_resources', `Cleaning up resources for job ${job.jobId}`, {
                    layer: 'domain',
                    jobId: job.jobId,
                    data: { status: job.status, updatedAt: job.updatedAt }
                });
                await this.jobRepository.delete(job.jobId);
            }

            logger.info('cleanup_resources_done', 'Resource cleanup completed', {
                layer: 'domain',
                durationMs: Date.now() - start,
                data: { cleanedCount: toCleanup.length }
            });
        } catch (err: unknown) {
            logger.error('cleanup_resources_failed', String(err), {
                layer: 'domain',
                durationMs: Date.now() - start
            });
        }
    }
}
