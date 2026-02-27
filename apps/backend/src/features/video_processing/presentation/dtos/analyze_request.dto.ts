import { z } from 'zod';

const YOUTUBE_URL_REGEX = /^https?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w-]{11}.*/;

export const AnalyzeRequestSchema = z.object({
  youtubeUrl: z
    .string()
    .min(1, 'youtubeUrl is required')
    .regex(YOUTUBE_URL_REGEX, 'Must be a valid YouTube URL (e.g. https://www.youtube.com/watch?v=...)'),
  language: z.enum(['uk', 'uk_18', 'en', 'ru']),
});

export type AnalyzeRequestDto = z.infer<typeof AnalyzeRequestSchema>;
