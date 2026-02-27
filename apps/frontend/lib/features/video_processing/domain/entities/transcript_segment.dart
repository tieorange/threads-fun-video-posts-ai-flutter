class TranscriptSegment {
  const TranscriptSegment({required this.startSec, required this.endSec, required this.text});

  final double startSec;
  final double endSec;
  final String text;
  Map<String, dynamic> toJson() => {'startSec': startSec, 'endSec': endSec, 'text': text};

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) => TranscriptSegment(
    startSec: (json['startSec'] as num).toDouble(),
    endSec: (json['endSec'] as num).toDouble(),
    text: json['text'] as String,
  );
}
