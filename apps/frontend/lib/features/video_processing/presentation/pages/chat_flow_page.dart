import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../domain/entities/chat_message.dart';
import '../cubits/chat_flow_cubit.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/chat_video_metadata_card.dart';
import '../widgets/chat_prompt_card.dart';
import '../../../../../core/widgets/app_shell_scaffold.dart';
import '../../../../../i18n/strings.g.dart';

/// Main chat interface page for the video processing flow
class ChatFlowPage extends StatefulWidget {
  const ChatFlowPage({super.key});

  @override
  State<ChatFlowPage> createState() => _ChatFlowPageState();
}

class _ChatFlowPageState extends State<ChatFlowPage> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  double _lastBottomInset = 0;
  bool _showJumpToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = !_isNearBottom();
    if (shouldShow != _showJumpToBottom && mounted) {
      setState(() {
        _showJumpToBottom = shouldShow;
      });
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    return (max - current) < 120;
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(target);
        }
      }
    });
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final cubit = context.read<ChatFlowCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.chat.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.chat.retry),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: t.chat.title,
      actions: [
        IconButton(
          onPressed: () => _showResetConfirmation(context),
          icon: const Icon(Icons.refresh),
          tooltip: t.chat.retry,
        ),
      ],
      body: BlocConsumer<ChatFlowCubit, ChatFlowState>(
        listener: (context, state) {
          // Navigate to review page on completion
          if (state is ChatFlowCompleted) {
            context.go('/review');
          }
        },
        builder: (context, state) {
          final mediaQuery = MediaQuery.of(context);
          final bottomInset = mediaQuery.viewInsets.bottom;
          final shouldAutoScroll =
              state.messages.length > _lastMessageCount && _isNearBottom();
          final keyboardShifted = (bottomInset - _lastBottomInset).abs() > 8;
          final keepBottomVisible = keyboardShifted && _isNearBottom();
          _lastMessageCount = state.messages.length;
          _lastBottomInset = bottomInset;

          if (shouldAutoScroll) {
            _scrollToBottom();
          }
          if (keepBottomVisible) {
            _scrollToBottom(animated: false);
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: math.max(0, bottomInset - 12)),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Messages list
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return _buildMessageItem(context, message, state);
                          },
                        ),
                      ),
                      // Input area based on current step
                      ChatInputArea(
                        currentStep: state.currentStep,
                        onUrlSubmit: (url) => context.read<ChatFlowCubit>().submitUrl(url),
                        onJsonSubmit: (json) => context.read<ChatFlowCubit>().submitJson(json),
                        errorMessage: state.errorMessage,
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 86 + math.max(mediaQuery.padding.bottom, 0),
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      offset: _showJumpToBottom ? Offset.zero : const Offset(0, 1.2),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _showJumpToBottom ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !_showJumpToBottom,
                          child: FloatingActionButton.small(
                            onPressed: () => _scrollToBottom(),
                            child: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ChatMessage message,
    ChatFlowState state,
  ) {
    // For special message types that need interaction, use specialized builders
    if (message.type == MessageType.languageSelection && state is ChatFlowLanguageSelection) {
      return _buildLanguageSelector(context, state);
    }

    if (message.type == MessageType.videoMetadata && state is ChatFlowMetadata) {
      return ChatVideoMetadataCard(
        metadata: state.videoMetadata,
        onContinue: () {
          context.read<ChatFlowCubit>().buildPrompt();
        },
      );
    }

    if (message.type == MessageType.aiPrompt && state is ChatFlowPromptReady) {
      return ChatPromptCard(
        prompt: state.prompt,
        onCopy: () => context.read<ChatFlowCubit>().copyPrompt(),
        onOpenAi: () => context.read<ChatFlowCubit>().openAiTool('https://chat.openai.com'),
        onProceed: () => context.read<ChatFlowCubit>().proceedToJsonInput(),
      );
    }

    // For regular messages, use the bubble
    return ChatMessageBubble(
      message: message,
      state: state,
    );
  }

  /// Build language selector chips
  Widget _buildLanguageSelector(BuildContext context, ChatFlowLanguageSelection state) {
    final colorScheme = Theme.of(context).colorScheme;
    final languages = [
      ('en', t.analyze.languages.en),
      ('uk', t.analyze.languages.uk),
      ('uk_18', t.analyze.languages.uk_18),
      ('ru', t.analyze.languages.ru),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((lang) {
            return ActionChip(
              label: Text(lang.$2),
              onPressed: () {
                context.read<ChatFlowCubit>().selectLanguage(lang.$1);
              },
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(color: colorScheme.outlineVariant),
            );
          }).toList(),
        ),
      ),
    );
  }
}
