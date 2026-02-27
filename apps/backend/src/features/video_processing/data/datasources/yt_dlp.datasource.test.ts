import { describe, it, expect, vi, beforeEach } from 'vitest';
import ytDlp from 'yt-dlp-exec';
import { YtDlpDataSource, YtDlpMetadata } from './yt_dlp.datasource';

vi.mock('yt-dlp-exec');

describe('YtDlpDataSource', () => {
    const storagePath = '/tmp/storage';
    let dataSource: YtDlpDataSource;

    beforeEach(() => {
        vi.clearAllMocks();
        dataSource = new YtDlpDataSource(storagePath);
    });

    describe('checkDependencies', () => {
        it('should pass if yt-dlp is available', async () => {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            vi.mocked(ytDlp).mockResolvedValueOnce('2024.01.01' as any);
            await expect(dataSource.checkDependencies()).resolves.toBeUndefined();
        });

        it('should throw AppError if yt-dlp is missing', async () => {
            vi.mocked(ytDlp).mockRejectedValueOnce(new Error('command not found'));
            await expect(dataSource.checkDependencies()).rejects.toThrow('yt-dlp is required');
        });
    });

    describe('getMetadata', () => {
        it('should fetch video metadata', async () => {
            const mockInfo: YtDlpMetadata = {
                id: '123',
                title: 'Test Video',
                duration: 100,
                webpage_url: 'https://youtube.com/watch?v=123',
            };
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            vi.mocked(ytDlp).mockResolvedValueOnce(mockInfo as any);

            const result = await dataSource.getMetadata('https://youtube.com/watch?v=123');

            expect(result).toEqual({
                videoId: '123',
                title: 'Test Video',
                durationSec: 100,
                sourceUrl: 'https://youtube.com/watch?v=123',
            });
        });
    });
});
