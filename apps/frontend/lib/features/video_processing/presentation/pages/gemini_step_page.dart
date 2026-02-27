import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/prompt_cubit.dart';
import '../cubits/json_paste_cubit.dart';
import '../cubits/moments_review_cubit.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/launch_service.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import '../../../../../i18n/strings.g.dart';

class GeminiStepPage extends StatefulWidget {
  const GeminiStepPage({super.key});

  @override
  State<GeminiStepPage> createState() => _GeminiStepPageState();
}

class _GeminiStepPageState extends State<GeminiStepPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _step1Done = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copyAndOpen() async {
    await context.read<PromptCubit>().copyToClipboard();
    setState(() => _step1Done = true);

    // Scroll to paste area so it's ready when user comes back from Gemini.
    // Uses ScrollController — no BuildContext needed after the async gap.
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    // Launch Gemini — iOS app deeplink with web fallback (fire and forget).
    sl<LaunchService>().openGemini();
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (_) {
      data = null;
    }

    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() => _controller.text = data!.text!);
      return;
    }

    // Safari iOS: clipboard API restricted — focus field so user can long-press → Paste.
    _focusNode.requestFocus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Long-press the text field, then tap Paste'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _validate() {
    context.read<JsonPasteCubit>().validate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppShellScaffold(
      title: t.geminiStep.title,
      leading: BackButton(onPressed: () => context.go('/')),
      body: BlocListener<JsonPasteCubit, JsonPasteState>(
        listener: (context, state) {
          if (state is JsonPasteValid) {
            context.read<MomentsReviewCubit>().load(state.moments, state.payload);
            context.go('/review', extra: state.payload);
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Step 1: copy prompt & open Gemini ─────────────────
                  _Step1Card(
                    step1Done: _step1Done,
                    onCopyAndOpen: _copyAndOpen,
                  ),
                  const SizedBox(height: 16),

                  // ── Step 2: paste response ─────────────────────────────
                  AnimatedOpacity(
                      opacity: _step1Done ? 1.0 : 0.45,
                      duration: const Duration(milliseconds: 300),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.geminiStep.step2Title,
                                      style: textTheme.titleMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: _pasteFromClipboard,
                                    icon: const Icon(Icons.content_paste, size: 18),
                                    label: Text(t.common.paste),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              if (_step1Done) ...[
                                const SizedBox(height: 6),
                                Text(
                                  t.geminiStep.step2Hint,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 220,
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    hintText: t.paste.hint,
                                    border: const OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                  contextMenuBuilder:
                                      (context, editableTextState) =>
                                          AdaptiveTextSelectionToolbar.editableText(
                                            editableTextState: editableTextState,
                                          ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              BlocBuilder<JsonPasteCubit, JsonPasteState>(
                                builder: (context, state) {
                                  if (state is JsonPasteInvalid) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Card(
                                        color: colorScheme.errorContainer,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: colorScheme.onErrorContainer,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  state.message,
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .onErrorContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(t.geminiStep.validate),
                  ),
                  // Bottom buffer so button clears the Safari toolbar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 1 card extracted for clarity ──────────────────────────────────────

class _Step1Card extends StatelessWidget {
  const _Step1Card({
    required this.step1Done,
    required this.onCopyAndOpen,
  });

  final bool step1Done;
  final VoidCallback onCopyAndOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.geminiStep.step1Title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              t.geminiStep.step1Hint,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Prompt preview — scrollable, fixed height
            BlocBuilder<PromptCubit, PromptState>(
              builder: (context, state) {
                final prompt = switch (state) {
                  PromptReady(:final prompt) => prompt,
                  PromptCopied(:final prompt) => prompt,
                  _ => '',
                };
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Card.outlined(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        prompt,
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            BlocBuilder<PromptCubit, PromptState>(
              builder: (context, state) {
                final copied = state is PromptCopied;
                return FilledButton.icon(
                  onPressed: onCopyAndOpen,
                  icon: Icon(copied ? Icons.check : Icons.open_in_new),
                  label: Text(
                    copied ? t.geminiStep.copiedLabel : t.geminiStep.copyOpen,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
