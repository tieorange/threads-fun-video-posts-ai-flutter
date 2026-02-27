import { Request, Response, NextFunction } from 'express';
import { logger } from '../../../../core/logging/logger';
import { AppLayer, LogLevel } from '../../../../core/logging/log_event';

const LOG_LEVELS: readonly LogLevel[] = ['debug', 'info', 'warn', 'error'];
const APP_LAYERS: readonly AppLayer[] = [
  'presentation',
  'domain',
  'data',
  'infrastructure',
  'core',
];

function asString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function asNumber(value: unknown): number | undefined {
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return undefined;
  return value as Record<string, unknown>;
}

function hasValue<T extends string>(options: readonly T[], value: string): value is T {
  return options.includes(value as T);
}

export class LogsController {
  log(req: Request, res: Response, next: NextFunction): void {
    try {
      const body = asRecord(req.body) ?? {};

      const levelRaw = asString(body['level']);
      const event = asString(body['event']);
      const message = asString(body['message']);
      const layerRaw = asString(body['layer']);
      const featureRaw = asString(body['feature']);
      const requestId = asString(body['requestId']);
      const jobId = asString(body['jobId']);
      const endpoint = asString(body['endpoint']) ?? asString(body['route']);
      const stack = asString(body['stack']);
      const durationMs = asNumber(body['durationMs']);
      const data = asRecord(body['data']);

      if (!levelRaw || !event || !message || !layerRaw) {
        res.status(400).json({ error: 'Missing required log fields: level, event, message, layer' });
        return;
      }
      if (!hasValue(LOG_LEVELS, levelRaw)) {
        res.status(400).json({ error: `Invalid log level: ${levelRaw}` });
        return;
      }
      if (!hasValue(APP_LAYERS, layerRaw)) {
        res.status(400).json({ error: `Invalid app layer: ${layerRaw}` });
        return;
      }

      const feature = featureRaw === 'core' ? 'core' : 'video_processing';
      const context = {
        app: 'frontend' as const,
        layer: layerRaw,
        feature,
        requestId,
        jobId,
        endpoint,
        data,
        stack,
        durationMs,
      };

      switch (levelRaw) {
        case 'debug':
          logger.debug(event, message, context);
          break;
        case 'info':
          logger.info(event, message, context);
          break;
        case 'warn':
          logger.warn(event, message, context);
          break;
        case 'error':
          logger.error(event, message, context);
          break;
      }

      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}
