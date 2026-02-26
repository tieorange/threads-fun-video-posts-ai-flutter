/**
 * export_ai_logs.ts
 * Reads logs/app.jsonl and prints an AI-friendly bug bundle to stdout.
 * Usage: npm run logs:ai
 */

import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';

interface LogEntry {
  timestamp: string;
  level: 'debug' | 'info' | 'warn' | 'error';
  layer: string;
  event: string;
  requestId: string | null;
  jobId: string | null;
  endpoint: string | null;
  message: string;
  data?: Record<string, unknown>;
  stack?: string;
  durationMs?: number;
}

const LOG_FILE = path.join(process.cwd(), 'logs', 'app.jsonl');
const MAX_RECENT = 300;

async function readLastLines(filePath: string, maxLines: number): Promise<LogEntry[]> {
  const entries: LogEntry[] = [];
  if (!fs.existsSync(filePath)) {
    console.error(`Log file not found: ${filePath}\nRun 'npm run dev' first to generate logs.`);
    process.exit(1);
  }

  const rl = readline.createInterface({
    input: fs.createReadStream(filePath),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    try {
      entries.push(JSON.parse(line) as LogEntry);
    } catch {
      // skip malformed lines
    }
  }

  return entries.slice(-maxLines);
}

function section(title: string): string {
  const bar = '='.repeat(60);
  return `\n${bar}\n## ${title}\n${bar}\n`;
}

async function main(): Promise<void> {
  const entries = await readLastLines(LOG_FILE, MAX_RECENT);

  const errors = entries.filter((e) => e.level === 'error');
  const warnings = entries.filter((e) => e.level === 'warn');
  const networkEntries = entries.filter(
    (e) => e.layer === 'infrastructure' && (e.event === 'request_started' || e.event === 'request_finished'),
  );
  const jobEntries = entries.filter((e) => e.jobId !== null);

  const out: string[] = [];

  out.push('AI task: find root cause, point to likely layer/file, propose fix + test.\n');

  // Problem summary
  out.push(section('Problem summary'));
  if (errors.length === 0) {
    out.push('No errors in recent logs.\n');
  } else {
    out.push(`${errors.length} error(s) found:\n`);
    errors.slice(-5).forEach((e) => {
      out.push(`  [${e.timestamp}] ${e.layer}/${e.event}: ${e.message}`);
      if (e.data) out.push(`    data: ${JSON.stringify(e.data)}`);
      if (e.stack) out.push(`    stack: ${e.stack.split('\n').slice(0, 3).join(' | ')}`);
    });
  }
  if (warnings.length > 0) {
    out.push(`\n${warnings.length} warning(s):\n`);
    warnings.slice(-3).forEach((e) => {
      out.push(`  [${e.timestamp}] ${e.layer}/${e.event}: ${e.message}`);
    });
  }

  // Last failing request
  out.push(section('Last failing request / job'));
  const lastError = errors[errors.length - 1];
  if (lastError) {
    const rid = lastError.requestId;
    const jid = lastError.jobId;
    const related = entries.filter(
      (e) => (rid && e.requestId === rid) || (jid && e.jobId === jid),
    );
    related.forEach((e) => {
      out.push(`  [${e.timestamp}] ${e.level.toUpperCase()} ${e.layer}/${e.event}: ${e.message}`);
    });
  } else {
    out.push('No failing request/job found.\n');
  }

  // Network timeline
  out.push(section('Network timeline (last 20 requests)'));
  networkEntries.slice(-20).forEach((e) => {
    const dur = e.durationMs !== undefined ? ` ${e.durationMs}ms` : '';
    const rid = e.requestId ? ` rid=${e.requestId.slice(0, 8)}` : '';
    out.push(`  [${e.timestamp}]${rid}${dur} ${e.event}: ${e.message}`);
  });

  // Job timeline
  out.push(section('Job lifecycle (last 10 job events)'));
  jobEntries.slice(-10).forEach((e) => {
    const dur = e.durationMs !== undefined ? ` ${e.durationMs}ms` : '';
    out.push(`  [${e.timestamp}] job=${e.jobId ?? '?'}${dur} ${e.level.toUpperCase()} ${e.event}: ${e.message}`);
  });

  // Raw JSONL (recent)
  out.push(section(`Raw JSONL (last ${Math.min(entries.length, 100)} entries)`));
  entries.slice(-100).forEach((e) => out.push(JSON.stringify(e)));

  console.log(out.join('\n'));
}

main().catch((err: unknown) => {
  console.error('export_ai_logs failed:', err);
  process.exit(1);
});
