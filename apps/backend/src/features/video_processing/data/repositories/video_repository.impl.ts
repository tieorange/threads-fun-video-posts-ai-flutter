import { Language } from '../../domain/entities/ai_moments_payload';
import { TranscriptSegment } from '../../domain/entities/transcript_segment';
import { VideoMetadata } from '../../domain/entities/video_metadata';
import { IVideoRepository } from '../../domain/repositories/video_repository.interface';
import { YtDlpDataSource } from '../datasources/yt_dlp.datasource';
import { VideoCacheDataSource } from '../datasources/video_cache.datasource';

export class VideoRepositoryImpl implements IVideoRepository {
  constructor(
    private readonly ytDlp: YtDlpDataSource,
    private readonly videoCache: VideoCacheDataSource,
  ) { }

  getMetadata(url: string): Promise<VideoMetadata> {
    return this.ytDlp.getMetadata(url);
  }

  getCaptions(url: string, language: Language): Promise<TranscriptSegment[]> {
    return this.ytDlp.getCaptions(url, language);
  }

  downloadVideo(url: string, jobId: string, onProgress?: (percent: number) => void, signal?: AbortSignal): Promise<string> {
    return this.ytDlp.downloadVideo(url, jobId, onProgress, signal);
  }

  getCachedVideoPath(videoId: string): Promise<string | null> {
    return this.videoCache.getCachedVideoPath(videoId);
  }

  linkToCache(jobId: string, videoId: string): Promise<void> {
    return this.videoCache.linkToCache(jobId, videoId);
  }

  symlinkFromCache(videoId: string, jobId: string): Promise<string> {
    return this.videoCache.symlinkFromCache(videoId, jobId);
  }
}
