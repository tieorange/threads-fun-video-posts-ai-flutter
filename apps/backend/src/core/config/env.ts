export const config = {
  port: parseInt(process.env['PORT'] ?? '3000', 10),
  storagePath: process.env['STORAGE_PATH'] ?? './storage',
  corsOrigin: process.env['CORS_ORIGIN'] ?? '*',
  processDownloadTimeoutMs: parseInt(process.env['PROCESS_DOWNLOAD_TIMEOUT_MS'] ?? '900000', 10),
  processClipCutTimeoutMs: parseInt(process.env['PROCESS_CLIP_CUT_TIMEOUT_MS'] ?? '180000', 10),
  processTargetMaxHeight: parseInt(process.env['PROCESS_TARGET_MAX_HEIGHT'] ?? '720', 10),
  processTargetFps: parseInt(process.env['PROCESS_TARGET_FPS'] ?? '30', 10),
  processVideoCrf: parseInt(process.env['PROCESS_VIDEO_CRF'] ?? '24', 10),
  processVideoPreset: process.env['PROCESS_VIDEO_PRESET'] ?? 'veryfast',
  processClipConcurrency: parseInt(process.env['PROCESS_CLIP_CONCURRENCY'] ?? '2', 10),
  processAudioBitrate: process.env['PROCESS_AUDIO_BITRATE'] ?? '96k',
} as const;
