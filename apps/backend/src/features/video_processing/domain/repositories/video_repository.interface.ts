import { Language } from '../entities/ai_moments_payload';
import { TranscriptSegment } from '../entities/transcript_segment';
import { VideoMetadata } from '../entities/video_metadata';

export interface IVideoRepository {
  getMetadata(url: string): Promise<VideoMetadata>;
  getCaptions(url: string, language: Language): Promise<TranscriptSegment[]>;
  downloadVideo(url: string, jobId: string, onProgress?: (percent: number) => void, signal?: AbortSignal): Promise<string>;
  getCachedVideoPath(videoId: string): Promise<string | null>;
  linkToCache(jobId: string, videoId: string): Promise<void>;
  symlinkFromCache(videoId: string, jobId: string): Promise<string>;
}
