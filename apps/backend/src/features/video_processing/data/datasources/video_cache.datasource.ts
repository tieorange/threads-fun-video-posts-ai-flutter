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
            // Check if job video exists before trying to move it
            try {
                await fs.access(jobVideoPath);
            } catch {
                logger.warn('video_cache_link_skipped_no_source', 'Job video not found, skipping cache link', {
                    layer: 'data',
                    data: { jobId, videoId, jobVideoPath },
                });
                return;
            }

            // If the cache file already exists, just remove the job file (it's redundant)
            try {
                await fs.access(cacheVideoPath);
                logger.info('video_cache_link_skipped_exists', 'Cache already exists, removing job-specific file', {
                    layer: 'data',
                    data: { jobId, videoId, cacheVideoPath },
                });
                await fs.unlink(jobVideoPath);
            } catch {
                // Cache doesn't exist, so rename the job file to cache
                await fs.rename(jobVideoPath, cacheVideoPath);
            }

            // Always ensure the job-specific path is a symlink to the cache
            // This ensures consistent behavior for the rest of the pipeline
            try {
                await fs.symlink(cacheVideoPath, jobVideoPath);
            } catch (symError: unknown) {
                // If symlink already exists, it's fine
                if (symError instanceof Error && (symError as { code?: string }).code !== 'EEXIST') throw symError;
            }

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
            await fs.access(cacheVideoPath);

            try {
                await fs.symlink(cacheVideoPath, jobVideoPath);
            } catch (symError: unknown) {
                if (symError instanceof Error && (symError as { code?: string }).code !== 'EEXIST') throw symError;
                // If it exists, verify it points to the right place or replace it
                await fs.unlink(jobVideoPath);
                await fs.symlink(cacheVideoPath, jobVideoPath);
            }
            logger.info('video_cache_restored', `Restored job video from cache`, {
                layer: 'data',
                data: { jobId, videoId, jobVideoPath },
            });
            return jobVideoPath;
        } catch (err: unknown) {
            logger.error('video_cache_restore_failed', String(err), {
                layer: 'data',
                data: { jobId, videoId, jobVideoPath },
            });
            throw err;
        }
    }
}
