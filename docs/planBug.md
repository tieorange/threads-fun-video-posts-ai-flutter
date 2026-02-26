# planBug.md

## Verification Summary
- Backend build: `npm run build` in `apps/backend` -> passed.
- Backend lint: `npm run lint` in `apps/backend` -> failed (1 error).
- Frontend static check: could not run because local Flutter SDK permissions are broken (`/usr/local/Caskroom/flutter/.../bin/cache/lockfile`).
- Manual code review completed for backend and frontend critical flows.

## Bugs To Fix (Priority Ordered)

## P0
1. **Caption extraction implementation is incompatible with `yt-dlp` JSON shape**
- File: `apps/backend/src/features/video_processing/data/datasources/yt_dlp.datasource.ts:63-76`
- Problem: code treats `automatic_captions/subtitles` as transcript entries (`start/end/text`), but yt-dlp returns format descriptors with URLs. This makes transcript parsing fail or return invalid data.
- Fix:
  - Fetch subtitle file URL from yt-dlp metadata.
  - Download/parse subtitle content (`json3`/`vtt`) into `TranscriptSegment[]`.
  - Add explicit fallback when captions are unavailable.
- Acceptance:
  - `POST /api/v1/videos/analyze` returns non-empty transcript for a video with auto captions.

2. **Frontend JSON parsing can crash when AI returns wrong field types**
- Files:
  - `apps/frontend/lib/features/video_processing/domain/usecases/validate_and_parse_json_usecase.dart:38-40`
  - `apps/frontend/lib/features/video_processing/presentation/cubits/json_paste_cubit.dart:21-27`
- Problem: validator checks only field presence, then cubit force-casts `startSec/endSec` to `num`. If AI returns strings, runtime exception occurs.
- Fix:
  - Validate types in `ValidateAndParseJsonUseCase` (`id/caption/postText/reason` as string, `startSec/endSec` as number).
  - Wrap conversion in safe parsing and emit `JsonPasteInvalid` instead of throwing.
- Acceptance:
  - Invalid type payload never crashes UI and always shows validation message.

## P1
3. **AI moments count constraint mismatch with plan requirements**
- Files:
  - `apps/backend/src/features/video_processing/presentation/dtos/process_request.dto.ts:17`
  - `apps/backend/src/features/video_processing/domain/usecases/validate_ai_payload.usecase.ts:17`
- Problem: backend allows `1..10` moments, but plan requires `3..10`.
- Fix: change both schema constraints to `.min(3).max(10)` and keep one source-of-truth constant.
- Acceptance:
  - backend rejects payloads with <3 moments using consistent error code/message.

4. **Downloaded file extension is assumed as `.mp4`, can break clip cutting**
- File: `apps/backend/src/features/video_processing/data/datasources/yt_dlp.datasource.ts:84-93`
- Problem: function always returns `<jobId>.mp4`, but yt-dlp fallback may produce non-mp4 output.
- Fix:
  - force mp4 output (`--merge-output-format mp4`) or
  - detect actual output file path from yt-dlp result and return real path.
- Acceptance:
  - FFmpeg cut succeeds for videos where yt-dlp fallback format is not mp4 by default.

5. **Lint is failing in backend (CI blocker)**
- File: `apps/backend/src/core/errors/error_middleware.ts:8`
- Problem: `_next` parameter unused with `@typescript-eslint/no-unused-vars` set to error.
- Fix: remove parameter and keep 4-arg signature via ignored pattern config, or rename and configure ignore rule.
- Acceptance:
  - `npm run lint` passes in `apps/backend`.

## P2
6. **Polling loop can overlap requests and produce race conditions**
- File: `apps/frontend/lib/features/video_processing/presentation/cubits/process_cubit.dart:40-61`
- Problem: `Timer.periodic` with async callback can start a new poll before previous request finishes.
- Fix:
  - serialize polling (`if (_polling) return` guard) or
  - replace periodic timer with await-loop + delay.
- Acceptance:
  - only one in-flight `getJobStatus` request exists at any time.

7. **Clip download UX may open stream instead of saving file on web**
- File: `apps/frontend/lib/features/video_processing/presentation/pages/results_page.dart:111-116`
- Problem: `url_launcher` external open is not guaranteed to trigger file download behavior.
- Fix:
  - implement web download via `<a download>` flow, and/or
  - backend sets `Content-Disposition: attachment` for explicit download endpoint.
- Acceptance:
  - clicking Download saves an `.mp4` file locally in browser-supported flow.

8. **Job load swallows all IO/parse failures as "not found"**
- File: `apps/backend/src/features/video_processing/data/datasources/local_storage.datasource.ts:16-22`
- Problem: any read/parse error returns `null`, masking corruption/permission errors.
- Fix:
  - return `null` only for ENOENT.
  - throw typed `AppError` for other failures.
- Acceptance:
  - corrupted job file returns server error, missing file returns 404.

## P3
9. **Review route/state can become stale across retries/navigation**
- File: `apps/frontend/lib/core/utils/router.dart:33-35, 63-79`
- Problem: shared mutable globals (`_reviewYoutubeUrl`, `_reviewAiPayload`) can leak stale data between flows.
- Fix:
  - pass required data through typed route params/extra each time, avoid globals.
  - reset review state on new analyze flow.
- Acceptance:
  - repeat runs do not reuse old payload/video URL accidentally.

## Suggested Fix Order
1. P0.1, P0.2
2. P1.3, P1.4, P1.5
3. P2.6, P2.7, P2.8
4. P3.9
