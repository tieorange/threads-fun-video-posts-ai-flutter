# Architecture

## Monorepo Structure

```
.
├── apps/
│   ├── backend/          Node 22 + Express + TypeScript (strict)
│   └── frontend/         Flutter Web + Material 3
└── docs/
```

---

## Backend — Clean Architecture

```
src/
  core/
    config/env.ts                 # PORT, STORAGE_PATH, CORS_ORIGIN
    errors/
      app_error.ts                # Typed AppError with ErrorCode
      error_middleware.ts         # Express global error handler → {code, message, details}
  features/
    video_processing/
      domain/
        entities/                 # Pure interfaces (no runtime deps)
          video_metadata.ts
          transcript_segment.ts
          funny_moment.ts
          ai_moments_payload.ts   # Language = 'uk'|'uk_18'|'en'|'ru'
          job_record.ts           # JobStatus = 'queued'|'running'|'failed'|'done'
        repositories/             # Interfaces only
          video_repository.interface.ts
          job_repository.interface.ts
        usecases/
          analyze_video.usecase.ts        # metadata + captions (no download)
          validate_ai_payload.usecase.ts  # zod + business rules (overlap, duration)
          process_video.usecase.ts        # creates job, downloads, cuts clips
          get_process_status.usecase.ts   # reads job JSON from disk
      data/
        datasources/
          yt_dlp.datasource.ts    # yt-dlp-exec wrapper
          ffmpeg.datasource.ts    # fluent-ffmpeg wrapper (IFfmpegDataSource)
          local_storage.datasource.ts  # job JSON r/w, path helpers
        repositories/
          video_repository.impl.ts
          job_repository.impl.ts
      presentation/
        controllers/              # validate DTO → call use case → return JSON
          analyze.controller.ts
          process.controller.ts
          job_status.controller.ts
        routes/video.routes.ts
        dtos/
          analyze_request.dto.ts  # youtubeUrl (regex) + language
          process_request.dto.ts  # youtubeUrl + aiPayload (min 1 moment)
  infrastructure/
    express/app.ts                # DI wiring, CORS, static /media/clips, error mw
  main.ts
storage/
  captions/   videos/   clips/   jobs/    # gitignored, created at startup
```

### Job Execution Model

- In-process async queue (single worker, no external queue dependency).
- Job state persisted to `storage/jobs/<jobId>.json` after every stage.
- Progress: 0% → 10% (metadata) → 30% (download) → 50% (transcript) → 95% (clip loop) → 100% (complete).

---

## Frontend — Clean Architecture

```
lib/
  core/
    di/injection.dart       # GetIt wiring: datasource → repo → usecase → cubit
    failures/failure.dart   # Sealed: NetworkFailure | ValidationFailure | ServerFailure | UnexpectedFailure
    theme/app_theme.dart    # Material 3, ColorScheme.fromSeed, light + dark
    utils/router.dart       # GoRouter with 6 named routes, shared cubit instances
  features/
    video_processing/
      domain/
        entities/           # Plain Dart classes (no codegen needed)
        repositories/       # Abstract interfaces using Either<Failure, T>
        usecases/
          analyze_video_usecase.dart
          build_ai_prompt_usecase.dart      # Pure Dart — builds AI prompt string
          validate_and_parse_json_usecase.dart  # Client-side JSON validation
          submit_process_usecase.dart
          poll_job_status_usecase.dart
      data/
        datasources/video_remote_datasource.dart  # Dio → backend API
        dtos/               # Manual fromJson/toDomain (no codegen)
        repositories/       # Implementations wrapping datasource + error mapping
      presentation/
        cubits/             # 5 cubits with sealed state classes
        pages/              # 6 pages
  main.dart
```

### User Flow (6 Screens)

```
1. AnalyzeInputPage      URL + language → POST /analyze
2. PromptBuilderPage     Generated prompt + copy to clipboard
3. AiJsonPastePage       Paste AI JSON → client-side validation
4. MomentsReviewPage     YouTube iframes with timestamps, tap-to-select
                         ↳ "Generate N Posts" → POST /process (selected only)
5. ProcessingPage        Poll every 2s, LinearProgressIndicator
6. ResultsPage           Chewie player + post-text copy + download
```

### Key Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| No AI API key | Manual copy/paste workflow | Local-first, no cost, any AI tool works |
| YouTube iframes FIRST | Review before download | Avoids wasting bandwidth on unwanted clips |
| Sealed state classes | Dart 3 `sealed` keyword | No extra `equatable` dependency |
| Manual DTOs | No `freezed`/`json_serializable` codegen | Simpler, faster dev, fewer build steps |
| `get_it` for DI | `GetIt.instance` singletons | Avoids `BuildContext`-dependent DI |
| GoRouter + shared cubits | `late final` globals + `BlocProvider.value` | Cubits survive route transitions |
| Video caching | Local filesystem with content-addressable symlinks | Avoids re-downloading same video for different jobs |
| Background cleanup | `setInterval` (1hr) + startup scan | Automatic resource management for stale videos/clips |
| Job recovery on startup | `recover_stale_jobs.usecase.ts` runs at boot | Handles interrupted jobs from previous sessions |

---

## API Contract

### `POST /api/v1/videos/analyze`
```json
// Request
{ "youtubeUrl": "https://...", "language": "en" }

// Response
{
  "video": { "videoId": "...", "title": "...", "durationSec": 3600, "sourceUrl": "..." },
  "transcript": [{ "startSec": 0, "endSec": 3, "text": "..." }],
  "language": "en"
}
```

### `POST /api/v1/videos/process`
```json
// Request
{
  "youtubeUrl": "https://...",
  "aiPayload": {
    "videoTitle": "...", "language": "en",
    "moments": [{ "id": "m1", "startSec": 123, "endSec": 165, "caption": "...", "postText": "...", "reason": "..." }]
  }
}

// Response
{ "jobId": "job_20260226_a1b2c3d4", "status": "queued" }
```

### `GET /api/v1/videos/process/:jobId`
```json
{
  "jobId": "...", "status": "running", "progress": 65,
  "clips": [{ "momentId": "m1", "startSec": 123, "endSec": 165, "downloadUrl": "/media/clips/job_..._m1.mp4" }],
  "error": null
}
```

### `GET /media/clips/:fileName`
Static file serving with `Accept-Ranges` header for video streaming.

### Error Envelope
```json
{ "code": "MOMENTS_OVERLAP", "message": "Moments m1 and m2 overlap.", "details": {} }
```

Error codes: `INVALID_URL` · `INVALID_LANGUAGE` · `INVALID_AI_PAYLOAD` · `MOMENTS_OVERLAP` · `MOMENTS_DURATION_EXCEEDED` · `TRANSCRIPT_FETCH_FAILED` · `DOWNLOAD_FAILED` · `CLIP_CUT_FAILED` · `JOB_NOT_FOUND` · `INTERNAL_ERROR`
