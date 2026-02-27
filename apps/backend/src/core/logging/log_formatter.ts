import { type LogEvent } from './log_event';

export function formatJsonl(event: LogEvent): string {
  return JSON.stringify(event);
}

export function formatText(event: LogEvent): string {
  const lvl = event.level.toUpperCase().padEnd(5);
  const rid = event.requestId ? ` rid=${event.requestId.slice(0, 8)}` : '';
  const jid = event.jobId ? ` job=${event.jobId}` : '';
  const dur = event.durationMs !== undefined ? ` ${event.durationMs}ms` : '';
  let msg = `[${event.timestamp}] ${lvl} [${event.app}] [${event.layer}] ${event.event}${rid}${jid}${dur} — ${event.message}`;
  if (event.stack) {
    msg += `\nSTACK: ${event.stack}`;
  }
  return msg;
}
