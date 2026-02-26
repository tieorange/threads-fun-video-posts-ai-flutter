import '../entities/analyze_result.dart';
import '../entities/transcript_segment.dart';

class BuildAiPromptUseCase {
  const BuildAiPromptUseCase();

  String call(AnalyzeResult result) {
    final lang = result.language;
    final video = result.video;
    final transcript = result.transcript;
    final hasTranscript = transcript.isNotEmpty;

    final langInstruction = _languageInstruction(lang);
    final audienceInstruction = _audienceInstruction();
    final transcriptText = _formatTranscript(transcript);
    final availabilityInstruction = _availabilityInstruction(hasTranscript);
    final momentCountConstraint = hasTranscript
        ? '- Return between 3 and 10 moments.'
        : '- Return exactly 0 moments (an empty "moments" array).';

    return '''
You are a viral comedy content assistant. Your task is to analyze the provided YouTube transcript and identify the funniest, most shareable moments.

$langInstruction
$audienceInstruction
$availabilityInstruction

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
$momentCountConstraint
- Timestamps must be in seconds (numbers, not strings).
- endSec MUST be greater than startSec.
- Prefer clips between 20 and 70 seconds when possible.
- Each clip duration (endSec - startSec) must NOT exceed 120 seconds.
- Moments must NOT overlap (no two moments share the same time range).
- Sort moments by startSec ascending.
- postText should be concise and platform-ready (no hashtag spam).
- Ignore garbled ASR/noisy transcript fragments; select moments with clear setup and punchline.
- Avoid generic captions/postText; use specific, sharp, internet-native phrasing.
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

  String _audienceInstruction() {
    return '''
## Audience & Tone
Target audience: women 18-35 in Ukraine.
Style: witty, modern, playful, and confident.
Keep it cool and meme-aware, not generic or cringe.
Avoid stale punchlines, forced slang, and "boomer" humor.
''';
  }

  String _formatTranscript(List<TranscriptSegment> segments) {
    if (segments.isEmpty) return '(No transcript available for the selected language.)';
    return segments
        .map((s) => '[${s.startSec.toStringAsFixed(1)}s - ${s.endSec.toStringAsFixed(1)}s] ${s.text}')
        .join('\n');
  }

  String _availabilityInstruction(bool hasTranscript) {
    if (hasTranscript) {
      return '''
Use only the transcript text below.
Do NOT invent details and do NOT claim you watched/listened to the video directly.
''';
    }
    return '''
Transcript is unavailable.
Do NOT invent moments and do NOT analyze unseen video/audio content.
Return a valid JSON object with "moments": [].
''';
  }

  String _formatDuration(double seconds) {
    final h = (seconds ~/ 3600);
    final m = ((seconds % 3600) ~/ 60);
    final s = (seconds % 60).floor();
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }
}
