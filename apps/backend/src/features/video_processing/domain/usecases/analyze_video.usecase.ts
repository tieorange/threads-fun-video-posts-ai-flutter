import { Language } from '../entities/ai_moments_payload';
import { TranscriptSegment } from '../entities/transcript_segment';
import { VideoMetadata } from '../entities/video_metadata';
import { IVideoRepository } from '../repositories/video_repository.interface';
import { logger } from '../../../../core/logging/logger';

export interface AnalyzeVideoResult {
  readonly video: VideoMetadata;
  readonly transcript: TranscriptSegment[];
  readonly language: Language;
}

export class AnalyzeVideoUseCase {
  constructor(private readonly videoRepository: IVideoRepository) {}

  async execute(url: string, language: Language): Promise<AnalyzeVideoResult> {
    const start = Date.now();
    logger.info('analyze_video_start', 'Fetching metadata and captions in parallel', {
      layer: 'domain',
      data: { url, language },
    });

    const [video, transcript] = await Promise.all([
      this.videoRepository.getMetadata(url),
      this.videoRepository.getCaptions(url, language),
    ]);

    logger.info('analyze_video_done', 'Metadata and captions fetched', {
      layer: 'domain',
      durationMs: Date.now() - start,
      data: { videoId: video.videoId, durationSec: video.durationSec, transcriptSegments: transcript.length },
    });

    return { video, transcript, language };
  }
}
