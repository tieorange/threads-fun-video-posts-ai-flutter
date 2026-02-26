import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/usecases/validate_and_parse_json_usecase.dart';

part 'json_paste_state.dart';

class JsonPasteCubit extends Cubit<JsonPasteState> {
  JsonPasteCubit(this._validateUseCase) : super(const JsonPasteIdle());

  final ValidateAndParseJsonUseCase _validateUseCase;

  void validate(String rawJson) {
    final result = _validateUseCase(rawJson);
    result.fold(
      (failure) => emit(JsonPasteInvalid(failure.message)),
      (payload) {
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
        emit(JsonPasteValid(payload: payload, moments: moments));
      },
    );
  }

  void reset() => emit(const JsonPasteIdle());
}
