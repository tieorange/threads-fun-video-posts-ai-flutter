import { Router } from 'express';
import { AnalyzeController } from '../controllers/analyze.controller.js';
import { ProcessController } from '../controllers/process.controller.js';
import { JobStatusController } from '../controllers/job_status.controller.js';

export function createVideoRouter(
  analyzeController: AnalyzeController,
  processController: ProcessController,
  jobStatusController: JobStatusController,
): Router {
  const router = Router();

  router.post('/analyze', analyzeController.handle);
  router.post('/process', processController.handle);
  router.get('/process/:jobId', jobStatusController.handle);

  return router;
}
