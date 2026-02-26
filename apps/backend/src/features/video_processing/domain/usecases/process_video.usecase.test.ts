import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ProcessVideoUseCase } from './process_video.usecase';
import { IVideoRepository } from '../repositories/video_repository.interface';
import { IJobRepository } from '../repositories/job_repository.interface';
import { IFfmpegDataSource } from '../../data/datasources/ffmpeg.datasource';

describe('ProcessVideoUseCase', () => {
    let useCase: ProcessVideoUseCase;
    let videoRepo: IVideoRepository;
    let jobRepo: IJobRepository;
    let ffmpegDs: IFfmpegDataSource;
    const clipsStoragePath = '/tmp/clips';

    beforeEach(() => {
        videoRepo = {
            getMetadata: vi.fn(),
            downloadVideo: vi.fn(),
            getCachedVideoPath: vi.fn(),
            symlinkFromCache: vi.fn(),
            linkToCache: vi.fn(),
        };
        jobRepo = {
            save: vi.fn(),
            update: vi.fn(),
            load: vi.fn(),
            loadAll: vi.fn(),
            delete: vi.fn(),
        };
        ffmpegDs = {
            cutClip: vi.fn(),
            checkDependencies: vi.fn(),
        } as any;

        useCase = new ProcessVideoUseCase(videoRepo, jobRepo, ffmpegDs, clipsStoragePath);
    });

    it('should create a job and return jobId', async () => {
        const youtubeUrl = 'https://youtube.com/watch?v=123';
        const payload = { moments: [] };

        const result = await useCase.execute(youtubeUrl, payload as any);

        expect(result).toMatch(/^job_\d+_[a-z0-9]+$/);
        expect(jobRepo.save).toHaveBeenCalled();
    });
});
