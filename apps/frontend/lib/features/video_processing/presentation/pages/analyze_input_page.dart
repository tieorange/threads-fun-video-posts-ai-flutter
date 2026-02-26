import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/analyze_cubit.dart';
import '../cubits/prompt_cubit.dart';
import '../cubits/json_paste_cubit.dart';
import '../cubits/moments_review_cubit.dart';
import '../cubits/process_cubit.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';

class AnalyzeInputPage extends StatefulWidget {
  const AnalyzeInputPage({super.key});

  @override
  State<AnalyzeInputPage> createState() => _AnalyzeInputPageState();
}

class _AnalyzeInputPageState extends State<AnalyzeInputPage> {
  final _urlController = TextEditingController();
  String _language = 'en';

  static const _languages = [
    ('en', 'English'),
    ('uk', 'Ukrainian'),
    ('uk_18', 'Ukrainian 18+'),
    ('ru', 'Russian'),
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
    super.dispose();
  }

  void _analyze() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    context.read<AnalyzeCubit>().analyze(url, _language);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: 'Funny Threads AI',
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Turn a YouTube video into viral clips',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube URL',
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _analyze(),
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    initialSelection: _language,
                    label: const Text('Language profile'),
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
                        label: Text(loading ? 'Analyzing...' : 'Analyze'),
                      );
                    },
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
