# 🤖 AI Agent Guide — Funny Threads AI

> **Compatible with**: AntiGravity IDE (auto-reads AGENTS.md) | Claude Code (see CLAUDE.md) | Gemini CLI (manual context)
> **Last Updated**: 2026-02-27
> **Project Status**: MVP Complete ✅

> **ℹ️ Tool Compatibility Details:**
> - **AntiGravity IDE**: Auto-reads AGENTS.md per [agents.md spec](https://agents.md) ✅
> - **Claude Code**: Auto-reads CLAUDE.md (create symlink or duplicate content) — see [CLAUDE.md](./CLAUDE.md)
> - **Gemini CLI**: Manual context inclusion required (paste AGENTS.md content)

---

## 🎯 Project Overview

| Field | Value |
|-------|-------|
| **Product Name** | Funny Threads AI (ThreadGen AI) |
| **Goal** | Local-first app that turns YouTube videos into short funny clips + social text |
| **Platforms** | Flutter Web (frontend) + Node.js/Express/TypeScript (backend) |
| **Key Philosophy** | No AI API integration — manual copy/paste workflow with your own ChatGPT/Claude/Gemini session |
| **Storage** | Local filesystem (no database for MVP) |

### The Magic Flow ✨
```
Paste YouTube URL → App builds AI prompt from transcript → Copy to ChatGPT/Claude/Gemini →
Paste JSON back → Preview moments as YouTube players → Select what you like → Download .mp4 clips
```

---

## 📁 Project Structure

```
.
├── apps/
│   ├── backend/              # Node.js 22+ · Express · TypeScript (strict)
│   │   ├── src/
│   │   │   ├── core/         # Config, errors, logging
│   │   │   ├── features/     # Feature-first clean architecture
│   │   │   │   └── video_processing/
│   │   │   │       ├── domain/      # Entities, repositories, use cases
│   │   │   │       ├── data/        # Datasources, DTOs, repository impl
│   │   │   │       └── presentation/# Controllers, DTOs, routes
│   │   │   ├── infrastructure/ # Express app setup
│   │   │   └── main.ts
│   │   ├── storage/          # captions/ videos/ clips/ jobs/
│   │   └── logs/
│   └── frontend/             # Flutter Web · Material 3
│       ├── lib/
│       │   ├── core/         # DI, failures, logging, theme, router
│       │   └── features/
│       │       └── video_processing/
│       │           ├── domain/       # Entities, repositories, use cases
│       │           ├── data/         # Datasources, DTOs, repository impl
│       │           └── presentation/ # Cubits, pages, widgets
│       └── i18n/            # Localization (en, uk, ru)
├── docs/
│   ├── architecture.md      # Full architecture reference
│   ├── plan.md              # Original project spec
│   ├── planImplementation.md # As-built implementation guide
│   ├── planUi.md            # UI design specs
│   ├── planVideo.md         # Video processing specs
│   └── planBug.md           # Bug tracking & fixes
└── scripts/                 # Helper scripts (iPhone LAN testing)
```

---

## 🏗️ Architecture Rules

### Clean Architecture 3-Layer Structure

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                     │
│  • Controllers / Cubits                                 │
│  • DTOs (Request/Response validation)                   │
│  • Routes                                               │
├─────────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                           │
│  • Entities (pure interfaces/objects)                   │
│  • Repository Interfaces                                │
│  • Use Cases (business logic)                           │
├─────────────────────────────────────────────────────────┤
│  DATA LAYER                                             │
│  • Datasources (yt-dlp, FFmpeg, API)                    │
│  • Repository Implementations                           │
│  • DTOs (fromJson/toDomain mapping)                     │
└─────────────────────────────────────────────────────────┘
```

### Layer Dependencies
```
Presentation → Domain ← Data
     ↑                       ↑
     └───────────→ uses ─────┘
```

### Key Principles
- 🔒 **Domain has NO external dependencies** — pure business logic only
- 🔄 **Dependencies point inward** — outer layers depend on inner layers
- 🎯 **Feature-first organization** — group by feature, not by type
- 📝 **Manual DTOs** — no codegen for main features (simpler, faster)

---

## 🛠️ Tech Stack

### Backend Stack
| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 22+ | Runtime |
| Express | ^4.19.2 | Web framework |
| TypeScript | ^5.5.0 (strict) | Type safety — **NO `any` ALLOWED** |
| yt-dlp-exec | ^1.0.2 | YouTube metadata & download |
| fluent-ffmpeg | ^2.1.3 | Video clip cutting |
| Zod | ^3.23.8 | Runtime validation |
| uuid | ^10.0.0 | Job ID generation |
| Vitest | ^4.0.18 | Testing framework |

**Key Files:**
- [`apps/backend/src/main.ts`](apps/backend/src/main.ts:1) — Entry point
- [`apps/backend/src/infrastructure/express/app.ts`](apps/backend/src/infrastructure/express/app.ts:1) — App setup & DI
- [`apps/backend/package.json`](apps/backend/package.json:1) — Full dependency list

### Frontend Stack
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.27+ | UI framework |
| Dart | ^3.9.2 | Language |
| flutter_bloc | ^9.1.1 | State management (Cubit pattern) |
| fpdart | ^1.1.0 | Functional programming (Either) |
| go_router | ^14.8.1 | Navigation |
| dio | ^5.7.0 | HTTP client |
| chewie | ^1.8.5 | Video player |
| get_it | ^8.0.3 | Dependency injection |
| slang | ^3.31.0 | Type-safe i18n |

**Key Files:**
- [`apps/frontend/lib/main.dart`](apps/frontend/lib/main.dart:1) — Entry point
- [`apps/frontend/lib/core/di/injection.dart`](apps/frontend/lib/core/di/injection.dart:1) — DI wiring
- [`apps/frontend/lib/core/utils/router.dart`](apps/frontend/lib/core/utils/router.dart:1) — Route definitions
- [`apps/frontend/pubspec.yaml`](apps/frontend/pubspec.yaml:1) — Dependencies

---

## 📝 Key Constraints (DO NOT VIOLATE)

### ⚠️ Hard Rules — Non-Negotiable

| # | Constraint | Rationale |
|---|------------|-----------|
| 1 | **No AI API integration** | Manual copy/paste workflow only. The app builds prompts, user brings their own AI session |
| 2 | **Strict TypeScript** — no `any` | Type safety is enforced by ESLint. Use `unknown` + type guards if needed |
| 3 | **Material Design 3 only** | No custom theming beyond `ColorScheme.fromSeed`. Light + dark themes required |
| 4 | **Clean architecture 3-layer** | Domain → Data → Presentation. No skipping layers |
| 5 | **Local filesystem storage** | No database for MVP. JSON files in `storage/` folders |
| 6 | **Manual DTOs for main features** | No `freezed`/`json_serializable` for core entities (simpler dev) |
| 7 | **Dart 3 sealed classes** | Use `sealed class` for states, not `equatable` |

### ⚡ Quality Gates
- ✅ All use cases have Either<Failure, Success> return types
- ✅ All API responses are validated with Zod (backend) or manual parsing (frontend)
- ✅ All errors map to typed Failure/AppError classes
- ✅ No business logic in presentation layer (Cubits/Controllers are thin)

---

## 🔄 User Flow (6 Screens)

```
┌────────────────────────────────────────────────────────────────────┐
│  1️⃣  AnalyzeInputPage                                              │
│      • Paste YouTube URL                                           │
│      • Select language (en/uk/uk_18/ru)                            │
│      • POST /api/v1/videos/analyze                                 │
│      → Gets metadata + transcript (no download yet)                │
├────────────────────────────────────────────────────────────────────┤
│  2️⃣  PromptBuilderPage                                             │
│      • View generated AI prompt with transcript                    │
│      • Copy to clipboard                                           │
│      → User pastes into ChatGPT/Claude/Gemini                      │
├────────────────────────────────────────────────────────────────────┤
│  3️⃣  AiJsonPastePage                                               │
│      • Paste AI JSON response                                      │
│      • Client-side validation (3-10 moments, no overlap, max 120s) │
│      → Validates and parses to domain entities                     │
├────────────────────────────────────────────────────────────────────┤
│  4️⃣  MomentsReviewPage                                             │
│      • YouTube iframes with timestamps (start/end)                 │
│      • Tap to select/deselect moments                              │
│      • "Generate N Posts" button                                   │
│      → POST /api/v1/videos/process with selected moments only      │
├────────────────────────────────────────────────────────────────────┤
│  5️⃣  ProcessingPage                                                │
│      • Poll job status every 2 seconds                             │
│      • LinearProgressIndicator                                     │
│      • Auto-transition to results on completion                    │
│      → GET /api/v1/videos/process/:jobId                           │
├────────────────────────────────────────────────────────────────────┤
│  6️⃣  ResultsPage                                                   │
│      • Chewie video player for each clip                           │
│      • Copy post text button                                       │
│      • Download .mp4 button                                        │
│      → GET /media/clips/:fileName                                  │
└────────────────────────────────────────────────────────────────────┘
```

### Key Design Decision: YouTube-First Review
**Video download is DEFERRED** until the user selects moments. This saves bandwidth and time — users review moments via YouTube iframes first, then only download what they want.

---

## 📡 API Endpoints

### Base URL
```
Development: http://localhost:3000
Production:  (set via API_BASE_URL env/dart-define)
```

### Endpoints

#### 1. Analyze Video
```http
POST /api/v1/videos/analyze
Content-Type: application/json

{
  "youtubeUrl": "https://youtube.com/watch?v=...",
  "language": "en"  // "en" | "uk" | "uk_18" | "ru"
}
```

**Response:**
```json
{
  "video": {
    "videoId": "abc123",
    "title": "Video Title",
    "durationSec": 3600,
    "sourceUrl": "https://..."
  },
  "transcript": [
    { "startSec": 0, "endSec": 3, "text": "..." }
  ],
  "language": "en"
}
```

**Implementation:** [`apps/backend/src/features/video_processing/presentation/controllers/analyze.controller.ts`](apps/backend/src/features/video_processing/presentation/controllers/analyze.controller.ts:1)

---

#### 2. Process Video
```http
POST /api/v1/videos/process
Content-Type: application/json

{
  "youtubeUrl": "https://youtube.com/watch?v=...",
  "aiPayload": {
    "moments": [
      {
        "startSec": 120,
        "endSec": 145,
        "socialPost": "Funny caption text"
      }
    ],
    "language": "en"
  }
}
```

**Response:**
```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "queued"
}
```

**Implementation:** [`apps/backend/src/features/video_processing/presentation/controllers/process.controller.ts`](apps/backend/src/features/video_processing/presentation/controllers/process.controller.ts:1)

---

#### 3. Get Job Status
```http
GET /api/v1/videos/process/:jobId
```

**Response:**
```json
{
  "jobId": "550e8400-...",
  "status": "running",  // "queued" | "running" | "failed" | "done"
  "progress": 45,
  "stage": "downloading",  // "metadata" | "downloading" | "transcript" | "cutting" | "complete"
  "clips": null  // or array of clip URLs when done
}
```

**Implementation:** [`apps/backend/src/features/video_processing/presentation/controllers/job_status.controller.ts`](apps/backend/src/features/video_processing/presentation/controllers/job_status.controller.ts:1)

---

#### 4. Download Clip (Static)
```http
GET /media/clips/:fileName
```

Serves `.mp4` files with `Accept-Ranges` header for streaming.

**Storage Location:** [`apps/backend/storage/clips/`](apps/backend/storage/clips/)

---

## 🔧 Common Tasks

### Adding a New Feature

1. **Backend:**
   ```
   src/features/video_processing/
   ├── domain/
   │   ├── entities/new_entity.ts
   │   ├── repositories/new_repo.interface.ts
   │   └── usecases/new_usecase.ts
   ├── data/
   │   └── repositories/new_repo.impl.ts
   └── presentation/
       ├── dtos/new_dto.ts
       └── controllers/new_controller.ts
   ```

2. **Frontend:**
   ```
   lib/features/video_processing/
   ├── domain/
   │   ├── entities/new_entity.dart
   │   ├── repositories/new_repo.dart
   │   └── usecases/new_usecase.dart
   ├── data/
   │   └── repositories/new_repo_impl.dart
   └── presentation/
       ├── cubits/new_cubit.dart
       └── pages/new_page.dart
   ```

3. **Wire in DI:** Update [`apps/frontend/lib/core/di/injection.dart`](apps/frontend/lib/core/di/injection.dart:1) and [`apps/backend/src/infrastructure/express/app.ts`](apps/backend/src/infrastructure/express/app.ts:1)

### Adding a New API Endpoint

```typescript
// 1. Create DTO in presentation/dtos/
export const NewRequestDto = z.object({ ... });

