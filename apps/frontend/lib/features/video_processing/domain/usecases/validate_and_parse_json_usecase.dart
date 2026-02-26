import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';

class ValidateAndParseJsonUseCase {
  const ValidateAndParseJsonUseCase();

  Either<Failure, Map<String, dynamic>> call(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return left(const ValidationFailure('JSON input is empty.'));
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return left(const ValidationFailure('JSON must be an object.'));
      }

      final errors = <String>[];

      if (decoded['videoTitle'] == null) errors.add('Missing "videoTitle"');
      if (decoded['language'] == null) errors.add('Missing "language"');

      final moments = decoded['moments'];
      if (moments == null) {
        errors.add('Missing "moments" array');
      } else if (moments is! List) {
        errors.add('"moments" must be an array');
      } else if (moments.length > 10) {
        errors.add('"moments" must contain at most 10 items (got ${moments.length})');
      } else {
        for (var i = 0; i < moments.length; i++) {
          final m = moments[i];
          if (m is! Map) {
            errors.add('Moment $i is not an object');
            continue;
          }
          for (final field in ['id', 'caption', 'postText', 'reason']) {
            if (m[field] == null) {
              errors.add('Moment $i missing "$field"');
            } else if (m[field] is! String) {
              errors.add('Moment $i "$field" must be a string');
            }
          }
          for (final field in ['startSec', 'endSec']) {
            if (m[field] == null) {
              errors.add('Moment $i missing "$field"');
            } else if (m[field] is! num) {
              errors.add('Moment $i "$field" must be a number');
            }
          }
        }
      }

      if (errors.isNotEmpty) {
        return left(ValidationFailure(errors.join('\n')));
      }

      return right(decoded);
    } on FormatException catch (e) {
      return left(ValidationFailure('Invalid JSON: ${e.message}'));
    }
  }
}
