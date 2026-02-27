import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/json_paste_cubit.dart';
import '../cubits/moments_review_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import '../../../../../i18n/strings.g.dart';

class AiJsonPastePage extends StatefulWidget {
  const AiJsonPastePage({super.key});

  @override
  State<AiJsonPastePage> createState() => _AiJsonPastePageState();
}

class _AiJsonPastePageState extends State<AiJsonPastePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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

    // Safari iOS: clipboard API unavailable — focus field so user can long-press → Paste
    _focusNode.requestFocus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Long-press the text field, then tap Paste'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _validate() {
    context.read<JsonPasteCubit>().validate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: t.paste.title,
      leading: BackButton(onPressed: () => context.go('/prompt')),
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          t.paste.subtitle,
                          style: Theme.of(context).textTheme.titleMedium,
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
                  const SizedBox(height: 8),
                  Expanded(
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                      contextMenuBuilder: (context, editableTextState) =>
                          AdaptiveTextSelectionToolbar.editableText(
                            editableTextState: editableTextState,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<JsonPasteCubit, JsonPasteState>(
                    builder: (context, state) {
                      if (state is JsonPasteInvalid) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.message,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
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
                  FilledButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(t.paste.validate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
