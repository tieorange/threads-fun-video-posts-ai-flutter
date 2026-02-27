import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/analyze_cubit.dart';
import '../cubits/prompt_cubit.dart';
import '../cubits/json_paste_cubit.dart';
import '../cubits/moments_review_cubit.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import '../../../../../i18n/strings.g.dart';

class AnalyzeInputPage extends StatefulWidget {
  const AnalyzeInputPage({super.key});

  @override
  State<AnalyzeInputPage> createState() => _AnalyzeInputPageState();
}

class _AnalyzeInputPageState extends State<AnalyzeInputPage> {
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  String _language = 'uk_18';

  List<(String, String)> get _languages => [
    ('en', t.analyze.languages.en),
    ('uk', t.analyze.languages.uk),
    ('uk_18', t.analyze.languages.uk_18),
    ('ru', t.analyze.languages.ru),
  ];

  @override
  void initState() {
    super.initState();
    // Reset all states when entering the start page to prevent stale data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyzeCubit>().reset();
      context.read<PromptCubit>().reset();
      context.read<JsonPasteCubit>().reset();
      context.read<MomentsReviewCubit>().reset();
      context.read<ProcessCubit>().reset();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
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
      setState(() => _urlController.text = data!.text!);
      return;
    }

    // Safari iOS: clipboard API unavailable — focus field so user can long-press → Paste
    _urlFocusNode.requestFocus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Long-press the text field, then tap Paste'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _analyze() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    context.read<AnalyzeCubit>().analyze(url, _language);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: t.analyze.title,
      body: BlocListener<AnalyzeCubit, AnalyzeState>(
        listener: (context, state) {
          if (state is AnalyzeSuccess) {
            context.read<PromptCubit>().build(state.result);
            context.go('/prompt');
          } else if (state is AnalyzeFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48), // breathing room at top
                  Text(
                    t.analyze.subtitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    decoration: InputDecoration(
                      labelText: t.analyze.urlLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste),
                        onPressed: _pasteFromClipboard,
                        tooltip: t.common.paste,
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (_) => _analyze(),
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    initialSelection: _language,
                    label: Text(t.analyze.languageLabel),
                    leadingIcon: const Icon(Icons.language),
                    expandedInsets: EdgeInsets.zero,
                    dropdownMenuEntries: _languages
                        .map((l) => DropdownMenuEntry(value: l.$1, label: l.$2))
                        .toList(),
                    onSelected: (v) => setState(() => _language = v ?? 'en'),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AnalyzeCubit, AnalyzeState>(
                    builder: (context, state) {
                      final loading = state is AnalyzeLoading;
                      return FilledButton.icon(
                        onPressed: loading ? null : _analyze,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(loading ? t.common.analyzing : t.common.analyze),
                      );
                    },
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
