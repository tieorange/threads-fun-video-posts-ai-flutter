import '../../domain/entities/analyze_result.dart';
import '../../domain/entities/transcript_segment.dart';
import '../../domain/entities/video_metadata.dart';

class AnalyzeResponseDto {
  const AnalyzeResponseDto({
    required this.video,
    required this.transcript,
    required this.language,
  });

  final VideoDto video;
  final List<TranscriptDto> transcript;
  final String language;

  factory AnalyzeResponseDto.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponseDto(
      video: VideoDto.fromJson(json['video'] as Map<String, dynamic>),
      transcript: (json['transcript'] as List<dynamic>)
          .map((e) => TranscriptDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      language: json['language'] as String,
    );
  }

  AnalyzeResult toDomain() => AnalyzeResult(
        video: video.toDomain(),
        transcript: transcript.map((t) => t.toDomain()).toList(),
        language: language,
      );
}

class VideoDto {
  const VideoDto({
    required this.videoId,
    required this.title,
    required this.durationSec,
    required this.sourceUrl,
  });

  final String videoId;
  final String title;
  final double durationSec;
  final String sourceUrl;

  factory VideoDto.fromJson(Map<String, dynamic> json) => VideoDto(
        videoId: json['videoId'] as String,
        title: json['title'] as String,
        durationSec: (json['durationSec'] as num).toDouble(),
        sourceUrl: json['sourceUrl'] as String,
      );

  VideoMetadata toDomain() => VideoMetadata(
        videoId: videoId,
        title: title,
        durationSec: durationSec,
        sourceUrl: sourceUrl,
      );
}

class TranscriptDto {
  const TranscriptDto({
    required this.startSec,
    required this.endSec,
    required this.text,
  });

  final double startSec;
  final double endSec;
  final String text;

  factory TranscriptDto.fromJson(Map<String, dynamic> json) => TranscriptDto(
        startSec: (json['startSec'] as num).toDouble(),
        endSec: (json['endSec'] as num).toDouble(),
        text: json['text'] as String,
      );

  TranscriptSegment toDomain() =>
      TranscriptSegment(startSec: startSec, endSec: endSec, text: text);
}
