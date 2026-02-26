import { z } from 'zod';

const YOUTUBE_URL_REGEX = /^https?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w-]+/;
const MIN_MOMENTS = 3;
const MAX_MOMENTS = 10;

const FunnyMomentSchema = z.object({
  id: z.string().min(1),
  startSec: z.number().nonnegative(),
  endSec: z.number().positive(),
  caption: z.string().min(1),
  postText: z.string().min(1),
  reason: z.string().min(1),
});

const AiPayloadSchema = z.object({
  videoTitle: z.string().min(1),
  language: z.enum(['uk', 'uk_18', 'en', 'ru']),
  moments: z.array(FunnyMomentSchema).min(MIN_MOMENTS).max(MAX_MOMENTS),
});

export const ProcessRequestSchema = z.object({
  youtubeUrl: z
    .string()
    .min(1)
    .regex(YOUTUBE_URL_REGEX, 'Must be a valid YouTube URL'),
  aiPayload: AiPayloadSchema,
});

export type ProcessRequestDto = z.infer<typeof ProcessRequestSchema>;
