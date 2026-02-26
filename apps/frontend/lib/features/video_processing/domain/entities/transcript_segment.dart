class TranscriptSegment {
  const TranscriptSegment({
    required this.startSec,
    required this.endSec,
    required this.text,
  });

  final double startSec;
  final double endSec;
  final String text;
}
