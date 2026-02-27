import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../cubits/chat_flow_cubit.dart';
import 'chat_video_metadata_card.dart';
import 'chat_prompt_card.dart';
import 'chat_typing_indicator.dart';

/// Widget that renders individual chat messages with appropriate styling
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.state,
  });

  final ChatMessage message;
  final ChatFlowState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (message.type) {
      MessageType.languageSelection => _buildTextBubble(context, colorScheme),
      MessageType.videoMetadata => _buildMetadataCard(context),
      MessageType.aiPrompt => _buildPromptCard(context),
      MessageType.error => _buildErrorBubble(context, colorScheme),
      MessageType.loading => _buildLoadingBubble(context, colorScheme),
      MessageType.text => _buildTextBubble(context, colorScheme),
    };
  }

  Widget _buildTextBubble(BuildContext context, ColorScheme colorScheme) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final textColor = isUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildErrorBubble(BuildContext context, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated typing indicator
            const ChatTypingIndicator(),
            // Optional text below indicator
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context) {
    final metadataState = state;
    if (metadataState is ChatFlowMetadata) {
      return ChatVideoMetadataCard(
        metadata: metadataState.videoMetadata,
        onContinue: () {
          // This will be handled by the parent widget with Cubit
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPromptCard(BuildContext context) {
    final promptState = state;
    if (promptState is ChatFlowPromptReady) {
      return ChatPromptCard(
        prompt: promptState.prompt,
        onCopy: () {},
        onOpenAi: () {},
        onProceed: () {},
      );
    }
    return const SizedBox.shrink();
  }
}
