import { describe, it, expect, vi, beforeEach } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { LocalStorageDataSource } from './local_storage.datasource';
import { JobRecord } from '../../domain/entities/job_record';

vi.mock('fs/promises');

describe('LocalStorageDataSource', () => {
    const storagePath = '/tmp/storage';
    let dataSource: LocalStorageDataSource;

    beforeEach(() => {
        vi.clearAllMocks();
        dataSource = new LocalStorageDataSource(storagePath);
    });

    describe('saveJob', () => {
        it('should save a job atomically', async () => {
            const job: JobRecord = {
                jobId: 'job_123',
                status: 'queued',
                progress: 0,
                youtubeUrl: 'https://youtube.com/watch?v=123',
                moments: [],
                clips: [],
                error: null,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
            };

            await dataSource.saveJob(job);

            expect(fs.writeFile).toHaveBeenCalledWith(
                expect.stringContaining('job_123.json.tmp-'),
                JSON.stringify(job, null, 2),
                'utf-8'
            );
            expect(fs.rename).toHaveBeenCalledWith(
                expect.stringContaining('job_123.json.tmp-'),
                path.join(storagePath, 'jobs', 'job_123.json')
            );
        });
    });

    describe('loadJob', () => {
        it('should load a job from disk', async () => {
            const job: JobRecord = {
                jobId: 'job_123',
                status: 'done',
                progress: 100,
                youtubeUrl: 'https://youtube.com/watch?v=123',
                moments: [],
                clips: [],
                error: null,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
            };

            vi.mocked(fs.readFile).mockResolvedValueOnce(JSON.stringify(job));

            const result = await dataSource.loadJob('job_123');

            expect(result).toEqual(job);
            expect(fs.readFile).toHaveBeenCalledWith(
                path.join(storagePath, 'jobs', 'job_123.json'),
                'utf-8'
            );
        });

        it('should return null if job file does not exist', async () => {
            const error = new Error('File not found') as NodeJS.ErrnoException;
            error.code = 'ENOENT';
            vi.mocked(fs.readFile).mockRejectedValueOnce(error);

            const result = await dataSource.loadJob('job_nonexistent');

            expect(result).toBeNull();
        });
    });

    describe('ensureDirectories', () => {
        it('should create all required directories', async () => {
            await dataSource.ensureDirectories();

            expect(fs.mkdir).toHaveBeenCalledTimes(4);
            expect(fs.mkdir).toHaveBeenCalledWith(expect.stringContaining('/jobs'), { recursive: true });
            expect(fs.mkdir).toHaveBeenCalledWith(expect.stringContaining('/videos'), { recursive: true });
            expect(fs.mkdir).toHaveBeenCalledWith(expect.stringContaining('/clips'), { recursive: true });
            expect(fs.mkdir).toHaveBeenCalledWith(expect.stringContaining('/captions'), { recursive: true });
        });
    });
});
