import { Request, Response, NextFunction } from 'express';
import { AnalyzeRequestSchema } from '../dtos/analyze_request.dto';
import { AnalyzeVideoUseCase } from '../../domain/usecases/analyze_video.usecase';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

export class AnalyzeController {
  constructor(private readonly analyzeVideoUseCase: AnalyzeVideoUseCase) {}

  handle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parseResult = AnalyzeRequestSchema.safeParse(req.body);
      if (!parseResult.success) {
        logger.warn('analyze_dto_invalid', 'DTO validation failed', {
          layer: 'presentation',
          data: { issues: parseResult.error.issues },
        });
        throw new AppError('INVALID_URL', 'Invalid request body.', 400, {
          issues: parseResult.error.issues,
        });
      }

      const { youtubeUrl, language } = parseResult.data;
      logger.info('analyze_dto_valid', 'DTO validated, calling use case', {
        layer: 'presentation',
        data: { youtubeUrl, language },
      });

      const result = await this.analyzeVideoUseCase.execute(youtubeUrl, language);

      logger.info('analyze_controller_done', 'Analyze completed, sending response', {
        layer: 'presentation',
        data: { transcriptSegments: result.transcript.length, videoId: result.video.videoId },
      });

      res.json(result);
    } catch (err) {
      next(err);
    }
  };
}
