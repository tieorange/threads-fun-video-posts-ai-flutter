import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/usecases/build_ai_prompt_usecase.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';

part 'prompt_state.dart';

class PromptCubit extends Cubit<PromptState> {
  PromptCubit(this._buildPrompt, this._log) : super(const PromptEmpty());

  final BuildAiPromptUseCase _buildPrompt;
  final AppLogger _log;

  void build(AnalyzeResult result) {
    final prompt = _buildPrompt(result);
    _log.info('prompt_built', 'AI prompt built', layer: AppLayer.domain,
        data: {'promptLength': prompt.length});
    emit(PromptReady(prompt));
  }

  Future<void> copyToClipboard() async {
    final current = state;
    if (current is PromptReady || current is PromptCopied) {
      final text = current is PromptReady ? current.prompt : (current as PromptCopied).prompt;
      await Clipboard.setData(ClipboardData(text: text));
      _log.info('prompt_copied', 'Prompt copied to clipboard', layer: AppLayer.presentation);
      emit(PromptCopied(text));
    }
  }

  void reset() => emit(const PromptEmpty());
}
