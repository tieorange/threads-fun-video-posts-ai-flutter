import express, { Application } from 'express';
import cors from 'cors';
import path from 'path';
import { config } from '../../core/config/env';
import { errorMiddleware } from '../../core/errors/error_middleware';
import { requestContextMiddleware } from './request_context.middleware';
import { createVideoRouter } from '../../features/video_processing/presentation/routes/video.routes';
import { AnalyzeController } from '../../features/video_processing/presentation/controllers/analyze.controller';
import { ProcessController } from '../../features/video_processing/presentation/controllers/process.controller';
import { JobStatusController } from '../../features/video_processing/presentation/controllers/job_status.controller';
import { AnalyzeVideoUseCase } from '../../features/video_processing/domain/usecases/analyze_video.usecase';
import { ValidateAiPayloadUseCase } from '../../features/video_processing/domain/usecases/validate_ai_payload.usecase';
import { ProcessVideoUseCase } from '../../features/video_processing/domain/usecases/process_video.usecase';
import { GetProcessStatusUseCase } from '../../features/video_processing/domain/usecases/get_process_status.usecase';
import { VideoRepositoryImpl } from '../../features/video_processing/data/repositories/video_repository.impl';
import { JobRepositoryImpl } from '../../features/video_processing/data/repositories/job_repository.impl';
import { YtDlpDataSource } from '../../features/video_processing/data/datasources/yt_dlp.datasource';
import { FfmpegDataSource } from '../../features/video_processing/data/datasources/ffmpeg.datasource';
import { LocalStorageDataSource } from '../../features/video_processing/data/datasources/local_storage.datasource';

export async function createApp(storagePath: string): Promise<Application> {
  const app = express();

  // Middleware
  app.use(cors({ origin: config.corsOrigin }));
  app.use(express.json({ limit: '5mb' }));
  app.use(requestContextMiddleware);

  // Static media serving with Range support
  app.use('/media/clips', (req, res, next) => {
    if (req.query.download === '1') {
      res.setHeader('Content-Disposition', 'attachment');
    }
    next();
  });
  app.use('/media/clips', express.static(path.join(storagePath, 'clips'), {
    acceptRanges: true,
    setHeaders: (res) => {
      res.setHeader('Accept-Ranges', 'bytes');
    },
  }));

  // DI wiring
  const localStorage = new LocalStorageDataSource(storagePath);
  await localStorage.ensureDirectories();

  const ytDlpDs = new YtDlpDataSource(storagePath);
  const ffmpegDs = new FfmpegDataSource();

  const videoRepo = new VideoRepositoryImpl(ytDlpDs);
  const jobRepo = new JobRepositoryImpl(localStorage);

  const analyzeUseCase = new AnalyzeVideoUseCase(videoRepo);
  const validateUseCase = new ValidateAiPayloadUseCase();
  const processUseCase = new ProcessVideoUseCase(
    videoRepo,
    jobRepo,
    ffmpegDs,
    path.join(storagePath, 'clips'),
  );
  const getStatusUseCase = new GetProcessStatusUseCase(jobRepo);

  const analyzeController = new AnalyzeController(analyzeUseCase);
  const processController = new ProcessController(validateUseCase, processUseCase);
  const jobStatusController = new JobStatusController(getStatusUseCase);

  const videoRouter = createVideoRouter(analyzeController, processController, jobStatusController);
  app.use('/api/v1/videos', videoRouter);

  // Error middleware (must be last)
  app.use(errorMiddleware);

  return app;
}
