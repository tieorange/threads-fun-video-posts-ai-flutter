# Funny Threads AI

Turn a long YouTube video into short, shareable funny clips with ready-to-post social text — using a manual AI copy/paste workflow (no API key required).

## Prerequisites

- Node.js 22+
- npm
- Flutter 3.27+ with web support enabled (`flutter config --enable-web`)
- `yt-dlp` installed and on `$PATH` (`brew install yt-dlp` / `pip install yt-dlp`)
- `ffmpeg` installed and on `$PATH` (`brew install ffmpeg`)

---

## Running the Backend

```bash
cd apps/backend
npm install
npm run dev          # starts on http://localhost:3000
```

Environment variables (optional, `.env` or shell exports):

| Variable       | Default                  | Description              |
|----------------|--------------------------|--------------------------|
| `PORT`         | `3000`                   | HTTP port                |
| `STORAGE_PATH` | `./storage`              | Where videos/clips live  |
| `CORS_ORIGIN`  | `http://localhost:3001`  | Allowed Flutter web origin |

---

## Running the Frontend

```bash
cd apps/frontend
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:3000
```

For a different backend URL (e.g. LAN access):

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://192.168.1.x:3000
```

---

## User Workflow

1. **Analyze** — Paste a YouTube URL, pick a language, press Analyze.
2. **Copy Prompt** — Copy the generated AI prompt to clipboard.
3. **Paste into AI** — Open ChatGPT / Claude / Gemini, paste the prompt, get JSON back.
4. **Paste JSON** — Paste the AI response into the app and validate.
5. **Review Moments** — Watch YouTube previews for each moment in-app. Select the ones you want.
6. **Generate Posts** — Press "Generate Posts". The backend downloads the video once and cuts your selected clips.
7. **Results** — Preview each clip, copy post text, download the `.mp4` files.

---

## API Endpoints

| Method | Path                              | Description                     |
|--------|-----------------------------------|---------------------------------|
| POST   | `/api/v1/videos/analyze`          | Fetch metadata + transcript     |
| POST   | `/api/v1/videos/process`          | Start clip-cutting job          |
| GET    | `/api/v1/videos/process/:jobId`   | Poll job status + clip list     |
| GET    | `/media/clips/:fileName`          | Stream/download a clip          |
