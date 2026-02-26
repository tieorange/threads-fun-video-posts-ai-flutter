# Implementation Guide

> Status: **implemented** — see `apps/backend/` and `apps/frontend/`

## Quick Start

```bash
# Prerequisites: Node 22+, Flutter 3.27+, yt-dlp, ffmpeg on $PATH

# 1. Backend
cd apps/backend && npm install && npm run dev
# → http://localhost:3000

# 2. Frontend (new terminal)
cd apps/frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

---

## What Was Built

### Phase 0 — Scaffolding
- `apps/backend/` — Express + TypeScript strict skeleton with clean architecture folders
- `apps/frontend/` — Flutter web app scaffolded with `flutter create --platforms=web`
- Material 3 theme (`ColorScheme.fromSeed`, light + dark)
- GoRouter with 6 named routes

### Phase 1 — Backend Core
- Domain entities: `VideoMetadata`, `TranscriptSegment`, `FunnyMoment`, `AiMomentsPayload`, `JobRecord`
- 4 use cases: `AnalyzeVideoUseCase`, `ValidateAiPayloadUseCase`, `ProcessVideoUseCase`, `GetProcessStatusUseCase`
- Data sources: `YtDlpDataSource` (metadata + captions + download), `FfmpegDataSource` (clip cutting), `LocalStorageDataSource` (job JSON persistence)
- 3 API endpoints + static media serving with `Accept-Ranges`
- In-process async job queue with progress tracking

### Phase 2 — Frontend Core
- 5 domain use cases including `BuildAiPromptUseCase` (pure Dart, no network)
- Dio datasource with typed error mapping → `Failure` sealed class
- 5 Cubits with Dart 3 sealed states: `AnalyzeCubit`, `PromptCubit`, `JsonPasteCubit`, `MomentsReviewCubit`, `ProcessCubit`
- GetIt DI wiring

### Phase 3 — Updated Workflow (YouTube-first)
**Changed from original spec:** Video download is deferred until the user selects moments to keep.

New flow:
1. Analyze → transcript only (no download)
2. Build AI prompt → copy to clipboard
3. Paste AI JSON → client-side validation (3-10 moments, no overlap, max 120s duration)
4. **Review page with YouTube iframes** — each moment shown as an embedded player with `start`/`end` timestamp params; user taps to select/deselect
5. Press "Generate Posts" → only selected moments are sent; backend downloads video + cuts those clips
6. Results page with Chewie player preview, post-text copy button, download link

---

## Key Files

| File | Purpose |
|---|---|
| `apps/backend/src/main.ts` | Server entry point |
| `apps/backend/src/infrastructure/express/app.ts` | DI wiring, middleware, routing |
| `apps/backend/src/features/video_processing/domain/usecases/validate_ai_payload.usecase.ts` | Zod + business rules |
| `apps/backend/src/features/video_processing/domain/usecases/process_video.usecase.ts` | Async job + FFmpeg cutting |
| `apps/backend/src/features/video_processing/data/datasources/yt_dlp.datasource.ts` | yt-dlp integration |
| `apps/frontend/lib/main.dart` | Flutter entry, DI init, router |
| `apps/frontend/lib/core/utils/router.dart` | GoRouter, shared cubit instances |
| `apps/frontend/lib/features/video_processing/domain/usecases/build_ai_prompt_usecase.dart` | AI prompt builder |
| `apps/frontend/lib/features/video_processing/presentation/pages/moments_review_page.dart` | YouTube iframe preview + selection |
| `apps/frontend/lib/features/video_processing/presentation/pages/results_page.dart` | Clip player + download |

---

## Validation Rules

### Client-side (JSON paste step — enforces AI quality)
- Moments count: 3-10
- `endSec > startSec`
- `endSec - startSec <= 120s`
- No overlap

### Backend process endpoint (user-selected moments)
- Moments count: 1-10 (user may intentionally select fewer than 3)
- `endSec > startSec`
- `endSec - startSec <= 120s`
- No overlap

---

## Manual Verification Checklist

1. `npm run dev` starts on port 3000 without errors
2. `POST /api/v1/videos/analyze` with a valid YouTube URL returns `video` + `transcript`
3. Generated prompt on `PromptBuilderPage` contains transcript and JSON schema
4. Paste valid AI JSON on `AiJsonPastePage` → advances to `MomentsReviewPage`
5. YouTube iframes load with correct start/end timestamps
6. Select a subset of moments, press "Generate Posts"
7. `ProcessingPage` shows progress increments, transitions to `ResultsPage` at 100%
8. Each clip previews with Chewie player and downloads correctly
9. Copy-post-text button copies the right text per clip
10. Invalid JSON (bad format, overlapping moments) shows error card with clear message
11. "Start Over" resets all state and returns to step 1

---

## Known Constraints (MVP)

- Single worker: one job at a time; concurrent job support is post-MVP
- No authentication: intended for local use only
- Storage not cleaned up: delete `storage/videos/` and `storage/clips/` manually between runs
- YouTube iframes may be blocked by browser CORS policies on some enterprise networks
