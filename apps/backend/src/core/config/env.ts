export const config = {
  port: parseInt(process.env['PORT'] ?? '3000', 10),
  storagePath: process.env['STORAGE_PATH'] ?? './storage',
  corsOrigin: process.env['CORS_ORIGIN'] ?? '*',
  processDownloadTimeoutMs: parseInt(process.env['PROCESS_DOWNLOAD_TIMEOUT_MS'] ?? '900000', 10),
  processClipCutTimeoutMs: parseInt(process.env['PROCESS_CLIP_CUT_TIMEOUT_MS'] ?? '180000', 10),
} as const;
