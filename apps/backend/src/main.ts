import path from 'path';
import { createApp } from './infrastructure/express/app.js';
import { config } from './core/config/env.js';

const storagePath = path.resolve(config.storagePath);

createApp(storagePath)
  .then((app) => {
    app.listen(config.port, () => {
      console.log(`[Server] Running on http://localhost:${config.port}`);
      console.log(`[Server] Storage path: ${storagePath}`);
    });
  })
  .catch((err: unknown) => {
    console.error('[Server] Failed to start:', err);
    process.exit(1);
  });
