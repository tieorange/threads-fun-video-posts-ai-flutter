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
      } else if (moments.length < 3 || moments.length > 10) {
        errors.add('"moments" must contain between 3 and 10 items (got ${moments.length})');
      } else {
        for (var i = 0; i < moments.length; i++) {
          final m = moments[i];
          if (m is! Map) {
            errors.add('Moment $i is not an object');
            continue;
          }
          for (final field in ['id', 'startSec', 'endSec', 'caption', 'postText', 'reason']) {
            if (m[field] == null) errors.add('Moment $i missing "$field"');
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
