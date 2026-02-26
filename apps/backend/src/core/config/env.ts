export const config = {
  port: parseInt(process.env['PORT'] ?? '3000', 10),
  storagePath: process.env['STORAGE_PATH'] ?? './storage',
  corsOrigin: process.env['CORS_ORIGIN'] ?? '*',
} as const;
