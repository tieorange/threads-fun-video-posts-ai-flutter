import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/usecases/validate_and_parse_json_usecase.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';

part 'json_paste_state.dart';

class JsonPasteCubit extends Cubit<JsonPasteState> {
  JsonPasteCubit(this._validateUseCase, this._log) : super(const JsonPasteIdle());

  final ValidateAndParseJsonUseCase _validateUseCase;
  final AppLogger _log;

  void validate(String rawJson) {
    _log.info(
      'json_validate_start',
      'Validating pasted JSON',
      layer: AppLayer.presentation,
      data: {'jsonLength': rawJson.length},
    );
    final result = _validateUseCase(rawJson);
    result.fold(
      (failure) {
        _log.warn('json_validate_invalid', failure.message, layer: AppLayer.presentation);
        emit(JsonPasteInvalid(failure.message));
      },
      (payload) {
        try {
          final rawMoments = payload['moments'] as List<dynamic>;
          final moments = rawMoments.map((m) {
            final map = m as Map<String, dynamic>;
            return FunnyMoment(
              id: map['id'] as String,
              startSec: (map['startSec'] as num).toDouble(),
              endSec: (map['endSec'] as num).toDouble(),
              caption: map['caption'] as String,
              postText: map['postText'] as String,
              reason: map['reason'] as String,
            );
          }).toList();
          _log.info(
            'json_validate_valid',
            'JSON valid',
            layer: AppLayer.presentation,
            data: {'momentCount': moments.length},
          );
          emit(JsonPasteValid(payload: payload, moments: moments));
        } catch (e) {
          _log.warn(
            'json_parse_error',
            'Failed to map json to objects: $e',
            layer: AppLayer.presentation,
          );
          emit(JsonPasteInvalid('Data shape error: $e'));
        }
      },
    );
  }

  void reset() => emit(const JsonPasteIdle());
}
