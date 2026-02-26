# 🎬 Funny Threads AI

> Turn any long YouTube video into **3–10 short funny clips** with ready-to-post social text — no API key, no subscription, runs entirely on your machine.

The magic: paste a YouTube URL → the app builds an AI prompt from the transcript → you copy-paste it into ChatGPT/Claude/Gemini → paste the JSON back → preview moments as YouTube players → select what you like → download `.mp4` clips.

---

## ✨ Features

- 🔗 **Paste any YouTube URL** — up to ~1 hour long
- 🌍 **4 language profiles** — English, Ukrainian, Ukrainian 18+, Russian
- 🤖 **No AI API key** — you bring your own ChatGPT/Claude/Gemini session
- 📺 **YouTube preview first** — watch each moment in-app with timestamp iframes before downloading anything
- ✅ **Select only what you want** — deselect bad moments, keep the gems
- ✂️ **FFmpeg clip cutting** — lossless-quality `.mp4` files per moment
- 📋 **One-click post text copy** — caption ready for Threads, TikTok, Instagram
- 🌗 **Material 3 design** — light + dark theme, responsive for mobile/tablet/desktop

---

## 🧰 Prerequisites

| Tool | Version | Install |
|---|---|---|
| Node.js | 22+ | [nodejs.org](https://nodejs.org) |
| Flutter | 3.27+ | [flutter.dev](https://flutter.dev) |
| yt-dlp | latest | `brew install yt-dlp` · `pip install yt-dlp` |
| ffmpeg | any | `brew install ffmpeg` · `apt install ffmpeg` |

Enable Flutter web if not already done:
```bash
flutter config --enable-web
```

---

## 🚀 Running Locally

### 1. Start the backend

```bash
cd apps/backend
npm install
npm run dev
# ✅ Running on http://localhost:3000
```

### 2. Start the frontend

```bash
cd apps/frontend
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:3000
```

That's it. Both should be running in under a minute.

---

## 🗺️ How It Works

```
┌─────────────────────────────────────────────────────────┐
│  1. Paste YouTube URL + pick language → Analyze          │
│     → backend fetches metadata + transcript (no download)│
├─────────────────────────────────────────────────────────┤
│  2. Copy the generated AI prompt to clipboard            │
├─────────────────────────────────────────────────────────┤
│  3. Paste into ChatGPT / Claude / Gemini                 │
│     → get a JSON response with funny moments             │
├─────────────────────────────────────────────────────────┤
│  4. Paste the JSON back → app validates it               │
├─────────────────────────────────────────────────────────┤
│  5. Review moments with YouTube iframes (with timestamps)│
│     → tap to select / deselect                           │
├─────────────────────────────────────────────────────────┤
│  6. Press "Generate Posts"                               │
│     → backend downloads video ONCE, cuts your clips      │
├─────────────────────────────────────────────────────────┤
│  7. Preview → copy post text → download .mp4 🎉          │
└─────────────────────────────────────────────────────────┘
```

---

## 🏗️ Project Structure

```
.
├── apps/
│   ├── backend/       Node 22 · Express · TypeScript (strict, no any)
│   └── frontend/      Flutter Web · Material 3 · flutter_bloc
└── docs/
    ├── plan.md              Original project spec
    ├── planImplementation.md  As-built implementation guide
    └── architecture.md      Full architecture reference
```

### Backend — Clean Architecture
```
src/
  core/               errors, config, utils
  features/
    video_processing/
      domain/         entities · repository interfaces · use cases
      data/           yt-dlp datasource · ffmpeg datasource · local storage
      presentation/   controllers · routes · zod DTOs
  infrastructure/     Express app factory · DI wiring
```

### Frontend — Clean Architecture
```
lib/
  core/               DI (get_it) · failures · theme · router
  features/
    video_processing/
      domain/         entities · repository interfaces · use cases
      data/           Dio datasource · DTOs · repository impls
      presentation/   5 cubits · 6 pages
```

---

## 🌐 API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/videos/analyze` | Fetch metadata + transcript |
| `POST` | `/api/v1/videos/process` | Start async clip-cutting job |
| `GET` | `/api/v1/videos/process/:jobId` | Poll job status + progress |
| `GET` | `/media/clips/:fileName` | Stream or download a clip |

### Job Progress Stages
```
0%  → queued
10% → video info fetched
30% → full video downloaded
30–95% → clips being cut (increments per clip)
100% → done ✅
```

---

## ⚙️ Environment Variables (Backend)

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP port |
| `STORAGE_PATH` | `./storage` | Local storage for videos/clips/jobs |
| `CORS_ORIGIN` | `http://localhost:3001` | Allowed frontend origin |

---

## 🛡️ Validation Rules

The app enforces these rules at two checkpoints:

**Client-side** (JSON paste — enforces AI output quality):
- 3–10 moments
- `endSec > startSec`
- Max 120s per clip
- No overlapping moments

**Backend** (process endpoint — user's intentional selection):
- 1–10 moments (you can select just 1 if you want!)
- Same timestamp and duration rules

---

## 🔧 Tech Stack

### Backend
| Package | Purpose |
|---|---|
| `express` | HTTP server |
| `zod` | Runtime schema validation |
| `yt-dlp-exec` | YouTube metadata + captions + download |
| `fluent-ffmpeg` | Video clip cutting |
| `uuid` | Job ID generation |

### Frontend
| Package | Purpose |
|---|---|
| `flutter_bloc` | Cubit state management |
| `fpdart` | `Either<Failure, T>` error handling |
| `dio` | HTTP client |
| `go_router` | Declarative routing |
| `get_it` | Dependency injection |
| `video_player` + `chewie` | In-app clip preview |
| `url_launcher` | Open download URLs |
| `web` | YouTube iframe embedding |

---

## 📁 Generated Storage Layout

```
apps/backend/storage/
  videos/    downloaded full videos (reused per job)
  clips/     cut .mp4 clips → served at /media/clips/
  jobs/      JSON job state files
  captions/  temporary caption files
```

> 💡 Clean up `storage/videos/` and `storage/clips/` manually between sessions — no automatic cleanup in MVP.

---

## 📖 Docs

- [docs/architecture.md](docs/architecture.md) — Full architecture reference, API contracts, design decisions
- [docs/planImplementation.md](docs/planImplementation.md) — As-built implementation guide + verification checklist
- [docs/plan.md](docs/plan.md) — Original project specification
