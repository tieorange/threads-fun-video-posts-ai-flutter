import 'video_metadata.dart';
import 'transcript_segment.dart';

typedef Language = String; // 'uk' | 'uk_18' | 'en' | 'ru'

class AnalyzeResult {
  const AnalyzeResult({
    required this.video,
    required this.transcript,
    required this.language,
  });

  final VideoMetadata video;
  final List<TranscriptSegment> transcript;
  final Language language;
}
