# Master Prompt for AI Agents - Funny Threads AI

## 1. Project Context
- Product: `Funny Threads AI` (aka `ThreadGen AI`)
- Goal: Build a local-first app that turns a long YouTube video (up to ~1 hour) into `3-10` short funny clips users can download as files to their devices, plus ready-to-post social text for later publishing.
- Platforms:
  - Frontend: Flutter Web
  - Backend: Node.js + Express + TypeScript
- Core rule: Do not integrate Gemini/OpenAI/Claude APIs. The user manually copies a generated prompt into an external AI tool and pastes JSON back into the app.

## 2. Hard Constraints (Do Not Violate)
1. Backend framework must be `Express`.
2. Backend code must be strongly typed TypeScript:
   - `"strict": true`
   - no `any`
   - typed request/response DTOs
   - runtime validation for external input (recommended: `zod`)
3. Frontend design system must use `Material Design 3` (no glassmorphic/neumorphic requirements).
4. Use clean architecture with 3 layers per feature:
   - `presentation`
   - `domain`
   - `data`
5. Local filesystem storage only (no database for MVP).
6. Testing is out of scope for now (no unit/integration test tasks in this phase).

## 3. User Journey (End-to-End)
1. User opens Flutter web app.
2. User selects language profile:
   - Ukrainian
   - Ukrainian 18+
   - English
   - Russian
3. User pastes YouTube URL and clicks `Analyze`.
4. Backend extracts metadata + captions/subtitles without full video download first.
5. Frontend builds a copy-ready AI prompt (includes transcript, strict JSON schema, and language instructions).
6. User copies prompt to external AI tool and receives JSON.
7. User pastes JSON back into app.
8. Backend downloads full video once and cuts clips via FFmpeg using AI timestamps.
9. Frontend shows list of moments, copy buttons for post text, clip preview, and download links.

## 4. Technical Stack
### Frontend (Flutter Web)
- Flutter stable (3.27+ acceptable)
- `flutter_bloc` (Cubit-based)
- `fpdart`
- Manual DTOs for video_processing (no codegen; `freezed`/`json_serializable` deps present but only used for i18n via slang)
- `dio`
- `go_router`
- `video_player` (and optional `chewie`)
- Material 3 theming (`useMaterial3: true`)

### Backend (Node + Express)
- Node.js 22+
- Express
- TypeScript
- `yt-dlp-exec` or typed wrapper for yt-dlp
- FFmpeg integration (`fluent-ffmpeg` acceptable)
- Validation: `zod` (recommended)
- Local static serving for clips with range support

## 5. Architecture Rules
### Layer dependency direction
- `presentation` depends on `domain`
- `data` depends on `domain`
- `domain` depends on nothing external

### Feature-first structure (both FE and BE)
```
features/
  video_processing/
    presentation/
    domain/
    data/
core/
```

### Backend structure target
```
src/
  core/
    config/
    errors/
    utils/
  features/
    video_processing/
      presentation/
        controllers/
        routes/
        dtos/
      domain/
        entities/
        repositories/
        usecases/
        value_objects/
      data/
        datasources/
        models/
        repositories/
  infrastructure/
    express/
  main.ts
```

### Frontend structure target
```
lib/
  core/
    di/
    failures/
    theme/
    utils/
  features/
    video_processing/
      presentation/
      domain/
      data/
  main.dart
```

## 6. Contracts and Schemas
### Required AI response shape (external AI -> app)
```json
{
  "videoTitle": "string",
  "language": "uk|uk_18|en|ru",
  "moments": [
    {
      "id": "string",
      "startSec": 123,
      "endSec": 165,
      "caption": "string",
      "postText": "string",
      "reason": "string"
    }
  ]
}
```

### Rules for moments
- `startSec >= 0`
- `endSec > startSec`
- `duration <= 120 sec`
- no overlapping moments in final accepted list
- min 3, max 10 moments

## 7. API Surface (MVP)
1. `POST /api/v1/videos/analyze`
   - input: YouTube URL + language
   - output: video metadata + transcript chunks + normalized language
2. `POST /api/v1/videos/process`
   - input: YouTube URL + validated AI JSON
   - output: processing job id
3. `GET /api/v1/videos/process/:jobId`
   - output: status, progress, errors, clip list when ready
4. `GET /media/clips/:fileName`
   - static/range-supported video serving

## 8. UI/UX Direction (Material Design 3)
- Material 3 only, responsive for mobile/tablet/desktop
- Keep UI clean and production-like; avoid decorative glass/neumorphism
- Required screens:
  1. Input & language selection
  2. Generated prompt + copy action
  3. JSON paste/validation
  4. Processing progress
  5. Results list with preview/download/copy-text

## 9. Implementation Phases for Agents
### Phase 0 - Project setup
- Create backend + frontend skeletons with feature-first clean architecture
- Configure strict TypeScript and linting
- Configure Material 3 theme baseline in Flutter

### Phase 1 - Backend core
- Implement analyze flow (metadata + captions)
- Implement process flow (download once + cut clips)
- Implement local storage layout and static media serving

### Phase 2 - Frontend core
- Implement Cubits and repositories for analyze/process flows
- Implement prompt builder + clipboard UX
- Implement JSON validation and error states

### Phase 3 - Integration
- Connect FE/BE via Dio
- Add progress polling and clip rendering
- Improve failure mapping and user feedback

## 10. Deliverables Per Phase
- Code changes in clean-architecture folders
- Brief architecture notes
- Run instructions
- Manual verification steps (no automated tests required in this stage)

## 11. Definition of Done
- Full local end-to-end flow works from URL input to downloadable clips
- JSON contract is validated and bad input fails gracefully
- Backend remains strongly typed and strict
- Flutter UI follows Material 3 and is responsive
- Code is organized by feature with clear 3-layer separation
