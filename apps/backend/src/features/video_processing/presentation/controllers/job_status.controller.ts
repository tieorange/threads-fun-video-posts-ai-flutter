import { Request, Response, NextFunction } from 'express';
import { GetProcessStatusUseCase } from '../../domain/usecases/get_process_status.usecase.js';

export class JobStatusController {
  constructor(private readonly getStatusUseCase: GetProcessStatusUseCase) {}

  handle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { jobId } = req.params;
      const job = await this.getStatusUseCase.execute(jobId ?? '');
      res.json(job);
    } catch (err) {
      next(err);
    }
  };
}
