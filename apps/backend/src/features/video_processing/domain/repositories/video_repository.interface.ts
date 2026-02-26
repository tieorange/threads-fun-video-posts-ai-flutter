import { Language } from '../entities/ai_moments_payload.js';
import { TranscriptSegment } from '../entities/transcript_segment.js';
import { VideoMetadata } from '../entities/video_metadata.js';

export interface IVideoRepository {
  getMetadata(url: string): Promise<VideoMetadata>;
  getCaptions(url: string, language: Language): Promise<TranscriptSegment[]>;
  downloadVideo(url: string, videoId: string): Promise<string>;
}
