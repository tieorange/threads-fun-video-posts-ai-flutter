import { z } from 'zod';
import { AiMomentsPayload } from '../entities/ai_moments_payload';
import { AppError } from '../../../../core/errors/app_error';
import { logger } from '../../../../core/logging/logger';

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

const AiMomentsPayloadSchema = z.object({
  videoTitle: z.string().min(1),
  language: z.enum(['uk', 'uk_18', 'en', 'ru']),
  moments: z.array(FunnyMomentSchema).min(MIN_MOMENTS).max(MAX_MOMENTS),
});

const MAX_CLIP_DURATION_SEC = 120;

function summarizeRawPayload(raw: unknown): Record<string, unknown> {
  if (!raw || typeof raw !== 'object') {
    return { rawType: typeof raw };
  }

  const payload = raw as Record<string, unknown>;
  const moments = Array.isArray(payload['moments']) ? payload['moments'] : [];
  const invalidMomentShapeCount = moments.filter((moment) => {
    if (!moment || typeof moment !== 'object') return true;
    const m = moment as Record<string, unknown>;
    return typeof m['id'] !== 'string' || typeof m['startSec'] !== 'number' || typeof m['endSec'] !== 'number';
  }).length;

  return {
    hasVideoTitle: typeof payload['videoTitle'] === 'string' && payload['videoTitle'].length > 0,
    language: payload['language'],
    momentCount: moments.length,
    invalidMomentShapeCount,
    sampleMomentIds: moments
      .slice(0, 5)
      .map((moment) => (moment && typeof moment === 'object' ? (moment as Record<string, unknown>)['id'] : null)),
  };
}

export class ValidateAiPayloadUseCase {
  execute(raw: unknown): AiMomentsPayload {
    const parseResult = AiMomentsPayloadSchema.safeParse(raw);
    if (!parseResult.success) {
      logger.warn('validate_payload_schema_failed', 'AI payload schema validation failed', {
        layer: 'domain',
        data: {
          constraints: { minMoments: MIN_MOMENTS, maxMoments: MAX_MOMENTS, maxClipDurationSec: MAX_CLIP_DURATION_SEC },
          payloadSummary: summarizeRawPayload(raw),
          issues: parseResult.error.issues,
        },
      });
      throw new AppError(
        'INVALID_AI_PAYLOAD',
        'AI payload validation failed.',
        400,
        { issues: parseResult.error.issues },
      );
    }

    const payload = parseResult.data;
    logger.info('validate_payload_schema_ok', 'Schema valid, checking business rules', {
      layer: 'domain',
      data: { momentCount: payload.moments.length, videoTitle: payload.videoTitle },
    });

    for (const moment of payload.moments) {
      if (moment.endSec <= moment.startSec) {
        throw new AppError(
          'INVALID_AI_PAYLOAD',
          `Moment ${moment.id}: endSec must be greater than startSec.`,
          400,
        );
      }
      if (moment.endSec - moment.startSec > MAX_CLIP_DURATION_SEC) {
        throw new AppError(
          'MOMENTS_DURATION_EXCEEDED',
          `Moment ${moment.id} exceeds maximum duration of ${MAX_CLIP_DURATION_SEC}s.`,
          400,
        );
      }
    }

    const sorted = [...payload.moments].sort((a, b) => a.startSec - b.startSec);
    for (let i = 1; i < sorted.length; i++) {
      const prev = sorted[i - 1];
      const curr = sorted[i];
      if (prev !== undefined && curr !== undefined && curr.startSec < prev.endSec) {
        throw new AppError(
          'MOMENTS_OVERLAP',
          `Moments ${prev.id} and ${curr.id} overlap.`,
          400,
        );
      }
    }

    logger.info('validate_payload_ok', 'Payload fully validated', {
      layer: 'domain',
      data: { momentCount: payload.moments.length },
    });
    return payload as AiMomentsPayload;
  }
}
