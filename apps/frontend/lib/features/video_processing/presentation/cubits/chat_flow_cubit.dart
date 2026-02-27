import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/entities/video_metadata.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/usecases/analyze_video_usecase.dart';
import '../../domain/usecases/build_ai_prompt_usecase.dart';
import '../../domain/usecases/validate_and_parse_json_usecase.dart';
import '../../data/datasources/chat_local_storage_datasource.dart';
import '../../../../../core/failures/failure.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';
import '../../../../../core/utils/clipboard_service.dart';
import '../../../../../core/utils/launch_service.dart';
import '../../../../../i18n/strings.g.dart';

part 'chat_flow_state.dart';

class ChatFlowCubit extends Cubit<ChatFlowState> {
  ChatFlowCubit({
    required AnalyzeVideoUseCase analyzeVideoUseCase,
    required BuildAiPromptUseCase buildAiPromptUseCase,
    required ValidateAndParseJsonUseCase validateAndParseJsonUseCase,
    required AppLogger log,
    required ClipboardService clipboard,
    required LaunchService launchService,
    required ChatLocalStorageDatasource localStorage,
  })  : _analyzeVideoUseCase = analyzeVideoUseCase,
        _buildAiPromptUseCase = buildAiPromptUseCase,
        _validateAndParseJsonUseCase = validateAndParseJsonUseCase,
        _log = log,
        _clipboard = clipboard,
        _launchService = launchService,
        _localStorage = localStorage,
        super(_initialState()) {
    // Try to restore persisted state
    _restoreState();
  }

  final AnalyzeVideoUseCase _analyzeVideoUseCase;
  final BuildAiPromptUseCase _buildAiPromptUseCase;
  final ValidateAndParseJsonUseCase _validateAndParseJsonUseCase;
  final AppLogger _log;
  final ClipboardService _clipboard;
  final LaunchService _launchService;
  final ChatLocalStorageDatasource _localStorage;

