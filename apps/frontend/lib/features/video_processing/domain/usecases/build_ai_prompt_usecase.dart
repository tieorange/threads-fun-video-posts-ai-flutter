import '../entities/analyze_result.dart';
import '../entities/transcript_segment.dart';

class BuildAiPromptUseCase {
  const BuildAiPromptUseCase();

  String call(AnalyzeResult result) {
    final lang = result.language;
    final video = result.video;
    final transcript = result.transcript;

    final langInstruction = _languageInstruction(lang);
    final transcriptText = _formatTranscript(transcript);

    return '''
You are a viral comedy content assistant. Your task is to analyze the following YouTube video transcript and identify ${{3}}-10 of the funniest, most shareable moments.

$langInstruction

## Video Info
Title: ${video.title}
Duration: ${_formatDuration(video.durationSec)}
URL: ${video.sourceUrl}

## Transcript (with timestamps in seconds)
$transcriptText

## Required JSON Output Schema
You MUST respond with ONLY valid JSON matching this exact schema — no markdown, no explanation:

{
  "videoTitle": "string",
  "language": "$lang",
  "moments": [
    {
      "id": "m1",
      "startSec": 123,
      "endSec": 165,
      "caption": "Short funny caption describing the moment",
      "postText": "Ready-to-post social media text (concise, platform-ready)",
      "reason": "Why this moment is funny or shareable"
    }
  ]
}

## Hard Constraints
- Return between 3 and 10 moments.
- Timestamps must be in seconds (numbers, not strings).
- endSec MUST be greater than startSec.
- Each clip duration (endSec - startSec) must NOT exceed 120 seconds.
- Moments must NOT overlap (no two moments share the same time range).
- postText should be concise and platform-ready (no hashtag spam).
''';
  }

  String _languageInstruction(String lang) {
    switch (lang) {
      case 'uk':
        return '## Language\nRespond with captions and postText in Ukrainian. Keep the tone funny and relatable.';
      case 'uk_18':
        return '## Language\nRespond with captions and postText in Ukrainian. Adult humor is allowed — be bold and irreverent.';
      case 'en':
        return '## Language\nRespond with captions and postText in English. Keep the tone funny and shareable.';
      case 'ru':
        return '## Language\nRespond with captions and postText in Russian. Keep the tone funny and relatable.';
      default:
        return '## Language\nRespond with captions and postText in English.';
    }
  }

  String _formatTranscript(List<TranscriptSegment> segments) {
    if (segments.isEmpty) return '(No transcript available — analyze the video content directly.)';
    return segments
        .map((s) => '[${s.startSec.toStringAsFixed(1)}s - ${s.endSec.toStringAsFixed(1)}s] ${s.text}')
        .join('\n');
  }

  String _formatDuration(double seconds) {
    final h = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60);
    final s = (seconds % 60).floor();
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }
}
