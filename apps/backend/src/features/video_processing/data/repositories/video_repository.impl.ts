import { Language } from '../../domain/entities/ai_moments_payload';
import { TranscriptSegment } from '../../domain/entities/transcript_segment';
import { VideoMetadata } from '../../domain/entities/video_metadata';
import { IVideoRepository } from '../../domain/repositories/video_repository.interface';
import { YtDlpDataSource } from '../datasources/yt_dlp.datasource';

export class VideoRepositoryImpl implements IVideoRepository {
  constructor(private readonly ytDlp: YtDlpDataSource) {}

  getMetadata(url: string): Promise<VideoMetadata> {
    return this.ytDlp.getMetadata(url);
  }

  getCaptions(url: string, language: Language): Promise<TranscriptSegment[]> {
    return this.ytDlp.getCaptions(url, language);
  }

  downloadVideo(url: string, videoId: string): Promise<string> {
    return this.ytDlp.downloadVideo(url, videoId);
  }
}
