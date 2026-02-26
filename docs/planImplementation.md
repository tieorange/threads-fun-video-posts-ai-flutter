# planImplementation.md

## 1. Objective
Implement an MVP web app that converts a long YouTube video into short funny clips users can download to their devices as files, plus ready-to-post social text, using a manual AI copy/paste workflow.

## 2. Scope and Constraints
- Frontend: Flutter Web with Material Design 3.
- Backend: Express + strongly typed TypeScript (`strict` mode, no `any`).
- Architecture: clean architecture per feature with 3 layers (`presentation`, `domain`, `data`).
- No database for MVP; local filesystem only.
- No tests required in this phase.

## 3. Monorepo Layout
```
.
├── apps/
│   ├── backend/
│   │   ├── src/
│   │   │   ├── core/
│   │   │   │   ├── config/
│   │   │   │   ├── errors/
│   │   │   │   └── utils/
│   │   │   ├── features/
│   │   │   │   └── video_processing/
│   │   │   │       ├── presentation/
│   │   │   │       │   ├── controllers/
│   │   │   │       │   ├── routes/
│   │   │   │       │   └── dtos/
│   │   │   │       ├── domain/
│   │   │   │       │   ├── entities/
│   │   │   │       │   ├── repositories/
│   │   │   │       │   ├── usecases/
│   │   │   │       │   └── value_objects/
│   │   │   │       └── data/
│   │   │   │           ├── datasources/
│   │   │   │           ├── models/
│   │   │   │           └── repositories/
│   │   │   ├── infrastructure/
│   │   │   │   └── express/
│   │   │   └── main.ts
│   │   ├── storage/
│   │   │   ├── captions/
│   │   │   ├── videos/
│   │   │   ├── clips/
│   │   │   └── jobs/
│   │   └── package.json
│   └── frontend/
│       ├── lib/
│       │   ├── core/
│       │   │   ├── di/
│       │   │   ├── failures/
│       │   │   ├── theme/
│       │   │   └── utils/
│       │   ├── features/
│       │   │   └── video_processing/
│       │   │       ├── presentation/
│       │   │       ├── domain/
│       │   │       └── data/
│       │   └── main.dart
│       └── pubspec.yaml
└── docs/
    └── plan.md
```

## 4. Backend Detailed Design (Express + Strict TypeScript)

## 4.1 TypeScript baseline
- `tsconfig`:
  - `"strict": true`
  - `"noUncheckedIndexedAccess": true`
  - `"noImplicitOverride": true`
  - `"exactOptionalPropertyTypes": true`
- ESLint rules should fail usage of `any`.

## 4.2 Domain entities
- `VideoMetadata`
  - `videoId: string`
  - `title: string`
  - `durationSec: number`
  - `sourceUrl: string`
- `TranscriptSegment`
  - `startSec: number`
  - `endSec: number`
  - `text: string`
- `FunnyMoment`
  - `id: string`
  - `startSec: number`
  - `endSec: number`
  - `caption: string`
  - `postText: string`
  - `reason: string`
- `AiMomentsPayload`
  - `videoTitle: string`
  - `language: 'uk' | 'uk_18' | 'en' | 'ru'`
  - `moments: FunnyMoment[]`

## 4.3 Use cases
1. `AnalyzeVideoUseCase`
   - Input: URL + language.
   - Process: fetch metadata + captions using yt-dlp (without full download).
   - Output: metadata + normalized transcript for prompt generation.
2. `ValidateAiPayloadUseCase`
   - Input: raw JSON pasted by user.
   - Process: zod validation + business checks (duration, overlap, count).
   - Output: typed `AiMomentsPayload`.
3. `ProcessVideoUseCase`
   - Input: URL + typed moments.
   - Process: full video download once, cut clips with FFmpeg.
   - Output: job result with generated clips.
4. `GetProcessStatusUseCase`
   - Input: jobId.
   - Output: `queued|running|failed|done` + progress + artifacts.

## 4.4 Data sources
- `YtDlpDataSource`
  - methods for metadata, caption extraction, and full download.
- `FfmpegDataSource`
  - cut clip from input by `startSec` and `durationSec`.
- `LocalStorageDataSource`
  - path management, job JSON files, clip files.

## 4.5 HTTP endpoints (v1)
1. `POST /api/v1/videos/analyze`
   - Request:
```json
{
  "youtubeUrl": "https://www.youtube.com/watch?v=...",
  "language": "en"
}
```
   - Response:
```json
{
  "video": {
    "videoId": "abc123",
    "title": "Sample",
    "durationSec": 3600,
    "sourceUrl": "..."
  },
  "transcript": [
    { "startSec": 0, "endSec": 3, "text": "..." }
  ],
  "language": "en"
}
```