// 2. Create controller in presentation/controllers/
export class NewController { ... }

// 3. Add route in presentation/routes/video.routes.ts
router.post('/new', new NewController(...).handle);
```

### Adding a New Page (Flutter)

```dart
// 1. Create Cubit + State
class NewCubit extends Cubit<NewState> { ... }
sealed class NewState { ... }

// 2. Create Page
class NewPage extends StatelessWidget { ... }

// 3. Add route in core/utils/router.dart
goRoute('/new', NewPage()),

// 4. Wire in DI in core/di/injection.dart
sl.registerFactory(() => NewCubit(sl()));
```

### Running Tests

```bash
# Backend tests
cd apps/backend && npm test              # Run once
npm run test:watch                       # Watch mode
npm run test:coverage                    # With coverage

# Frontend tests  
cd apps/frontend && flutter test
```

---

## 🚨 Error Handling

### Backend — AppError

Located in: [`apps/backend/src/core/errors/app_error.ts`](apps/backend/src/core/errors/app_error.ts:1)

```typescript
export enum ErrorCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  VIDEO_NOT_FOUND = 'VIDEO_NOT_FOUND',
  TRANSCRIPT_UNAVAILABLE = 'TRANSCRIPT_UNAVAILABLE',
  DOWNLOAD_FAILED = 'DOWNLOAD_FAILED',
  PROCESSING_FAILED = 'PROCESSING_FAILED',
  JOB_NOT_FOUND = 'JOB_NOT_FOUND',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
}

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly details?: Record<string, unknown>
  ) { super(message); }
}
```

**Global Error Middleware:** [`apps/backend/src/core/errors/error_middleware.ts`](apps/backend/src/core/errors/error_middleware.ts:1)

All errors are serialized to:
```json
{
  "code": "VALIDATION_ERROR",
  "message": "...",
  "details": { ... }
}
```

### Frontend — Failure Sealed Class

Located in: [`apps/frontend/lib/core/failures/failure.dart`](apps/frontend/lib/core/failures/failure.dart:1)

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class ServerFailure extends Failure { ... }
class UnexpectedFailure extends Failure { ... }
```

