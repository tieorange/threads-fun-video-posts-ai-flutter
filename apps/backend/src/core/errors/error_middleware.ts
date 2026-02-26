import { Request, Response, NextFunction } from 'express';
import { AppError } from './app_error.js';

export function errorMiddleware(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    res.status(err.httpStatus).json({
      code: err.code,
      message: err.message,
      details: err.details,
    });
    return;
  }

  console.error('[Unhandled error]', err);
  res.status(500).json({
    code: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred.',
    details: {},
  });
}
