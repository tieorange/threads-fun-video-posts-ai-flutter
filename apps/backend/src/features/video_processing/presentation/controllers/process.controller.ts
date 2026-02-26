import { Request, Response, NextFunction } from 'express';
import { ProcessRequestSchema } from '../dtos/process_request.dto.js';
import { ValidateAiPayloadUseCase } from '../../domain/usecases/validate_ai_payload.usecase.js';
import { ProcessVideoUseCase } from '../../domain/usecases/process_video.usecase.js';
import { AppError } from '../../../../core/errors/app_error.js';

export class ProcessController {
  constructor(
    private readonly validateUseCase: ValidateAiPayloadUseCase,
    private readonly processVideoUseCase: ProcessVideoUseCase,
  ) {}

  handle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parseResult = ProcessRequestSchema.safeParse(req.body);
      if (!parseResult.success) {
        throw new AppError('INVALID_AI_PAYLOAD', 'Invalid request body.', 400, {
          issues: parseResult.error.issues,
        });
      }

      const { youtubeUrl, aiPayload } = parseResult.data;
      const validatedPayload = this.validateUseCase.execute(aiPayload);
      const jobId = await this.processVideoUseCase.execute(youtubeUrl, validatedPayload);

      res.status(202).json({ jobId, status: 'queued' });
    } catch (err) {
      next(err);
    }
  };
}
