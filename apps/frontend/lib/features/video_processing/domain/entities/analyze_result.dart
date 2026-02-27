import 'video_metadata.dart';
import 'transcript_segment.dart';

typedef Language = String; // 'uk' | 'uk_18' | 'en' | 'ru'

class AnalyzeResult {
  const AnalyzeResult({required this.video, required this.transcript, required this.language});

  final VideoMetadata video;
  final List<TranscriptSegment> transcript;
  final Language language;
  Map<String, dynamic> toJson() => {
    'video': video.toJson(),
    'transcript': transcript.map((t) => t.toJson()).toList(),
    'language': language,
  };

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) => AnalyzeResult(
    video: VideoMetadata.fromJson(json['video'] as Map<String, dynamic>),
    transcript: (json['transcript'] as List<dynamic>)
        .map((t) => TranscriptSegment.fromJson(t as Map<String, dynamic>))
        .toList(),
    language: json['language'] as String,
  );
}
