import '../../domain/entities/clip_artifact.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/entities/job_status.dart';

class JobStatusDto {
  const JobStatusDto({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.clips,
    this.error,
  });

  final String jobId;
  final String status;
  final int progress;
  final List<ClipArtifactDto> clips;
  final String? error;

  factory JobStatusDto.fromJson(Map<String, dynamic> json) => JobStatusDto(
        jobId: json['jobId'] as String,
        status: json['status'] as String,
        progress: (json['progress'] as num).toInt(),
        clips: (json['clips'] as List<dynamic>? ?? [])
            .map((e) => ClipArtifactDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        error: json['error'] as String?,
      );

  JobStatus toDomain(List<FunnyMoment> moments) => JobStatus(
        jobId: jobId,
        status: _parseStatus(status),
        progress: progress,
        clips: clips.map((c) => c.toDomain()).toList(),
        moments: moments,
        error: error,
      );

  static JobStatusType _parseStatus(String s) => switch (s) {
        'queued' => JobStatusType.queued,
        'running' => JobStatusType.running,
        'failed' => JobStatusType.failed,
        'done' => JobStatusType.done,
        _ => JobStatusType.queued,
      };
}

class ClipArtifactDto {
  const ClipArtifactDto({
    required this.momentId,
    required this.startSec,
    required this.endSec,
    required this.downloadUrl,
  });

  final String momentId;
  final double startSec;
  final double endSec;
  final String downloadUrl;

  factory ClipArtifactDto.fromJson(Map<String, dynamic> json) => ClipArtifactDto(
        momentId: json['momentId'] as String,
        startSec: (json['startSec'] as num).toDouble(),
        endSec: (json['endSec'] as num).toDouble(),
        downloadUrl: json['downloadUrl'] as String,
      );

  ClipArtifact toDomain() => ClipArtifact(
        momentId: momentId,
        startSec: startSec,
        endSec: endSec,
        downloadUrl: downloadUrl,
      );
}
