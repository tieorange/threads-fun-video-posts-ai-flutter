import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/usecases/build_ai_prompt_usecase.dart';

part 'prompt_state.dart';

class PromptCubit extends Cubit<PromptState> {
  PromptCubit(this._buildPrompt) : super(const PromptEmpty());

  final BuildAiPromptUseCase _buildPrompt;

  void build(AnalyzeResult result) {
    final prompt = _buildPrompt(result);
    emit(PromptReady(prompt));
  }

  Future<void> copyToClipboard() async {
    final current = state;
    if (current is PromptReady || current is PromptCopied) {
      final text = current is PromptReady ? current.prompt : (current as PromptCopied).prompt;
      await Clipboard.setData(ClipboardData(text: text));
      emit(PromptCopied(text));
    }
  }

  void reset() => emit(const PromptEmpty());
}
