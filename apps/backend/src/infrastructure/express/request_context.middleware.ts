import { type Request, type Response, type NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { logger, asyncLocalStorage } from '../../core/logging/logger';

export function requestContextMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const clientRequestIdHeader = req.headers['x-client-request-id'];
  const clientRequestId = Array.isArray(clientRequestIdHeader)
    ? clientRequestIdHeader[0]
    : clientRequestIdHeader;
  const requestIdHeader = req.headers['x-request-id'];
  const requestIdFromHeader = Array.isArray(requestIdHeader)
    ? requestIdHeader[0]
    : requestIdHeader;
  const requestId = requestIdFromHeader ?? clientRequestId ?? uuidv4();
  const requestIdSource = requestIdFromHeader
    ? 'x-request-id'
    : clientRequestId
      ? 'x-client-request-id'
      : 'generated';
  const endpoint = `${req.method} ${req.path}`;

  res.setHeader('x-request-id', requestId);
  res.setHeader('x-correlation-id', requestId);

  const start = Date.now();

  asyncLocalStorage.run({ requestId, endpoint }, () => {
    logger.info('request_started', `${req.method} ${req.path}`, {
      layer: 'infrastructure',
      feature: 'core',
      data: {
        method: req.method,
        path: req.path,
        query: req.query as Record<string, unknown>,
        userAgent: req.headers['user-agent'],
        requestIdSource,
        clientRequestId,
      },
    });

    res.on('finish', () => {
      const durationMs = Date.now() - start;
      const level =
        res.statusCode >= 500
          ? 'error'
          : res.statusCode >= 400
            ? 'warn'
            : 'info';
      logger[level](
        'request_finished',
        `${req.method} ${req.path} → ${res.statusCode}`,
        {
          layer: 'infrastructure',
          feature: 'core',
          durationMs,
          data: { statusCode: res.statusCode },
        },
      );
    });

    next();
  });
}
