import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/prompt_cubit.dart';

class PromptBuilderPage extends StatelessWidget {
  const PromptBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copy AI Prompt'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: BlocBuilder<PromptCubit, PromptState>(
        builder: (context, state) {
          final prompt = switch (state) {
            PromptReady(:final prompt) => prompt,
            PromptCopied(:final prompt) => prompt,
            _ => '',
          };
          final copied = state is PromptCopied;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '1. Copy the prompt below',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2. Paste it into ChatGPT, Claude, Gemini, etc.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            prompt,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<PromptCubit>().copyToClipboard(),
                      icon: Icon(copied ? Icons.check : Icons.copy),
                      label: Text(copied ? 'Copied!' : 'Copy Prompt'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/paste'),
                      child: const Text('I\'ve got the AI response — Paste JSON'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
