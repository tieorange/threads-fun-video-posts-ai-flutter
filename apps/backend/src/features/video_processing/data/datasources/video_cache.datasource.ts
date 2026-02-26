import fs from 'fs/promises';
import path from 'path';
import { logger } from '../../../../core/logging/logger';

export class VideoCacheDataSource {
    private readonly videosDir: string;

    constructor(storagePath: string) {
        this.videosDir = path.join(storagePath, 'videos');
    }

    async getCachedVideoPath(videoId: string): Promise<string | null> {
        const filePath = path.join(this.videosDir, `${videoId}.mp4`);
        try {
            await fs.access(filePath);
            logger.info('video_cache_hit', `Cache hit for video ${videoId}`, {
                layer: 'data',
                data: { videoId, filePath },
            });
            return filePath;
        } catch {
            logger.debug('video_cache_miss', `Cache miss for video ${videoId}`, {
                layer: 'data',
                data: { videoId },
            });
            return null;
        }
    }

    async linkToCache(jobId: string, videoId: string): Promise<void> {
        const jobVideoPath = path.join(this.videosDir, `${jobId}.mp4`);
        const cacheVideoPath = path.join(this.videosDir, `${videoId}.mp4`);

        try {
            // If the cache file doesn't exist yet, rename the job-specific file to the cache-specific file
            // Then symlink the job-specific file to the cache-specific file
            await fs.rename(jobVideoPath, cacheVideoPath);
            await fs.symlink(cacheVideoPath, jobVideoPath);

            logger.info('video_cache_linked', `Linked job video to cache`, {
                layer: 'data',
                data: { jobId, videoId, cacheVideoPath, jobVideoPath },
            });
        } catch (err: unknown) {
            logger.error('video_cache_link_failed', String(err), {
                layer: 'data',
                data: { jobId, videoId },
            });
        }
    }

    async symlinkFromCache(videoId: string, jobId: string): Promise<string> {
        const cacheVideoPath = path.join(this.videosDir, `${videoId}.mp4`);
        const jobVideoPath = path.join(this.videosDir, `${jobId}.mp4`);

        try {
            await fs.symlink(cacheVideoPath, jobVideoPath);
            logger.info('video_cache_restored', `Restored job video from cache`, {
                layer: 'data',
                data: { jobId, videoId, jobVideoPath },
            });
            return jobVideoPath;
        } catch (err: unknown) {
            logger.error('video_cache_restore_failed', String(err), {
                layer: 'data',
                data: { jobId, videoId },
            });
            throw err;
        }
    }
}
