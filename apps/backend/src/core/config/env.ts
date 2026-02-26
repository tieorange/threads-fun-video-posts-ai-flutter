import { z } from 'zod';

const envSchema = z.object({
  PORT: z.string().transform(Number).default('3000'),
  STORAGE_PATH: z.string().default('./storage'),
  CORS_ORIGIN: z.string().default('*'),
  PROCESS_DOWNLOAD_TIMEOUT_MS: z.string().transform(Number).default('900000'),
  PROCESS_CLIP_CUT_TIMEOUT_MS: z.string().transform(Number).default('180000'),
  PROCESS_TARGET_MAX_HEIGHT: z.string().transform(Number).default('720'),
  PROCESS_TARGET_FPS: z.string().transform(Number).default('30'),
  PROCESS_VIDEO_CRF: z.string().transform(Number).default('24'),
  PROCESS_VIDEO_PRESET: z.enum(['ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow']).default('veryfast'),
  PROCESS_CLIP_CONCURRENCY: z.string().transform(Number).default('2'),
  PROCESS_AUDIO_BITRATE: z.string().default('96k'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', JSON.stringify(parsed.error.format(), null, 2));
  process.exit(1);
}

const env = parsed.data;

export const config = {
  port: env.PORT,
  storagePath: env.STORAGE_PATH,
  corsOrigin: env.CORS_ORIGIN,
  processDownloadTimeoutMs: env.PROCESS_DOWNLOAD_TIMEOUT_MS,
  processClipCutTimeoutMs: env.PROCESS_CLIP_CUT_TIMEOUT_MS,
  processTargetMaxHeight: env.PROCESS_TARGET_MAX_HEIGHT,
  processTargetFps: env.PROCESS_TARGET_FPS,
  processVideoCrf: env.PROCESS_VIDEO_CRF,
  processVideoPreset: env.PROCESS_VIDEO_PRESET,
  processClipConcurrency: env.PROCESS_CLIP_CONCURRENCY,
  processAudioBitrate: env.PROCESS_AUDIO_BITRATE,
} as const;
