part of 'chat_flow_cubit.dart';

/// Step enum to track flow progression
enum ChatStep {
  welcome, // Initial welcome, waiting for URL
  languageSelection, // URL submitted, waiting for language selection
  analyzing, // Language selected, calling analyze API
  metadata, // Showing video metadata
  buildingPrompt, // Building AI prompt
  promptReady, // Showing AI prompt with copy/open buttons
  jsonInput, // Waiting for user to paste AI JSON response
  validating, // Validating JSON
  completed, // Flow complete, ready to navigate
}

/// Base sealed class for all chat flow states
sealed class ChatFlowState {
  const ChatFlowState({
    required this.messages,
    required this.currentStep,
    this.errorMessage,
  });

  /// Conversation history - immutable list
  final List<ChatMessage> messages;

  /// Current step in the flow
  final ChatStep currentStep;

  /// Optional error message for error states
  final String? errorMessage;

  /// Helper to check if input should be enabled
  bool get isInputEnabled =>
      currentStep != ChatStep.analyzing &&
      currentStep != ChatStep.buildingPrompt &&
      currentStep != ChatStep.validating;
}

/// Initial state - bot welcomes user
final class ChatFlowInitial extends ChatFlowState {
  const ChatFlowInitial({
    required super.messages,
    super.errorMessage,
  }) : super(currentStep: ChatStep.welcome);
}

/// Language selection state - waiting for user to select language
final class ChatFlowLanguageSelection extends ChatFlowState {
  const ChatFlowLanguageSelection({
    required super.messages,
    required this.url,
  }) : super(currentStep: ChatStep.languageSelection);

  final String url;
}

/// Analyzing state - shows loading indicator in chat
final class ChatFlowAnalyzing extends ChatFlowState {
  const ChatFlowAnalyzing({
    required super.messages,
    required this.url,
    required this.language,
  }) : super(currentStep: ChatStep.analyzing);

  final String url;
  final String language;
}

/// Metadata displayed state - waiting for language selection
final class ChatFlowMetadata extends ChatFlowState {
  const ChatFlowMetadata({
    required super.messages,
    required this.videoMetadata,
    required this.analyzeResult,
  }) : super(currentStep: ChatStep.metadata);

  final VideoMetadata videoMetadata;
  final AnalyzeResult analyzeResult;
}

/// Prompt building state - transient loading state
final class ChatFlowBuildingPrompt extends ChatFlowState {
  const ChatFlowBuildingPrompt({
    required super.messages,
    required this.language,
  }) : super(currentStep: ChatStep.buildingPrompt);

  final String language;
}

/// Prompt ready state - AI prompt displayed with action buttons
final class ChatFlowPromptReady extends ChatFlowState {
  const ChatFlowPromptReady({
    required super.messages,
    required this.prompt,
    required this.analyzeResult,
  }) : super(currentStep: ChatStep.promptReady);

  final String prompt;
  final AnalyzeResult analyzeResult;
}

/// JSON input state - waiting for user to paste AI response
final class ChatFlowJsonInput extends ChatFlowState {
  const ChatFlowJsonInput({
    required super.messages,
    required this.prompt,
    required this.analyzeResult,
  }) : super(currentStep: ChatStep.jsonInput);

  final String prompt;
  final AnalyzeResult analyzeResult;
}

/// Validating state - JSON validation in progress
final class ChatFlowValidating extends ChatFlowState {
  const ChatFlowValidating({
    required super.messages,
    required this.jsonInput,
  }) : super(currentStep: ChatStep.validating);

  final String jsonInput;
}

/// Completed state - validation successful, ready to navigate
final class ChatFlowCompleted extends ChatFlowState {
  const ChatFlowCompleted({
    required super.messages,
    required this.aiPayload,
    required this.moments,
    required this.youtubeUrl,
  }) : super(currentStep: ChatStep.completed);

  final Map<String, dynamic> aiPayload;
  final List<FunnyMoment> moments;
  final String youtubeUrl;
}

/// Error state - recoverable error with retry option
final class ChatFlowError extends ChatFlowState {
  const ChatFlowError({
    required super.messages,
    required super.errorMessage,
    required this.recoverableStep,
    this.recoverableData,
  }) : super(currentStep: ChatStep.welcome);

  /// The step to return to for retry
  final ChatStep recoverableStep;

  /// Optional data needed to recover (e.g., URL for language selection retry)
  final Map<String, dynamic>? recoverableData;
}
