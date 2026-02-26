part of 'json_paste_cubit.dart';

sealed class JsonPasteState {
  const JsonPasteState();
}

final class JsonPasteIdle extends JsonPasteState {
  const JsonPasteIdle();
}

final class JsonPasteInvalid extends JsonPasteState {
  const JsonPasteInvalid(this.message);
  final String message;
}

final class JsonPasteValid extends JsonPasteState {
  const JsonPasteValid({required this.payload, required this.moments});
  final Map<String, dynamic> payload;
  final List<FunnyMoment> moments;
}
