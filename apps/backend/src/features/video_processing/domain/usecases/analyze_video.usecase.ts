import { Language } from '../entities/ai_moments_payload.js';
import { TranscriptSegment } from '../entities/transcript_segment.js';
import { VideoMetadata } from '../entities/video_metadata.js';
import { IVideoRepository } from '../repositories/video_repository.interface.js';

export interface AnalyzeVideoResult {
  readonly video: VideoMetadata;
  readonly transcript: TranscriptSegment[];
  readonly language: Language;
}

export class AnalyzeVideoUseCase {
  constructor(private readonly videoRepository: IVideoRepository) {}

  async execute(url: string, language: Language): Promise<AnalyzeVideoResult> {
    const [video, transcript] = await Promise.all([
      this.videoRepository.getMetadata(url),
      this.videoRepository.getCaptions(url, language),
    ]);

    return { video, transcript, language };
  }
}
