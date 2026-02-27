# Logging Plan (Bug-Catching + AI Copy/Paste)

## Goal
- Logs must be detailed enough to find bugs quickly.
- FE must always expose a visible `Copy logs` action on every page.
- BE must output structured logs that can be pasted to AI and diagnosed fast.

## Bug-Catching Rules
- Log at every layer boundary (presentation -> domain -> data -> infra).
- Include correlation ids (`requestId`, `jobId`) in every related event.
- Capture both success and failure milestones (not only errors).
- Keep logs AI-readable: short event names + explicit context fields.
- Redact secrets/tokens/PII centrally before storing or exporting.

## Shared Event Schema (FE + BE)
- `timestamp`: ISO-8601
- `level`: `debug | info | warn | error`
- `app`: `frontend | backend`
- `feature`: `video_processing`
- `layer`: `presentation | domain | data | infrastructure | core`
- `event`: stable key, e.g. `process_clip_cut_failed`
- `requestId`: nullable
- `jobId`: nullable
- `routeOrEndpoint`: FE route or BE endpoint
- `message`: one-line summary
- `data`: sanitized object
- `stack`: optional for errors
- `durationMs`: optional for timed operations

## Frontend Plan (Flutter)

### 1) Core logging package
- Add:
  - `apps/frontend/lib/core/logging/log_entry.dart`
  - `apps/frontend/lib/core/logging/log_buffer.dart`
  - `apps/frontend/lib/core/logging/logger.dart`
  - `apps/frontend/lib/core/logging/log_exporter.dart`
- `log_buffer`: in-memory ring buffer (1000 events default).
- `logger`: `debug/info/warn/error`, context merging, requestId helpers.
- Register in:
  - `apps/frontend/lib/core/di/injection.dart`

### 2) Capture global FE errors automatically
- Wire in `apps/frontend/lib/main.dart`:
  - `FlutterError.onError`
  - `PlatformDispatcher.instance.onError`
  - `BlocObserver` for cubit transition/error logs
- Log uncaught exceptions with stack + current route + last UI action.

### 3) `Copy logs` visible on all FE pages
- Add shared scaffold wrapper:
  - `apps/frontend/lib/core/widgets/app_shell_scaffold.dart`
- Wrapper requirements:
  - Always includes `Copy logs` in `AppBar.actions`.
  - Works across all 6 current routes.
  - Copies AI-ready bug bundle to clipboard.
- Migrate all pages to wrapper:
  - `apps/frontend/lib/features/video_processing/presentation/pages/analyze_input_page.dart`
  - `apps/frontend/lib/features/video_processing/presentation/pages/prompt_builder_page.dart`
  - `apps/frontend/lib/features/video_processing/presentation/pages/ai_json_paste_page.dart`
  - `apps/frontend/lib/features/video_processing/presentation/pages/moments_review_page.dart`
  - `apps/frontend/lib/features/video_processing/presentation/pages/processing_page.dart`
  - `apps/frontend/lib/features/video_processing/presentation/pages/results_page.dart`

### 4) On-Device Log Overlay (for Profile Mode)
- Add `apps/frontend/lib/core/logging/log_overlay.dart`.
- Behavior:
  - Enabled in Debug and Profile modes (`!kReleaseMode`).
  - Floating bug icon button in the bottom-right corner.
  - Toggles a full-screen semi-transparent overlay showing all buffered logs.
  - Includes a `Copy` button to export the AI bundle to the clipboard.
  - Useful for debugging on physical devices (e.g., iPhone via `make iphone`).

### 4) FE logging in different places
- Presentation (pages/widgets):
  - Route enter/exit, button taps, submit attempts, form validation failures, snackbars with error codes.
- State layer (cubits):
  - State transition logs with compact diff and reason.
- Domain (use cases):
  - Start/end/outcome + input summary (counts/ids only).
- Data (datasource/repositories):
  - HTTP request start/end, status, latency, response size, requestId.
- Network interceptors:
  - Request/response/error with truncated body preview and headers allowlist.

### 5) FE AI export format
- `Copy logs` produces:
  - `Issue summary` (auto from latest error events)
  - `Repro timeline` (last 150-300 events)
  - `Network timeline` (request -> response/error)
  - `State transitions` (recent cubit transitions)
  - `Raw JSONL` appendix
- First line template:
  - `AI task: find root cause, point to likely layer/file, propose fix + test.`

## Backend Plan (Node + Express)

### 1) Core structured logger
- Add:
  - `apps/backend/src/core/logging/log_event.ts`
  - `apps/backend/src/core/logging/logger.ts`
  - `apps/backend/src/core/logging/log_formatter.ts`
  - `apps/backend/src/core/logging/redaction.ts`
- Two outputs:
  - JSONL (primary, parseable)
  - concise text line (dev readability)

### 2) Request correlation middleware
- Add:
  - `apps/backend/src/infrastructure/express/request_context.middleware.ts`
- Behavior:
  - Read/create `x-request-id`
  - attach to request + response header
  - log request started/finished with status + latency
- Register in:
  - `apps/backend/src/infrastructure/express/app.ts`

### 3) BE logging in different places
- Presentation (controllers):
  - DTO validation pass/fail, normalized input summary, use case call.
- Domain (use cases):
  - Milestones and decisions.
  - `process_video.usecase.ts`: queued, download start/end, clip start/end per moment, done/failed.
- Data/repositories:
  - storage read/write events, payload sizes, retry attempts.
- Datasources:
  - external tool command start/end/error.
  - include duration, exit code, stderr tail for `yt-dlp` and `ffmpeg`.
- Core errors:
  - `error_middleware.ts` logs structured error with code, requestId, stack.
- Process-level catches:
  - `unhandledRejection`, `uncaughtException` in `main.ts`.

### 4) AI-ready backend export
- Add scripts in `apps/backend/package.json`:
  - `logs:recent` (last N structured lines)
  - `logs:ai` (curated bug bundle)
- Optional helper:
  - `apps/backend/scripts/export_ai_logs.ts`
- `logs:ai` output sections:
  - `Problem summary`
  - `Last failing request/job`
  - `Timeline`
  - `Error clusters`
  - `Raw JSONL`

## Quality Gates (Must Pass)
- FE:
  - `Copy logs` button is visible on every route page.
  - Export contains route, action, request, and state logs around failure.
- BE:
  - Every request has requestId and start/end entries.
  - Every job has end-to-end lifecycle with jobId.
  - External command errors include actionable stderr snippet.
- Security:
  - Redaction tests cover tokens/cookies/authorization/query secrets.

## Rollout Sequence
1. Build shared schema + logger primitives in FE/BE.
2. Add FE global `Copy logs` scaffold and global error hooks.
3. Add BE request context middleware and all layer instrumentation.
4. Add AI export (`Copy logs` on FE, `logs:ai` on BE).
5. Validate on success path and forced failures (invalid payload, ffmpeg failure, network timeout).

## Validation Scenarios
- FE:
  - bad URL -> validation failure logs
  - backend 500 -> request + state + UI error logs
  - page navigation across all 6 pages -> `Copy logs` always visible
- BE:
  - invalid DTO -> controller + error middleware logs
  - yt-dlp failure -> datasource + use case + final error logs
  - ffmpeg failure on one clip -> per-clip failure + job failed event

## Risks / Mitigations
- Too much noise:
  - keep default level `info`, use `debug` selectively, cap FE buffer.
- Missing correlation:
  - enforce `requestId/jobId` presence in logger wrapper.
- AI-unfriendly dumps:
  - curated timeline first, raw logs second.
