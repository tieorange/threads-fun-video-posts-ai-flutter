export type ErrorCode =
  | 'INVALID_URL'
  | 'INVALID_LANGUAGE'
  | 'INVALID_AI_PAYLOAD'
  | 'MOMENTS_OVERLAP'
  | 'MOMENTS_DURATION_EXCEEDED'
  | 'MOMENTS_COUNT_OUT_OF_RANGE'
  | 'TRANSCRIPT_FETCH_FAILED'
  | 'DOWNLOAD_FAILED'
  | 'DOWNLOAD_CANCELLED'
  | 'CLIP_CUT_FAILED'
  | 'CLIP_CUT_CANCELLED'
  | 'JOB_NOT_FOUND'
  | 'JOB_LOAD_FAILED'
  | 'DEPENDENCY_MISSING'
  | 'INTERNAL_ERROR';

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly httpStatus: number = 400,
    public readonly details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = 'AppError';
  }
}
