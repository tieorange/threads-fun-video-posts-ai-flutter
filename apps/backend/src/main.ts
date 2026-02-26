import path from 'path';
import { createApp } from './infrastructure/express/app';
import { config } from './core/config/env';
import { logger } from './core/logging/logger';

const storagePath = path.resolve(config.storagePath);

process.on('unhandledRejection', (reason: unknown) => {
  logger.error('process_unhandled_rejection', 'Unhandled promise rejection', {
    layer: 'core',
    feature: 'core',
    ...(reason instanceof Error && reason.stack ? { stack: reason.stack } : { stack: String(reason) }),
    data: { reason: String(reason) },
  });
  process.exit(1);
});

process.on('uncaughtException', (err: Error) => {
  logger.error('process_uncaught_exception', err.message, {
    layer: 'core',
    feature: 'core',
    ...(err.stack ? { stack: err.stack } : {}),
    data: { name: err.name },
  });
  process.exit(1);
});

createApp(storagePath)
  .then((app) => {
    app.listen(config.port, () => {
      logger.info('server_started', `Running on http://localhost:${config.port}`, {
        layer: 'infrastructure',
        feature: 'core',
        data: { port: config.port, storagePath },
      });
    });
  })
  .catch((err: unknown) => {
    logger.error('server_start_failed', err instanceof Error ? err.message : String(err), {
      layer: 'infrastructure',
      feature: 'core',
      ...(err instanceof Error && err.stack ? { stack: err.stack } : {}),
    });
    process.exit(1);
  });
