part of 'prompt_cubit.dart';

sealed class PromptState {
  const PromptState();
}

final class PromptEmpty extends PromptState {
  const PromptEmpty();
}

final class PromptReady extends PromptState {
  const PromptReady(this.prompt);
  final String prompt;
}

final class PromptCopied extends PromptState {
  const PromptCopied(this.prompt);
  final String prompt;
}
