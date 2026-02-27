import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../cubits/chat_flow_cubit.dart';
import '../../../../../i18n/strings.g.dart';

/// Dynamic input area that adapts to current flow step
class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,
    required this.currentStep,
    required this.onUrlSubmit,
    required this.onJsonSubmit,
    this.errorMessage,
  });

  final ChatStep currentStep;
  final ValueChanged<String> onUrlSubmit;
  final ValueChanged<String> onJsonSubmit;
  final String? errorMessage;

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final _urlController = TextEditingController();
  final _jsonController = TextEditingController();
  final _urlFocusNode = FocusNode();
  final _jsonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onInputChanged);
    _jsonController.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.currentStep == ChatStep.welcome) {
        _urlFocusNode.requestFocus();
      } else if (widget.currentStep == ChatStep.jsonInput) {
        _jsonFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _urlController.removeListener(_onInputChanged);
    _jsonController.removeListener(_onInputChanged);
    _urlController.dispose();
    _jsonController.dispose();
    _urlFocusNode.dispose();
    _jsonFocusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (widget.currentStep) {
          case ChatStep.welcome:
            _urlFocusNode.requestFocus();
            break;
          case ChatStep.jsonInput:
            _jsonFocusNode.requestFocus();
            break;
          case ChatStep.languageSelection:
          case ChatStep.analyzing:
          case ChatStep.metadata:
          case ChatStep.buildingPrompt:
          case ChatStep.promptReady:
          case ChatStep.validating:
          case ChatStep.completed:
            FocusScope.of(context).unfocus();
            break;
        }
      });
    }
  }

  void _submitUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      widget.onUrlSubmit(url);
      _urlController.clear();
    }
  }

  void _submitJson() {
    final json = _jsonController.text.trim();
    if (json.isNotEmpty) {
      widget.onJsonSubmit(json);
      _jsonController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.currentStep) {
      ChatStep.welcome => _buildUrlInput(context),
      ChatStep.languageSelection => const SizedBox.shrink(), // Language selection uses buttons, not input
      ChatStep.analyzing => _buildDisabledInput(context, t.chat.analyzingVideo),
      ChatStep.metadata => const SizedBox.shrink(),
      ChatStep.buildingPrompt => const SizedBox.shrink(),
      ChatStep.promptReady => const SizedBox.shrink(),
      ChatStep.jsonInput => _buildJsonInput(context),
      ChatStep.validating => _buildDisabledInput(context, t.chat.validating),
      ChatStep.completed => const SizedBox.shrink(),
    };
  }

  Widget _buildUrlInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomSafe = mediaQuery.padding.bottom;
    final isSendEnabled = _urlController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + math.max(bottomSafe, 8)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              onTapOutside: (_) => _urlFocusNode.unfocus(),
              decoration: InputDecoration(
                hintText: t.chat.urlHint,
                prefixIcon: const Icon(Icons.link),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _submitUrl(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton.filled(
              onPressed: isSendEnabled ? _submitUrl : null,
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomSafe = mediaQuery.padding.bottom;
    final isValidateEnabled = _jsonController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + math.max(bottomSafe, 8)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _jsonController,
            focusNode: _jsonFocusNode,
            onTapOutside: (_) => _jsonFocusNode.unfocus(),
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: t.chat.jsonHint,
              alignLabelWithHint: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.35,
            ),
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: isValidateEnabled ? _submitJson : null,
              icon: const Icon(Icons.check),
              label: Text(t.paste.validate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledInput(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + math.max(bottomSafe, 8)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
