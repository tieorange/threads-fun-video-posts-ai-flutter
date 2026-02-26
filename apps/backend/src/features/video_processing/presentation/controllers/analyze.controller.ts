import { Request, Response, NextFunction } from 'express';
import { AnalyzeRequestSchema } from '../dtos/analyze_request.dto.js';
import { AnalyzeVideoUseCase } from '../../domain/usecases/analyze_video.usecase.js';
import { AppError } from '../../../../core/errors/app_error.js';

export class AnalyzeController {
  constructor(private readonly analyzeVideoUseCase: AnalyzeVideoUseCase) {}

  handle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const parseResult = AnalyzeRequestSchema.safeParse(req.body);
      if (!parseResult.success) {
        throw new AppError('INVALID_URL', 'Invalid request body.', 400, {
          issues: parseResult.error.issues,
        });
      }

      const { youtubeUrl, language } = parseResult.data;
      const result = await this.analyzeVideoUseCase.execute(youtubeUrl, language);

      res.json(result);
    } catch (err) {
      next(err);
    }
  };
}