All use cases return `Either<Failure, Success>` using `fpdart`.

---

## 📚 Documentation Reference

| Document | Purpose | Location |
|----------|---------|----------|
| **Architecture** | Full architecture reference, patterns, decisions | [`docs/architecture.md`](docs/architecture.md:1) |
| **Plan** | Original project specification | [`docs/plan.md`](docs/plan.md:1) |
| **Implementation Guide** | As-built guide with key files | [`docs/planImplementation.md`](docs/planImplementation.md:1) |
| **UI Specs** | Design specifications | [`docs/planUi.md`](docs/planUi.md:1) |
| **Video Processing** | Video/FFmpeg specs | [`docs/planVideo.md`](docs/planVideo.md:1) |
| **Bug Tracking** | Known issues and fixes | [`docs/planBug.md`](docs/planBug.md:1) |

---

## ✅ Code Quality Checklist

Before submitting any changes, verify:

### Backend
- [ ] **No `any` types** — TypeScript strict mode enforced
- [ ] **Proper error handling** — Use `AppError` with correct `ErrorCode`
- [ ] **Zod validation** — All request DTOs validated
- [ ] **Layer boundaries respected** — Domain has no external deps
- [ ] **Tests written** — Vitest coverage for use cases

### Frontend  
- [ ] **Material 3 design** — Use theme colors, no hardcoded values
- [ ] **Sealed state classes** — Dart 3 `sealed`, not `equatable`
- [ ] **Either returns** — All use cases return `Either<Failure, T>`
- [ ] **No business logic in UI** — Keep Cubits thin, use cases thick
- [ ] **i18n support** — Add strings to `.i18n.json` files

