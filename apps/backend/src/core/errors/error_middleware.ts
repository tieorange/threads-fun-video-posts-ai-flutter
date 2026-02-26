import { Request, Response, NextFunction } from 'express';
import { AppError } from './app_error';
import { logger } from '../logging/logger';

export function errorMiddleware(
  err: unknown,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    const level = err.httpStatus >= 500 ? 'error' : 'warn';
    logger[level]('app_error', err.message, {
      layer: 'core',
      feature: 'core',
      data: { code: err.code, httpStatus: err.httpStatus, details: err.details },
      ...(err.stack ? { stack: err.stack } : {}),
    });
    res.status(err.httpStatus).json({
      code: err.code,
      message: err.message,
      details: err.details,
    });
    return;
  }

  logger.error('unhandled_error', err instanceof Error ? err.message : 'Unknown error', {
    layer: 'core',
    feature: 'core',
    ...(err instanceof Error && err.stack ? { stack: err.stack } : { stack: String(err) }),
    data: { type: err instanceof Error ? err.name : typeof err },
  });
  res.status(500).json({
    code: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred.',
    details: {},
  });
}