  /// Create initial state with welcome message
  static ChatFlowState _initialState() {
    return ChatFlowInitial(
      messages: [
        ChatMessage.bot(
          text: t.chat.welcomeMessage,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Restore state from localStorage if available
  void _restoreState() {
    try {
      final persistedData = _localStorage.loadState();
      if (persistedData != null) {
        _log.info(
          'chatflow_state_restored',
          'Restored chat state from localStorage',
          layer: AppLayer.presentation,
          data: {'step': persistedData.currentStep, 'messages': persistedData.messages.length},
        );

        // Restore state based on persisted step
        final restoredState = _createStateFromPersistence(persistedData);
        if (restoredState != null) {
          emit(restoredState);
        }
      }
    } catch (e) {
      _log.error(
        'chatflow_restore_failed',
        'Failed to restore chat state: $e',
        layer: AppLayer.presentation,
      );
    }
  }

  /// Create state object from persisted data
  ChatFlowState? _createStateFromPersistence(ChatPersistenceData data) {
    return switch (data.currentStep) {
      'welcome' => ChatFlowInitial(messages: data.messages),
      'languageSelection' => data.url != null
          ? ChatFlowLanguageSelection(messages: data.messages, url: data.url!)
          : null,
      'analyzing' => (data.url != null && data.language != null)
          ? ChatFlowAnalyzing(
              messages: data.messages,
              url: data.url!,
              language: data.language!,
            )
          : null,
      // For metadata and beyond, we can't fully restore without analyzeResult
      // So we go back to language selection
      'metadata' || 'buildingPrompt' || 'promptReady' || 'jsonInput' => data.url != null
          ? ChatFlowLanguageSelection(messages: data.messages, url: data.url!)
          : ChatFlowInitial(messages: data.messages),
      _ => null,
    };
  }

  /// Persist current state to localStorage
  void _persistState() {
    try {
      final currentState = state;
      String? persistedUrl;
      String? persistedLanguage;
      String? persistedYoutubeUrl;
      Map<String, dynamic>? persistedAiPayload;

      // Extract data based on state type
      switch (currentState) {
        case ChatFlowLanguageSelection(:final url):
          persistedUrl = url;
        case ChatFlowAnalyzing(:final url, :final language):
          persistedUrl = url;
          persistedLanguage = language;
        case ChatFlowCompleted(:final youtubeUrl, :final aiPayload):
          persistedYoutubeUrl = youtubeUrl;
          persistedAiPayload = aiPayload;
        default:
          break;
      }

      _localStorage.saveState(
        currentStep: currentState.currentStep.name,
        messages: currentState.messages,
        url: persistedUrl,
        language: persistedLanguage,
        youtubeUrl: persistedYoutubeUrl,
        aiPayload: persistedAiPayload,
      );
    } catch (e) {
      _log.error(
        'chatflow_persist_failed',
        'Failed to persist chat state: $e',
        layer: AppLayer.presentation,
      );
    }
  }

  /// Override emit to persist state after each change
  @override
  void emit(ChatFlowState state) {
    super.emit(state);
    _persistState();
  }

  /// Immutable message addition helper
  List<ChatMessage> _addMessage(ChatMessage message) {
    return [...state.messages, message];
  }

  /// Add a bot message to conversation
  void addBotMessage(String text, {MessageType type = MessageType.text}) {
    final newMessage = ChatMessage.bot(
      text: text,
      timestamp: DateTime.now(),
      type: type,
    );
    emit(_updateStateWithMessages(_addMessage(newMessage)));
  }

  /// Add a user message to conversation
  void addUserMessage(String text) {
    final newMessage = ChatMessage.user(
      text: text,
      timestamp: DateTime.now(),
    );
    emit(_updateStateWithMessages(_addMessage(newMessage)));
  }

  /// Update current state with new messages list
  ChatFlowState _updateStateWithMessages(List<ChatMessage> messages) {
    return switch (state) {
      ChatFlowInitial() => ChatFlowInitial(messages: messages),
      ChatFlowLanguageSelection(:final url) =>
        ChatFlowLanguageSelection(messages: messages, url: url),
      ChatFlowAnalyzing(:final url, :final language) =>
        ChatFlowAnalyzing(messages: messages, url: url, language: language),
      ChatFlowMetadata(:final videoMetadata, :final analyzeResult) =>
        ChatFlowMetadata(
          messages: messages,
          videoMetadata: videoMetadata,
          analyzeResult: analyzeResult,
        ),
      ChatFlowBuildingPrompt(:final language) =>
        ChatFlowBuildingPrompt(messages: messages, language: language),
      ChatFlowPromptReady(:final prompt, :final analyzeResult) =>
        ChatFlowPromptReady(
          messages: messages,
          prompt: prompt,
          analyzeResult: analyzeResult,
        ),
      ChatFlowJsonInput(:final prompt, :final analyzeResult) =>
        ChatFlowJsonInput(
          messages: messages,
          prompt: prompt,
          analyzeResult: analyzeResult,
        ),
      ChatFlowValidating(:final jsonInput) =>
        ChatFlowValidating(messages: messages, jsonInput: jsonInput),
      ChatFlowCompleted(:final aiPayload, :final moments, :final youtubeUrl) =>
        ChatFlowCompleted(
          messages: messages,
          aiPayload: aiPayload,
          moments: moments,
          youtubeUrl: youtubeUrl,
        ),
      ChatFlowError(:final errorMessage, :final recoverableStep, :final recoverableData) =>
        ChatFlowError(
          messages: messages,
          errorMessage: errorMessage,
          recoverableStep: recoverableStep,
          recoverableData: recoverableData,
        ),
    };
  }

  /// Submit YouTube URL - proceeds to language selection
  void submitUrl(String url) {
    _log.info(
      'chatflow_url_submitted',
      'User submitted URL',
      layer: AppLayer.presentation,
      data: {'url': url},
    );

    // Add user message
    final userMessage = ChatMessage.user(
      text: url,
      timestamp: DateTime.now(),
    );
    final messagesWithUser = _addMessage(userMessage);

    // Add language selection prompt
    final languagePrompt = ChatMessage.bot(
      text: t.chat.selectLanguagePrompt,
      timestamp: DateTime.now(),
      type: MessageType.languageSelection,
    );
    final messagesWithPrompt = [...messagesWithUser, languagePrompt];

    // Emit language selection state
    emit(ChatFlowLanguageSelection(
      messages: messagesWithPrompt,
      url: url,
    ));
  }

  /// Select language and analyze video
  Future<void> selectLanguage(String language) async {
    final currentState = state;
    if (currentState is! ChatFlowLanguageSelection) return;

    final url = currentState.url;

    _log.info(
      'chatflow_language_selected',
      'User selected language, starting analysis',
      layer: AppLayer.presentation,
      data: {'language': language, 'url': url},
    );

    // Add user message for language selection
    final languageLabel = _getLanguageLabel(language);
    final userMessage = ChatMessage.user(
      text: languageLabel,
      timestamp: DateTime.now(),
    );
    final messagesWithUser = [...state.messages, userMessage];

    // Emit analyzing state with selected language
    emit(ChatFlowAnalyzing(
      messages: messagesWithUser,
      url: url,
      language: language,
    ));

    // Add loading message
    final loadingMessage = ChatMessage.bot(
      text: t.chat.analyzingVideo,
      timestamp: DateTime.now(),
      type: MessageType.loading,
    );
    emit(ChatFlowAnalyzing(
      messages: [...messagesWithUser, loadingMessage],
      url: url,
      language: language,
    ));

    // Call analyze use case with selected language
    final result = await _analyzeVideoUseCase(url, language);

    result.fold(
      (failure) {
        _log.error(
          'chatflow_analyze_failed',
          failure.message,
          layer: AppLayer.presentation,
          data: {'url': url, 'language': language},
        );

        // Remove loading message and add error
        final messagesWithoutLoading = state.messages
            .where((m) => m.type != MessageType.loading)
            .toList();
        final errorMessage = ChatMessage.bot(
          text: _mapFailureToMessage(failure),
          timestamp: DateTime.now(),
          type: MessageType.error,
        );

        emit(ChatFlowError(
          messages: [...messagesWithoutLoading, errorMessage],
          errorMessage: failure.message,
          recoverableStep: ChatStep.languageSelection,
          recoverableData: {'url': url},
        ));
      },
      (analyzeResult) {
        _log.info(
          'chatflow_analyze_success',
          'Video analyzed successfully',
          layer: AppLayer.presentation,
          data: {
            'videoId': analyzeResult.video.videoId,
            'transcriptSegments': analyzeResult.transcript.length,
            'language': language,
          },
        );

        // Remove loading message and add metadata message
        final messagesWithoutLoading = state.messages
            .where((m) => m.type != MessageType.loading)
            .toList();
        final metadataMessage = ChatMessage.bot(
          text: t.chat.videoFound,
          timestamp: DateTime.now(),
          type: MessageType.videoMetadata,
        );

        emit(ChatFlowMetadata(
          messages: [...messagesWithoutLoading, metadataMessage],
          videoMetadata: analyzeResult.video,
          analyzeResult: analyzeResult,
        ));
      },
    );
  }

  /// Build AI prompt after metadata is shown
  void buildPrompt() {
    final currentState = state;
    if (currentState is! ChatFlowMetadata) return;

    final language = currentState.analyzeResult.language;

    _log.info(
      'chatflow_building_prompt',
      'Building AI prompt',
      layer: AppLayer.presentation,
      data: {'language': language},
    );

    // Emit building prompt state
    emit(ChatFlowBuildingPrompt(
      messages: state.messages,
      language: language,
    ));

    // Build prompt with the analyze result
    final prompt = _buildAiPromptUseCase(currentState.analyzeResult);

    _log.info(
      'chatflow_prompt_built',
      'AI prompt built successfully',
      layer: AppLayer.presentation,
      data: {'language': language},
    );

    // Add prompt ready message
    final promptMessage = ChatMessage.bot(
      text: t.chat.promptReady,
      timestamp: DateTime.now(),
      type: MessageType.aiPrompt,
    );

    emit(ChatFlowPromptReady(
      messages: [...state.messages, promptMessage],
      prompt: prompt,
      analyzeResult: currentState.analyzeResult,
    ));
  }

  /// Copy AI prompt to clipboard
  Future<void> copyPrompt() async {
    final currentState = state;
    if (currentState is! ChatFlowPromptReady) return;

    await _clipboard.copy(currentState.prompt);

    _log.info(
      'chatflow_prompt_copied',
      'Prompt copied to clipboard',
      layer: AppLayer.presentation,
    );

    // Add confirmation message
    final confirmationMessage = ChatMessage.bot(
      text: t.chat.promptCopied,
      timestamp: DateTime.now(),
    );

    emit(ChatFlowPromptReady(
      messages: [...state.messages, confirmationMessage],
      prompt: currentState.prompt,
      analyzeResult: currentState.analyzeResult,
    ));
  }

  /// Open external AI tool (ChatGPT, Claude, etc.) in a new tab
  Future<void> openAiTool(String toolUrl) async {
    final currentState = state;
    if (currentState is! ChatFlowPromptReady) return;

    // Copy prompt first
    await _clipboard.copy(currentState.prompt);

    // Open the tool in a new tab
    await _launchService.launchUrl(toolUrl);

    _log.info(
      'chatflow_ai_tool_opened',
      'AI tool opened',
      layer: AppLayer.presentation,
      data: {'toolUrl': toolUrl},
    );

    // Add instruction message and transition to JSON input
    final instructionMessage = ChatMessage.bot(
      text: t.chat.pasteJsonPrompt,
      timestamp: DateTime.now(),
    );

    emit(ChatFlowJsonInput(
      messages: [...state.messages, instructionMessage],
      prompt: currentState.prompt,
      analyzeResult: currentState.analyzeResult,
    ));
  }

  /// Manually proceed to JSON input without opening external tool
  void proceedToJsonInput() {
    final currentState = state;
    if (currentState is! ChatFlowPromptReady) return;

    // Add instruction message
    final instructionMessage = ChatMessage.bot(
      text: t.chat.pasteJsonPrompt,
      timestamp: DateTime.now(),
    );

    emit(ChatFlowJsonInput(
      messages: [...state.messages, instructionMessage],
      prompt: currentState.prompt,
      analyzeResult: currentState.analyzeResult,
    ));
  }

  /// Submit and validate AI JSON response
  Future<void> submitJson(String jsonInput) async {
    _log.info(
      'chatflow_json_submitted',
      'User submitted JSON',
      layer: AppLayer.presentation,
    );

    final currentState = state;
    if (currentState is! ChatFlowJsonInput) return;

    // Add user message (truncated preview)
    final preview = jsonInput.length > 100
        ? '${jsonInput.substring(0, 100)}...'
        : jsonInput;
    final userMessage = ChatMessage.user(
      text: preview,
      timestamp: DateTime.now(),
    );
    final messagesWithUser = [...state.messages, userMessage];

    // Emit validating state
    emit(ChatFlowValidating(
      messages: messagesWithUser,
      jsonInput: jsonInput,
    ));

    // Add loading message
    final loadingMessage = ChatMessage.bot(
      text: t.chat.validating,
      timestamp: DateTime.now(),
      type: MessageType.loading,
    );
    emit(ChatFlowValidating(
      messages: [...messagesWithUser, loadingMessage],
      jsonInput: jsonInput,
    ));

    // Validate JSON
    final result = _validateAndParseJsonUseCase(jsonInput);

    result.fold(
      (failure) {
        _log.error(
          'chatflow_validation_failed',
          failure.message,
          layer: AppLayer.presentation,
        );

        // Remove loading message and add error
        final messagesWithoutLoading = state.messages
            .where((m) => m.type != MessageType.loading)
            .toList();
        final errorMessage = ChatMessage.bot(
          text: '${t.chat.validationFailed}\n${failure.message}',
          timestamp: DateTime.now(),
          type: MessageType.error,
        );

        emit(ChatFlowError(
          messages: [...messagesWithoutLoading, errorMessage],
          errorMessage: failure.message,
          recoverableStep: ChatStep.jsonInput,
        ));
      },
      (aiPayload) {
        _log.info(
          'chatflow_validation_success',
          'JSON validation successful',
          layer: AppLayer.presentation,
          data: {'momentsCount': (aiPayload['moments'] as List?)?.length ?? 0},
        );

        // Parse moments from payload
        final moments = _parseMoments(aiPayload);

        // Remove loading message and add success message
        final messagesWithoutLoading = state.messages
            .where((m) => m.type != MessageType.loading)
            .toList();
        // Use string interpolation for the count
        final successText = t.chat.validationSuccess.replaceAll('{count}', moments.length.toString());
        final successMessage = ChatMessage.bot(
          text: successText,
          timestamp: DateTime.now(),
        );

        emit(ChatFlowCompleted(
          messages: [...messagesWithoutLoading, successMessage],
          aiPayload: aiPayload,
          moments: moments,
          youtubeUrl: currentState.analyzeResult.video.sourceUrl,
        ));
      },
    );
  }

  /// Retry from error state
  void retry() {
    final currentState = state;
    if (currentState is! ChatFlowError) return;

    _log.info(
      'chatflow_retry',
      'User requested retry',
      layer: AppLayer.presentation,
      data: {
        'recoverableStep': currentState.recoverableStep.name,
        'hasData': currentState.recoverableData != null,
      },
    );

    // Remove error messages and return to recoverable step
    final messagesWithoutErrors = state.messages
        .where((m) => m.type != MessageType.error)
        .toList();

    switch (currentState.recoverableStep) {
      case ChatStep.welcome:
        emit(ChatFlowInitial(messages: messagesWithoutErrors));
      case ChatStep.languageSelection:
        // Recover to language selection with URL
        final url = currentState.recoverableData?['url'] as String?;
        if (url != null) {
          emit(ChatFlowLanguageSelection(
            messages: messagesWithoutErrors,
            url: url,
          ));
        } else {
          emit(ChatFlowInitial(messages: messagesWithoutErrors));
        }
      case ChatStep.jsonInput:
        // Try to recover to JSON input state if possible
        final previousState = state;
        if (previousState is ChatFlowJsonInput) {
          emit(ChatFlowJsonInput(
            messages: messagesWithoutErrors,
            prompt: previousState.prompt,
            analyzeResult: previousState.analyzeResult,
          ));
        } else {
          emit(ChatFlowInitial(messages: messagesWithoutErrors));
        }
      default:
        emit(ChatFlowInitial(messages: messagesWithoutErrors));
    }
  }

  /// Reset flow to initial state
  void reset() {
    _log.info(
      'chatflow_reset',
      'Chat flow reset',
      layer: AppLayer.presentation,
    );

    emit(_initialState());
  }

  /// Map failure to user-friendly message
  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => t.chat.errorNetwork,
      ValidationFailure() => t.chat.errorInvalidUrl,
      ServerFailure(:final code) =>
        code == 'NO_TRANSCRIPT'
            ? t.chat.errorNoTranscript
            : failure.message,
      UnexpectedFailure() => t.chat.errorNetwork,
    };
  }

  /// Get language label from code
  String _getLanguageLabel(String language) {
    return switch (language) {
      'en' => t.analyze.languages.en,
      'uk' => t.analyze.languages.uk,
      'uk_18' => t.analyze.languages.uk_18,
      'ru' => t.analyze.languages.ru,
      _ => t.analyze.languages.uk,
    };
  }

  /// Parse moments from AI payload
  List<FunnyMoment> _parseMoments(Map<String, dynamic> payload) {
    final momentsList = payload['moments'] as List<dynamic>?;
    if (momentsList == null) return [];

    return momentsList.map((m) {
      final map = m as Map<String, dynamic>;
      return FunnyMoment(
        id: map['id'] as String,
        startSec: (map['startSec'] as num).toDouble(),
        endSec: (map['endSec'] as num).toDouble(),
        caption: map['caption'] as String,
        postText: map['postText'] as String,
        reason: map['reason'] as String,
      );
    }).toList();
  }
}
