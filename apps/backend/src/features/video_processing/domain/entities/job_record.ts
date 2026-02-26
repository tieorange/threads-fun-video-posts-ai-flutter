import { FunnyMoment } from './funny_moment.js';

export type JobStatus = 'queued' | 'running' | 'failed' | 'done';

export interface ClipArtifact {
  readonly momentId: string;
  readonly startSec: number;
  readonly endSec: number;
  readonly downloadUrl: string;
}

export interface JobRecord {
  readonly jobId: string;
  status: JobStatus;
  progress: number;
  readonly youtubeUrl: string;
  readonly moments: FunnyMoment[];
  clips: ClipArtifact[];
  error: string | null;
  readonly createdAt: string;
  updatedAt: string;
}
