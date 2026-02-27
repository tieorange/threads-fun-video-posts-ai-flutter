import { AsyncLocalStorage } from 'node:async_hooks';
import fs from 'node:fs';
import path from 'node:path';
import { type LogEvent, type LogLevel, type AppLayer } from './log_event';
import { formatJsonl, formatText } from './log_formatter';

interface RequestContext {
  requestId: string;
  endpoint: string;
  jobId?: string;
}

export interface LogContext {
  app?: 'backend' | 'frontend';
  feature?: 'video_processing' | 'core';
  layer: AppLayer;
  requestId?: string;
  jobId?: string;
  endpoint?: string;
  data?: Record<string, unknown>;
  stack?: string;
  durationMs?: number;
}

const LEVEL_ORDER: Record<LogLevel, number> = { debug: 0, info: 1, warn: 2, error: 3 };

const _asyncLocalStorage = new AsyncLocalStorage<RequestContext>();

// Ensure log directory exists and open write stream
const LOG_DIR = process.env['LOG_DIR'] ?? path.join(process.cwd(), 'logs');
fs.mkdirSync(LOG_DIR, { recursive: true });
const _logStream = fs.createWriteStream(path.join(LOG_DIR, 'app.jsonl'), { flags: 'a' });

class Logger {
  private _minLevel: LogLevel =
    (process.env['LOG_LEVEL'] as LogLevel | undefined) ?? 'info';

  setLevel(level: LogLevel): void {
    this._minLevel = level;
  }

  /** Run fn inside an async context with requestId/endpoint for automatic propagation. */
  runWithContext(ctx: RequestContext, fn: () => void): void {
    _asyncLocalStorage.run(ctx, fn);
  }

  /** Update jobId in the current async context (call after job creation). */
  setJobId(jobId: string): void {
    const store = _asyncLocalStorage.getStore();
    if (store) store.jobId = jobId;
  }

  getRequestId(): string | undefined {
    return _asyncLocalStorage.getStore()?.requestId;
  }

  private _shouldLog(level: LogLevel): boolean {
    return LEVEL_ORDER[level] >= LEVEL_ORDER[this._minLevel];
  }

  private _emit(level: LogLevel, event: string, message: string, ctx: LogContext): void {
    if (!this._shouldLog(level)) return;

    const store = _asyncLocalStorage.getStore();
    const logEvent: LogEvent = {
      timestamp: new Date().toISOString(),
      level,
      app: ctx.app ?? 'backend',
      feature: ctx.feature ?? 'video_processing',
      layer: ctx.layer,
      event,
      requestId: ctx.requestId ?? store?.requestId ?? null,
      jobId: ctx.jobId ?? store?.jobId ?? null,
      endpoint: ctx.endpoint ?? store?.endpoint ?? null,
      message,
      ...(ctx.data !== undefined ? { data: ctx.data } : {}),
      ...(ctx.stack !== undefined ? { stack: ctx.stack } : {}),
      ...(ctx.durationMs !== undefined ? { durationMs: ctx.durationMs } : {}),
    };

    _logStream.write(formatJsonl(logEvent) + '\n');
    process.stderr.write(formatText(logEvent) + '\n');
  }

  debug(event: string, message: string, ctx: LogContext): void {
    this._emit('debug', event, message, ctx);
  }

  info(event: string, message: string, ctx: LogContext): void {
    this._emit('info', event, message, ctx);
  }

  warn(event: string, message: string, ctx: LogContext): void {
    this._emit('warn', event, message, ctx);
  }

  error(event: string, message: string, ctx: LogContext): void {
    this._emit('error', event, message, ctx);
  }
}

export const logger = new Logger();
export { _asyncLocalStorage as asyncLocalStorage };
export type { RequestContext };
