import { Request, Response, NextFunction } from 'express';
import { GetProcessStatusUseCase } from '../../domain/usecases/get_process_status.usecase';
import { logger } from '../../../../core/logging/logger';

export class JobStatusController {
  constructor(private readonly getStatusUseCase: GetProcessStatusUseCase) { }

  handle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { jobId } = req.params;
      logger.debug('job_status_requested', `Fetching status for job`, {
        layer: 'presentation',
        ...(jobId ? { jobId } : {}),
      });

      const job = await this.getStatusUseCase.execute(jobId ?? '');

      logger.debug('job_status_returned', `Job status: ${job.status}`, {
        layer: 'presentation',
        ...(jobId ? { jobId } : {}),
        data: { status: job.status, progress: job.progress },
      });

      res.json(job);
    } catch (err) {
      next(err);
    }
  };
}
