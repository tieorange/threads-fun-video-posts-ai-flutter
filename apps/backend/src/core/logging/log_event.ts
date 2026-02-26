export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export type AppLayer =
  | 'presentation'
  | 'domain'
  | 'data'
  | 'infrastructure'
  | 'core';

export interface LogEvent {
  readonly timestamp: string;
  readonly level: LogLevel;
  readonly app: 'backend';
  readonly feature: 'video_processing' | 'core';
  readonly layer: AppLayer;
  readonly event: string;
  readonly requestId: string | null;
  readonly jobId: string | null;
  readonly endpoint: string | null;
  readonly message: string;
  readonly data?: Record<string, unknown>;
  readonly stack?: string;
  readonly durationMs?: number;
}
