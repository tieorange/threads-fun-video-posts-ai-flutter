import { Request, Response, NextFunction } from 'express';
import { ProcessRequestSchema } from '../dtos/process_request.dto';
import { ValidateAiPayloadUseCase } from '../../domain/usecases/validate_ai_payload.usecase';
import { ProcessVideoUseCase } from '../../domain/usecases/process_video.usecase';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

export class ProcessController {
  constructor(
    private readonly validateUseCase: ValidateAiPayloadUseCase,
    private readonly processVideoUseCase: ProcessVideoUseCase,
  ) {}

  handle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parseResult = ProcessRequestSchema.safeParse(req.body);
      if (!parseResult.success) {
        logger.warn('process_dto_invalid', 'DTO validation failed', {
          layer: 'presentation',
          data: { issues: parseResult.error.issues },
        });
        throw new AppError('INVALID_AI_PAYLOAD', 'Invalid request body.', 400, {
          issues: parseResult.error.issues,
        });
      }

      const { youtubeUrl, aiPayload } = parseResult.data;
      logger.info('process_dto_valid', 'DTO validated, calling validate use case', {
        layer: 'presentation',
        data: { youtubeUrl, momentCount: aiPayload.moments.length },
      });

      const validatedPayload = this.validateUseCase.execute(aiPayload);
      const jobId = await this.processVideoUseCase.execute(youtubeUrl, validatedPayload);

      logger.info('process_job_queued', 'Job queued, sending 202', {
        layer: 'presentation',
        jobId,
      });

      res.status(202).json({ jobId, status: 'queued' });
    } catch (err) {
      next(err);
    }
  };
}