2. `POST /api/v1/videos/process`
   - Request:
```json
{
  "youtubeUrl": "https://www.youtube.com/watch?v=...",
  "aiPayload": {
    "videoTitle": "Sample",
    "language": "en",
    "moments": [
      {
        "id": "m1",
        "startSec": 123,
        "endSec": 165,
        "caption": "...",
        "postText": "...",
        "reason": "..."
      }
    ]
  }
}
```
   - Response:
```json
{
  "jobId": "job_20260226_001",
  "status": "queued"
}
```

3. `GET /api/v1/videos/process/:jobId`
   - Response:
```json
{
  "jobId": "job_20260226_001",
  "status": "running",
  "progress": 65,
  "clips": [
    {
      "momentId": "m1",
      "startSec": 123,
      "endSec": 165,
      "downloadUrl": "/media/clips/job_20260226_001_m1.mp4"
    }
  ],
  "error": null
}
```

4. `GET /media/clips/:fileName`
- Serves generated clip with range support for video preview.

## 4.6 Job execution model
- Start with in-process async queue (single worker).
- Persist job state in `storage/jobs/<jobId>.json`.
- Update progress by stage:
  - 10% metadata ready
  - 30% full download ready
  - 30-95% clip cutting loop
  - 100% done

## 5. Frontend Detailed Design (Flutter + Material 3)

## 5.1 App flow screens
1. `AnalyzeInputPage`
   - URL input
   - language selector
   - analyze action
2. `PromptBuilderPage`
   - shows generated AI prompt from transcript + schema
   - copy-to-clipboard CTA
3. `AiJsonPastePage`
   - text area for AI JSON
   - validate JSON action
   - submit process action
4. `ProcessingPage`
   - progress indicator and status polling
5. `ResultsPage`
   - list of moments/cards
   - copy post text button
   - clip preview player
   - download clip action

## 5.2 Material 3 requirements
- `ThemeData(useMaterial3: true)` for light and dark themes.
- Use `ColorScheme.fromSeed` for consistent brand palette.
- Use Material components (FilledButton, Card, NavigationBar, SnackBar).
- Responsive layout:
  - mobile: single-column flow
  - tablet/desktop: split panes for form + preview/results

## 5.3 Frontend feature internals
- `presentation`
  - Cubits:
    - `AnalyzeCubit`
    - `PromptCubit`
    - `ProcessCubit`
    - `ResultsCubit`
- `domain`
  - entities mirroring backend contracts
  - repository abstractions
  - use cases for each action
- `data`
  - Dio datasource
  - repository implementations
  - DTO serialization (`freezed` + `json_serializable`)

## 6. Prompt Generation Specification (Frontend)
Generated prompt must include:
1. Role instruction (viral comedy content assistant).
2. Selected language profile behavior.
3. Full transcript with timestamps.
4. Mandatory output JSON schema.
5. Hard constraints:
   - 3 to 10 moments
   - no overlap
   - seconds-based timestamps
   - post text should be platform-ready and concise

## 7. Error Handling Strategy
- Backend returns typed error envelope:
```json
{
  "code": "INVALID_AI_PAYLOAD",
  "message": "Moments overlap",
  "details": {}
}
```
- Frontend maps backend errors to user-friendly messages.
- Parsing failures show actionable hints (invalid JSON, missing fields, invalid timestamps).

## 8. Security and Limits (MVP)
- Validate URL format and allowed hosts (YouTube only).
- Sanitize filenames and avoid path traversal.
- Cap max moments to 10.
- Cap max clip duration to 120 seconds.

## 9. Implementation Sequence
1. Bootstrap backend with strict TS + Express app + DI wiring.
2. Implement analyze endpoint and transcript extraction.
3. Implement AI payload validation.
4. Implement process job queue + FFmpeg clipping + media serving.
5. Bootstrap Flutter app with Material 3 theme and routes.
6. Implement analyze + prompt builder flow.
7. Implement AI JSON paste + process trigger flow.
8. Implement polling + results/preview/download UI.
9. Manual end-to-end verification with a real video.

## 10. Manual Verification Checklist (No Tests)
1. Analyze a valid 1-hour YouTube URL.
2. Confirm transcript data appears in prompt builder.
3. Paste valid AI JSON and start processing.
4. Verify status transitions and progress updates.
5. Verify all generated clips play and download.
6. Verify copy-post-text button works for each moment.
7. Verify invalid JSON and overlap errors are handled clearly.

## 11. Done Criteria
- End-to-end flow works locally without external DB.
- Backend is strict, typed, and Express-based.
- Frontend is Material 3 and responsive.
- Feature-first clean architecture is enforced in both FE and BE.
- Manual verification checklist passes.
