import { Request, Response, NextFunction } from 'express';
import { ProcessRequestSchema } from '../dtos/process_request.dto';
import { ValidateAiPayloadUseCase } from '../../domain/usecases/validate_ai_payload.usecase';
import { ProcessVideoUseCase } from '../../domain/usecases/process_video.usecase';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

function summarizePayloadForLogs(aiPayload: {
  videoTitle: string;
  language: 'uk' | 'uk_18' | 'en' | 'ru';
  moments: Array<{ id: string; startSec: number; endSec: number }>;
}): Record<string, unknown> {
  return {
    language: aiPayload.language,
    videoTitleLength: aiPayload.videoTitle.length,
    momentCount: aiPayload.moments.length,
    sampleMomentIds: aiPayload.moments.slice(0, 5).map((m) => m.id),
    rangeSec: aiPayload.moments.length
      ? {
          minStartSec: Math.min(...aiPayload.moments.map((m) => m.startSec)),
          maxEndSec: Math.max(...aiPayload.moments.map((m) => m.endSec)),
        }
      : null,
  };
}

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
          data: {
            issues: parseResult.error.issues,
            bodyKeys:
              req.body && typeof req.body === 'object' ? Object.keys(req.body as Record<string, unknown>) : [],
          },
        });
        throw new AppError('INVALID_AI_PAYLOAD', 'Invalid request body.', 400, {
          issues: parseResult.error.issues,
        });
      }

      const { youtubeUrl, aiPayload } = parseResult.data;
      logger.info('process_dto_valid', 'DTO validated, calling validate use case', {
        layer: 'presentation',
        data: { youtubeUrl, payloadSummary: summarizePayloadForLogs(aiPayload) },
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
