import 'clip_artifact.dart';
import 'funny_moment.dart';

enum JobStatusType { queued, running, failed, done }

class JobStatus {
  const JobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.clips,
    required this.moments,
    this.error,
  });

  final String jobId;
  final JobStatusType status;
  final int progress;
  final List<ClipArtifact> clips;
  final List<FunnyMoment> moments;
  final String? error;
}
