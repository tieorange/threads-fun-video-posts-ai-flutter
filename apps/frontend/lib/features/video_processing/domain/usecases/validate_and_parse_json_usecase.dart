import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';

class ValidateAndParseJsonUseCase {
  const ValidateAndParseJsonUseCase();

  Either<Failure, Map<String, dynamic>> call(String rawJson) {
    var source = rawJson.trim();
    if (source.isEmpty) {
      return left(const ValidationFailure('JSON input is empty.'));
    }

    // Try to extract JSON from markdown or conversational text
    // Looks for the first '{' and corresponding last '}'
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(source);
    if (jsonMatch != null) {
      source = jsonMatch.group(0)!;
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return left(const ValidationFailure('JSON must be an object.'));
      }

      final errors = <String>[];
      final normalizedPayload = Map<String, dynamic>.from(decoded);

      final videoTitle = _asNonEmptyString(decoded['videoTitle']);
      if (videoTitle == null) {
        errors.add('Missing "videoTitle"');
      } else {
        normalizedPayload['videoTitle'] = videoTitle;
      }

      final language = _asNonEmptyString(decoded['language']);
      if (language == null) {
        errors.add('Missing "language"');
      } else {
        normalizedPayload['language'] = language;
      }

      final moments = decoded['moments'];
      if (moments == null) {
        errors.add('Missing "moments" array');
      } else if (moments is! List) {
        errors.add('"moments" must be an array');
      } else if (moments.length > 10) {
        errors.add('"moments" must contain at most 10 items (got ${moments.length})');
      } else {
        final normalizedMoments = <Map<String, dynamic>>[];
        for (var i = 0; i < moments.length; i++) {
          final m = moments[i];
          if (m is! Map) {
            errors.add('Moment $i is not an object');
            continue;
          }

          final map = Map<String, dynamic>.from(m);
          final id = _asNonEmptyString(map['id']) ?? 'm${i + 1}';
          final caption = _firstNonEmptyString([map['caption'], map['title'], map['hook']]);
          final postText = _firstNonEmptyString([
            map['postText'],
            map['socialPost'],
            map['post'],
            map['text'],
          ]);
          final reason = _firstNonEmptyString([map['reason'], map['why'], map['explanation']]);

          final start = map['startSec'];
          final end = map['endSec'];

          if (caption == null) errors.add('Moment $i missing "caption"');
          if (postText == null) errors.add('Moment $i missing "postText"');
          if (reason == null) errors.add('Moment $i missing "reason"');
          if (start == null) {
            errors.add('Moment $i missing "startSec"');
          } else if (start is! num) {
            errors.add('Moment $i "startSec" must be a number');
          }
          if (end == null) {
            errors.add('Moment $i missing "endSec"');
          } else if (end is! num) {
            errors.add('Moment $i "endSec" must be a number');
          }

          if (caption != null && postText != null && reason != null && start is num && end is num) {
            normalizedMoments.add({
              'id': id,
              'caption': caption,
              'postText': postText,
              'reason': reason,
              'startSec': start,
              'endSec': end,
            });
          }
        }
        normalizedPayload['moments'] = normalizedMoments;
      }

      if (errors.isNotEmpty) {
        return left(ValidationFailure(errors.join('\n')));
      }

      return right(normalizedPayload);
    } on FormatException catch (e) {
      return left(ValidationFailure('Invalid JSON: ${e.message}'));
    }
  }

  String? _asNonEmptyString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final normalized = _asNonEmptyString(value);
      if (normalized != null) return normalized;
    }
    return null;
  }
}
