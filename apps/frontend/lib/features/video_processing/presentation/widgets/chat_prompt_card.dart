import 'package:flutter/material.dart';
import '../../../../../i18n/strings.g.dart';

/// Widget to display AI prompt with copy and open actions
class ChatPromptCard extends StatelessWidget {
  const ChatPromptCard({
    super.key,
    required this.prompt,
    required this.onCopy,
    required this.onOpenAi,
    required this.onProceed,
  });

  final String prompt;
  final VoidCallback onCopy;
  final VoidCallback onOpenAi;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.chat.aiPromptTitle,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            t.chat.aiPromptSubtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Prompt preview
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      prompt,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(t.chat.copyPrompt),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenAi,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(t.chat.openAiTool),
                    ),
                    TextButton(
                      onPressed: onProceed,
                      child: Text(t.chat.iHaveResponse),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
