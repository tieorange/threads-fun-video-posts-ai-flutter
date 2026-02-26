import { FunnyMoment } from './funny_moment.js';

export type Language = 'uk' | 'uk_18' | 'en' | 'ru';

export interface AiMomentsPayload {
  readonly videoTitle: string;
  readonly language: Language;
  readonly moments: FunnyMoment[];
}
