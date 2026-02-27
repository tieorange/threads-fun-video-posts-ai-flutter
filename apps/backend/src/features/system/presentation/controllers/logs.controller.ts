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

const MAX_LOG_MESSAGE_LENGTH = 2000;
const MAX_LOG_STACK_LENGTH = 12000;
const MAX_DATA_DEPTH = 6;
const MAX_DATA_KEYS = 120;
const MAX_ARRAY_ITEMS = 40;
const MAX_STRING_LENGTH = 2000;

function truncateString(value: string, maxLength: number): string {
  if (value.length <= maxLength) return value;
  return `${value.slice(0, maxLength)}…[truncated ${value.length - maxLength} chars]`;
}

function sanitizeDataValue(value: unknown, depth: number): unknown {
  if (depth > MAX_DATA_DEPTH) return '[max_depth_exceeded]';

  if (
    value === null ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  ) {
    return value;
  }

  if (typeof value === 'string') {
    return truncateString(value, MAX_STRING_LENGTH);
  }

  if (Array.isArray(value)) {
    return value.slice(0, MAX_ARRAY_ITEMS).map((item) => sanitizeDataValue(item, depth + 1));
  }

  if (typeof value === 'object') {
    const source = value as Record<string, unknown>;
    const entries = Object.entries(source).slice(0, MAX_DATA_KEYS);
    const result: Record<string, unknown> = {};
    for (const [key, item] of entries) {
      result[key] = sanitizeDataValue(item, depth + 1);
    }
    if (Object.keys(source).length > MAX_DATA_KEYS) {
      result['_truncatedKeys'] = Object.keys(source).length - MAX_DATA_KEYS;
    }
    return result;
  }

  return String(value);
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
      const rawData = asRecord(body['data']);

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
      const sanitizedData = rawData ? (sanitizeDataValue(rawData, 0) as Record<string, unknown>) : undefined;
      const context = {
        app: 'frontend' as const,
        layer: layerRaw,
        feature,
        requestId,
        jobId,
        endpoint,
        data: sanitizedData,
        stack: stack ? truncateString(stack, MAX_LOG_STACK_LENGTH) : undefined,
        durationMs,
      };
      const safeMessage = truncateString(message, MAX_LOG_MESSAGE_LENGTH);

      switch (levelRaw) {
        case 'debug':
          logger.debug(event, safeMessage, context);
          break;
        case 'info':
          logger.info(event, safeMessage, context);
          break;
        case 'warn':
          logger.warn(event, safeMessage, context);
          break;
        case 'error':
          logger.error(event, safeMessage, context);
          break;
      }

      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}
