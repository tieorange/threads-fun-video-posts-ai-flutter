import { Language } from '../entities/ai_moments_payload';
import { TranscriptSegment } from '../entities/transcript_segment';
import { VideoMetadata } from '../entities/video_metadata';

export interface IVideoRepository {
  getMetadata(url: string): Promise<VideoMetadata>;
  getCaptions(url: string, language: Language): Promise<TranscriptSegment[]>;
  downloadVideo(url: string, videoId: string, onProgress?: (percent: number) => void): Promise<string>;
}
