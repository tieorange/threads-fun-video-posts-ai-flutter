# Video Processing Optimization Plan

## Goal
- Make clip generation much faster by accepting lower output quality.
- Keep output quality "social-good" for iPhone viewers on Threads, Reddit, and Twitter/X.
- Preserve clean architecture (feature split by domain/data/presentation).

## Current Bottlenecks (from codebase)
- Download step pulls very heavy source format (`bestvideo + bestaudio`) and merges it:
  - `apps/backend/src/features/video_processing/data/datasources/yt_dlp.datasource.ts`
- Clip cutting re-encodes every clip with `libx264` but no speed/quality tuning (`preset`, `crf`, scaling, fps cap):
  - `apps/backend/src/features/video_processing/data/datasources/ffmpeg.datasource.ts`
- Clip processing is strictly sequential:
  - `apps/backend/src/features/video_processing/domain/usecases/process_video.usecase.ts`
- Same YouTube URL is downloaded again for each new job (no cross-job cache reuse).

## Target Output Profile (safe for iPhone social playback)
- Container: `mp4`
- Video codec: `H.264 (libx264)`, `yuv420p`, `+faststart`
- Audio codec: `AAC-LC`, stereo, `96k-128k`
- Resolution cap: long side max `1280` (720p class output)
- FPS cap: `30`
- Quality/speed: `-preset veryfast`, `-crf 24` (allow `23-26` range by config)

This profile is intentionally conservative for compatibility and much faster processing than current "best quality" flow.

## Phased Plan

## Phase 0 - Baseline Metrics (1 short PR)
- Add timing logs per stage to compare before/after:
  - download duration
  - average clip cut duration
  - total job duration
  - source resolution/fps and output resolution/fps
- Add a small benchmark doc with 3 sample videos (10 min, 30 min, 60 min).

Done criteria:
- We can report median total job time and p95 clip cut time before any optimization.

## Phase 1 - Biggest Win: Lighter Download + Fast Encode (1 PR)
- In `yt_dlp.datasource.ts`, switch to capped source format instead of `bestvideo+bestaudio`:
  - Prefer progressive mp4 with AVC/AAC when available.
  - Cap height at `720` (or `<=1080` fallback).
  - Avoid expensive "download huge + merge" when possible.
- In `ffmpeg.datasource.ts`, enforce fast social profile:
  - `-preset veryfast`
  - `-crf 24`
  - `-vf "scale='min(1280,iw)':-2,fps=30"`
  - `-pix_fmt yuv420p`
  - `-profile:v high -level 4.1`
  - `-c:a aac -b:a 96k -ac 2 -ar 48000`
  - keep `-movflags +faststart`

Expected impact:
- Usually the largest improvement (network + encode CPU), often 2x-4x faster end-to-end depending on source video.

## Phase 2 - Parallel Clip Cutting (1 PR)
- In `process_video.usecase.ts`, replace sequential loop with bounded concurrency (start with `2`, configurable).
- Keep deterministic progress updates (based on completed clips count).
- Add guardrails:
  - lower concurrency on low-core machines
  - fail fast if one clip fails, then stop remaining tasks cleanly

Expected impact:
- Additional 1.5x-2.5x speedup on multi-core machines.

## Phase 3 - Reuse Downloaded Video Across Jobs (1 PR)
- Cache by normalized YouTube video ID + quality profile instead of per `jobId`.
- If already present, skip download immediately.
- Add TTL or max-cache-size cleanup strategy.

Expected impact:
- Repeat runs on same video become much faster (download stage near zero).

## Phase 4 - Optional Advanced Speedups (after baseline wins)
- Optional hardware acceleration profile (if host ffmpeg supports it), behind feature flag.
- Optional "single ffmpeg process for multiple clips" strategy (advanced, more complex error handling).

Only implement if Phase 1-3 are not enough.

## Clean Architecture Changes (by layer)
- `data`:
  - Update `yt_dlp.datasource.ts` format strategy.
  - Update `ffmpeg.datasource.ts` encode options.
  - Add optional cache datasource/helper for source reuse.
- `domain`:
  - Add processing options entity/config (quality profile, clip concurrency).
  - Update `process_video.usecase.ts` to run bounded-parallel clip tasks.
- `presentation`:
  - No API contract break required for MVP.
  - Optional future: expose "Fast / Balanced / High" profile in request DTO.

## Config Additions
- `PROCESS_TARGET_MAX_HEIGHT` (default `720`)
- `PROCESS_TARGET_FPS` (default `30`)
- `PROCESS_VIDEO_CRF` (default `24`)
- `PROCESS_VIDEO_PRESET` (default `veryfast`)
- `PROCESS_CLIP_CONCURRENCY` (default `2`)
- `PROCESS_AUDIO_BITRATE` (default `96k`)

These go into:
- `apps/backend/src/core/config/env.ts`

## Verification Checklist
- Playback check on iPhone Safari and in-app players for Threads/Reddit/Twitter uploads.
- Validate no regressions in:
  - clip timing accuracy (`startSec`, `endSec`)
  - audio/video sync
  - job status progression and error reporting
- Benchmark again with same 3 sample videos and compare to Phase 0 baseline.

## Suggested Implementation Order
1. Phase 0 metrics
2. Phase 1 format + ffmpeg profile
3. Phase 2 concurrency
4. Phase 3 caching
5. Phase 4 only if still needed

This order gives fastest time-to-impact with low risk.
