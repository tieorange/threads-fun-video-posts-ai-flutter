import 'package:flutter/material.dart';
import '../../domain/entities/video_metadata.dart';
import '../../../../../i18n/strings.g.dart';

/// Widget to display video metadata with continue button
class ChatVideoMetadataCard extends StatelessWidget {
  const ChatVideoMetadataCard({
    super.key,
    required this.metadata,
    required this.onContinue,
  });

  final VideoMetadata metadata;
  final VoidCallback onContinue;

  String _formatDuration(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

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
                // Video info row
                Row(
                  children: [
                    // Thumbnail placeholder
                    Container(
                      width: 64,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.play_circle_outline,
                        color: colorScheme.onSurfaceVariant,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata.title,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(metadata.durationSec),
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
                Divider(
                  color: colorScheme.outlineVariant,
                  height: 1,
                ),
                const SizedBox(height: 16),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(t.chat.proceed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