### Both
- [ ] **Manual DTOs** — No codegen for main features
- [ ] **Clean architecture** — 3-layer structure maintained
- [ ] **Proper logging** — Use structured logging (not console.log/print)

---

## 🎨 Design Principles

### Core Philosophy
| Principle | Implementation |
|-----------|----------------|
| 🏠 **Local-first workflow** | No cloud dependencies, runs entirely on user's machine |
| 📺 **YouTube-first review** | Embedded iframes with timestamps BEFORE any download |
| 🤖 **No external AI dependencies** | User brings their own AI tool via copy/paste |
| 📱 **Responsive web app** | Material 3, works on mobile/tablet/desktop |
| 🔄 **Deferred processing** | Download only after user selects moments |

### Job Execution Model
- In-process async queue (single worker)
- Job state persisted to `storage/jobs/<jobId>.json`
- Progress: 0% → 10% (metadata) → 30% (download) → 50% (transcript) → 95% (clip loop) → 100%
- Automatic cleanup of stale resources (1hr interval)

---

## 🏃 Quick Start

### Prerequisites
| Tool | Version | Install |
|------|---------|---------|
| Node.js | 22+ | [nodejs.org](https://nodejs.org) |
| Flutter | 3.27+ | [flutter.dev](https://flutter.dev) |
| yt-dlp | latest | `brew install yt-dlp` or `pip install yt-dlp` |
| FFmpeg | any | `brew install ffmpeg` or `apt install ffmpeg` |

Enable Flutter web:
```bash
flutter config --enable-web
```

### 1. Start Backend
```bash
cd apps/backend
npm install
npm run dev
# ✅ Running on http://localhost:3000
```

### 2. Start Frontend (new terminal)
```bash
cd apps/frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

### One-Liner (both)
```bash
# Terminal 1
cd apps/backend && npm install && npm run dev

# Terminal 2  
cd apps/frontend && flutter pub get && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

---

## 🐛 Debugging Tips

### Backend Debugging

**Structured Logs:**
```bash
# View recent logs
cd apps/backend && npm run logs:recent

# View AI-related logs only
cd apps/backend && npm run logs:ai

# Raw log file
tail -f apps/backend/logs/app.jsonl | jq
```

**Log Format (JSON Lines):**
```json
{"timestamp":"2026-02-27T10:00:00.000Z","level":"info","event":"analyze_completed","message":"Video analyzed successfully","layer":"domain","feature":"video_processing","data":{"videoId":"abc123"}}
```

**Key Log Events to Watch:**
- `analyze_started` / `analyze_completed` / `analyze_failed`
- `process_job_started` / `process_job_progress` / `process_job_completed`
- `video_download_started` / `video_download_completed`
- `clip_cut_started` / `clip_cut_completed`

### Frontend Debugging

**Flutter DevTools:**
```bash
flutter pub global activate devtools
dart devtools
```

**BlocObserver Logging:**
All Cubit state changes are automatically logged. Check browser console for:
```
cubit_state_change: AnalyzeCubit: AnalyzeInitial → AnalyzeLoading
cubit_state_change: AnalyzeCubit: AnalyzeLoading → AnalyzeSuccess
```

**Network Tab:**
- All API calls logged via Dio interceptor
- Check Request/Response headers for debugging

**Common Issues:**
| Issue | Solution |
|-------|----------|
| CORS errors | Ensure backend CORS_ORIGIN includes frontend URL |
| Video not playing | Check `/media/clips/` endpoint returns correct MIME type |
| Job stuck at 0% | Check yt-dlp is installed and on PATH |
| FFmpeg errors | Verify FFmpeg is installed: `ffmpeg -version` |

### Environment Variables

**Backend** (`.env` or env vars):
```
PORT=3000
STORAGE_PATH=./storage
CORS_ORIGIN=http://localhost:8080
```

**Frontend** (dart-define):
```
--dart-define=API_BASE_URL=http://localhost:3000
```

---

## 🧪 Testing Checklist

### Manual Verification Flow
1. ✅ Backend starts on port 3000 without errors
2. ✅ `POST /api/v1/videos/analyze` returns metadata + transcript
3. ✅ Generated prompt contains transcript and JSON schema
4. ✅ Paste valid AI JSON → advances to MomentsReviewPage
5. ✅ YouTube iframes load with correct start/end timestamps
6. ✅ Select subset of moments → "Generate Posts"
7. ✅ ProcessingPage shows progress increments
8. ✅ Auto-transition to ResultsPage at 100%
9. ✅ Each clip previews with Chewie player
10. ✅ Download button returns valid .mp4
11. ✅ Copy-post-text copies correct text
12. ✅ Invalid JSON shows clear error message

---

## 📞 Support & Resources

**Project Repository Structure:**
- Monorepo root: `/Users/anduser/AndroidStudioProjects/threads-fun-video-posts-ai-flutter`
- Backend: `apps/backend/`
- Frontend: `apps/frontend/`
- Docs: `docs/`

**Key Commands:**
```bash
# Backend
npm run dev              # Development
npm run build            # Production build
npm run test             # Run tests
npm run lint             # ESLint check

# Frontend
flutter pub get          # Install deps
flutter run -d chrome    # Run on Chrome
flutter build web        # Production build
flutter test             # Run tests
```

---

> 🤖 **For AI Agents**: When making changes, always follow the clean architecture 3-layer structure. Keep domain logic pure, use proper error types, and maintain the local-first philosophy. When in doubt, refer to existing use cases as templates.
