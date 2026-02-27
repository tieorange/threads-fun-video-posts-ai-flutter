# Technical Specification: Chatbot-Style UI Flow

## Overview
This specification defines the implementation of a chatbot-style UI flow that replaces the first three screens (AnalyzeInputPage, GeminiStepPage, JSON paste) of the existing app with a conversational interface.

## Architecture Compliance
- **Pattern**: Clean Architecture (Domain ← Data → Presentation)
- **State Management**: Dart 3 sealed classes (not equatable)
- **Navigation**: go_router
- **DI**: get_it with factory registration for Cubits
- **Localization**: slang (strings.i18n.json)
- **Material Design**: Material 3 only

---

## 1. State Design: ChatFlowState Sealed Class

### File Location
`lib/features/video_processing/presentation/cubits/chat_flow_state.dart`

### Sealed Class Hierarchy

```dart
part of 'chat_flow_cubit.dart';

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
  bool get isInputEnabled => currentStep != ChatStep.processing && 
                             currentStep != ChatStep.analyzing;
}

/// Step enum to track flow progression
enum ChatStep {
  welcome,      // Initial welcome, waiting for URL
  analyzing,    // URL submitted, calling analyze API
  metadata,     // Showing video metadata, waiting for language selection
  buildingPrompt, // Language selected, building prompt
  promptReady,  // Showing AI prompt with copy/open buttons
  jsonInput,    // Waiting for user to paste AI JSON response
  validating,   // Validating JSON
  completed,    // Flow complete, ready to navigate
}

/// Message type for UI styling
enum MessageType {
  text,           // Regular text message
  videoMetadata,  // Video metadata card
  aiPrompt,       // AI prompt card
  error,          // Error message
  loading,        // Loading indicator
}

/// Initial state - bot welcomes user
final class ChatFlowInitial extends ChatFlowState {
  const ChatFlowInitial({
    required super.messages,
    super.errorMessage,
  }) : super(currentStep: ChatStep.welcome);
}

/// Analyzing state - shows loading indicator in chat
final class ChatFlowAnalyzing extends ChatFlowState {
  const ChatFlowAnalyzing({
    required super.messages,
    required this.url,
  }) : super(currentStep: ChatStep.analyzing);

  final String url;
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
  }) : super(currentStep: ChatStep.welcome);

  /// The step to return to for retry
  final ChatStep recoverableStep;
}
```

---

## 2. Cubit Interface: ChatFlowCubit

### File Location
`lib/features/video_processing/presentation/cubits/chat_flow_cubit.dart`

### Dependencies
```dart
class ChatFlowCubit extends Cubit<ChatFlowState> {
  ChatFlowCubit({
    required AnalyzeVideoUseCase analyzeVideoUseCase,
    required BuildAiPromptUseCase buildAiPromptUseCase,
    required ValidateAndParseJsonUseCase validateAndParseJsonUseCase,
    required AppLogger log,
    required ClipboardService clipboard,
    required LaunchService launchService,
  })  : _analyzeVideoUseCase = analyzeVideoUseCase,
        _buildAiPromptUseCase = buildAiPromptUseCase,
        _validateAndParseJsonUseCase = validateAndParseJsonUseCase,
        _log = log,
        _clipboard = clipboard,
        _launchService = launchService,
        super(_initialState());

  final AnalyzeVideoUseCase _analyzeVideoUseCase;
  final BuildAiPromptUseCase _buildAiPromptUseCase;
  final ValidateAndParseJsonUseCase _validateAndParseJsonUseCase;
  final AppLogger _log;
  final ClipboardService _clipboard;
  final LaunchService _launchService;
}
```

### Public Methods

#### `Future<void> submitUrl(String url)`
- **Purpose**: Submit YouTube URL for analysis
- **Flow**: 
  1. Add user message with URL
  2. Emit `ChatFlowAnalyzing`
  3. Call `AnalyzeVideoUseCase`
  4. On success: emit `ChatFlowMetadata` with video card
  5. On failure: emit `ChatFlowError` with retry option

#### `void selectLanguage(String language)`
- **Purpose**: Select language profile and build AI prompt
- **Flow**:
  1. Add user message with language selection
  2. Emit `ChatFlowBuildingPrompt`
  3. Create `AnalyzeResult` with selected language
  4. Call `BuildAiPromptUseCase`
  5. Emit `ChatFlowPromptReady` with prompt card

#### `Future<void> copyPrompt()`
- **Purpose**: Copy AI prompt to clipboard
- **Flow**:
  1. Check state is `ChatFlowPromptReady`
  2. Copy prompt via `ClipboardService`
  3. Add system message confirming copy
  4. Emit updated state with confirmation

#### `Future<void> openAiTool(String toolUrl)`
- **Purpose**: Open external AI tool (ChatGPT, Claude, etc.)
- **Flow**:
  1. Check state is `ChatFlowPromptReady`
  2. Copy prompt first
  3. Open URL via `LaunchService`
  4. Add system message with instructions
  5. Transition to `ChatFlowJsonInput`

#### `void proceedToJsonInput()`
- **Purpose**: Manually proceed to JSON input without opening external tool
- **Flow**: Transition from `ChatFlowPromptReady` to `ChatFlowJsonInput`

#### `Future<void> submitJson(String jsonInput)`
- **Purpose**: Submit and validate AI JSON response
- **Flow**:
  1. Add user message (truncated JSON preview)
  2. Emit `ChatFlowValidating`
  3. Call `ValidateAndParseJsonUseCase`
  4. On success: emit `ChatFlowCompleted`
  5. On failure: emit `ChatFlowError` with retry to jsonInput

#### `void retry()`
- **Purpose**: Retry from error state
- **Flow**: Return to `recoverableStep` from error state

#### `void reset()`
- **Purpose**: Reset flow to initial state
- **Flow**: Clear all messages, emit `ChatFlowInitial`

#### `void addBotMessage(String text, {MessageType type = MessageType.text})`
- **Purpose**: Add a bot message to conversation
- **Used internally** by other methods

#### `void addUserMessage(String text)`
- **Purpose**: Add a user message to conversation
- **Used internally** by other methods

### State Management Helpers

```dart
/// Create initial state with welcome message
static ChatFlowState _initialState() {
  return ChatFlowInitial(
    messages: [
      ChatMessage.bot(
        text: t.chat.welcomeMessage, // from i18n
        timestamp: DateTime.now(),
      ),
    ],
  );
}

/// Immutable message addition helper
List<ChatMessage> _addMessage(ChatMessage message) {
  return [...state.messages, message];
}
```

---

## 3. Entity Design: ChatMessage

### File Location
`lib/features/video_processing/domain/entities/chat_message.dart`

### Entity Definition

```dart
import 'package:flutter/material.dart';

/// Entity representing a single chat message
@immutable
class ChatMessage {
  const ChatMessage._({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.metadata,
  });

  /// Factory for bot messages
  factory ChatMessage.bot({
    required String text,
    required DateTime timestamp,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage._(
      id: _generateId(),
      text: text,
      isUser: false,
      timestamp: timestamp,
      type: type,
      metadata: metadata,
    );
  }

  /// Factory for user messages
  factory ChatMessage.user({
    required String text,
    required DateTime timestamp,
  }) {
    return ChatMessage._(
      id: _generateId(),
      text: text,
      isUser: true,
      timestamp: timestamp,
      type: MessageType.text,
    );
  }

  /// Unique message ID
  final String id;
  
  /// Message text content
  final String text;
  
  /// true = user message, false = bot message
  final bool isUser;
  
  /// Message timestamp
  final DateTime timestamp;
  
  /// Message type for UI rendering
  final MessageType type;
  
  /// Optional metadata for special message types
  /// Example: video metadata, prompt data
  final Map<String, dynamic>? metadata;

  /// ID generator
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }
  
  static int _counter = 0;
}

/// Message type enum (defined in state file but referenced here)
enum MessageType {
  text,
  videoMetadata,
  aiPrompt,
  error,
  loading,
}
```

### Entity Characteristics
- **Immutable**: All fields are final
- **Factory constructors**: Separate factories for bot/user messages
- **Auto-generated ID**: Prevents key collision in ListView
- **Metadata support**: Flexible map for special message data

---

## 4. Widget Breakdown

### 4.1 ChatFlowPage

**File**: `lib/features/video_processing/presentation/pages/chat_flow_page.dart`

**Purpose**: Main chat interface container

**Props**:
```dart
class ChatFlowPage extends StatelessWidget {
  const ChatFlowPage({super.key});
}
```

**Structure**:
```
Scaffold
├── AppBar (title: t.chat.title, actions: [reset button])
├── BlocConsumer<ChatFlowCubit, ChatFlowState>
│   └── Column
│       ├── Expanded
│       │   └── ListView.builder
│       │       └── ChatMessageBubble (for each message)
│       └── ChatInputArea (bottom, based on current step)
```

**Key Behaviors**:
- Listen for `ChatFlowCompleted` state to navigate to MomentsReviewPage
- Auto-scroll to bottom on new messages
- Show reset confirmation dialog

---

### 4.2 ChatMessageBubble

**File**: `lib/features/video_processing/presentation/widgets/chat_message_bubble.dart`

**Purpose**: Renders individual chat messages with appropriate styling

**Props**:
```dart
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.state, // Current ChatFlowState for context
  });

  final ChatMessage message;
  final ChatFlowState state;
}
```

**Rendering Logic**:
| Message Type | Widget Returned |
|--------------|-----------------|
| `MessageType.text` (user) | Right-aligned bubble, primary color |
| `MessageType.text` (bot) | Left-aligned bubble, surface color |
| `MessageType.videoMetadata` | `ChatVideoMetadataCard` |
| `MessageType.aiPrompt` | `ChatPromptCard` |
| `MessageType.error` | Left-aligned, error color |
| `MessageType.loading` | Typing indicator animation |

**Styling**:
- User: `Alignment.centerRight`, `ColorScheme.primary` container
- Bot: `Alignment.centerLeft`, `ColorScheme.surfaceContainerHighest` container
- Max width: 80% of screen
- Border radius: Material 3 standard (12px)

---

### 4.3 ChatVideoMetadataCard

**File**: `lib/features/video_processing/presentation/widgets/chat_video_metadata_card.dart`

**Purpose**: Display video metadata with language selection

**Props**:
```dart
class ChatVideoMetadataCard extends StatelessWidget {
  const ChatVideoMetadataCard({
    super.key,
    required this.metadata,
    required this.onLanguageSelected,
    this.selectedLanguage,
  });

  final VideoMetadata metadata;
  final ValueChanged<String> onLanguageSelected;
  final String? selectedLanguage;
}
```

**Structure**:
```
Card
├── Column
│   ├── Row (thumbnail placeholder + title/duration)
│   │   ├── Icon(Icons.play_circle_outline, size: 64)
│   │   └── Column
│   │       ├── Text(title, style: titleMedium)
│   │       └── Text(duration, style: bodySmall)
│   ├── Divider
│   └── Wrap (language chips)
│       ├── ChoiceChip(label: t.analyze.languages.en, onSelected: ...)
│       ├── ChoiceChip(label: t.analyze.languages.uk, onSelected: ...)
│       ├── ChoiceChip(label: t.analyze.languages.uk_18, onSelected: ...)
│       └── ChoiceChip(label: t.analyze.languages.ru, onSelected: ...)
```

**Behavior**:
- Only one language selectable at a time
- Calls `onLanguageSelected` immediately on tap
- Shows checkmark for selected language

---

### 4.4 ChatPromptCard

**File**: `lib/features/video_processing/presentation/widgets/chat_prompt_card.dart`

**Purpose**: Display AI prompt with copy and open actions

**Props**:
```dart
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
}
```

**Structure**:
```
Card
├── Column
│   ├── ListTile
│   │   ├── Icon(Icons.auto_fix_high)
│   │   ├── title: Text(t.chat.aiPromptTitle)
│   │   └── subtitle: Text(t.chat.aiPromptSubtitle)
│   ├── Container (prompt preview, max 200px height, scrollable)
│   │   └── Text(prompt, style: monoTextStyle)
│   └── ButtonBar
│       ├── FilledButton.icon(
│       │   icon: Icons.copy,
│       │   label: t.chat.copyPrompt,
│       │   onPressed: onCopy,
│       │ )
│       ├── OutlinedButton.icon(
│       │   icon: Icons.open_in_new,
│       │   label: t.chat.openAiTool,
│       │   onPressed: onOpenAi,
│       │ )
│       └── TextButton(
│           label: t.chat.iHaveResponse,
│           onPressed: onProceed,
│       )
```

---

### 4.5 ChatInputArea

**File**: `lib/features/video_processing/presentation/widgets/chat_input_area.dart`

**Purpose**: Dynamic input area that adapts to current flow step

**Props**:
```dart
class ChatInputArea extends StatelessWidget {
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
}
```

**Step-Based Rendering**:

| Step | Input Widget |
|------|--------------|
| `welcome` | URL input with TextField + send button |
| `analyzing` | Disabled input with loading indicator |
| `metadata` | Hidden (user must select language from card) |
| `buildingPrompt` | Hidden (transient state) |
| `promptReady` | Hidden (user uses card buttons) |
| `jsonInput` | Multi-line JSON input with validate button |
| `validating` | Disabled input with loading indicator |
| `completed` | Hidden (auto-navigates) |
| `error` | Context-dependent input based on recoverableStep |

**URL Input Mode**:
```
Container
├── TextField(
│   controller: _urlController,
│   decoration: InputDecoration(
│     hintText: t.analyze.urlHint,
│     prefixIcon: Icon(Icons.link),
│   ),
│   keyboardType: TextInputType.url,
│ )
└── IconButton(
    icon: Icon(Icons.send),
    onPressed: _submitUrl,
)
```

**JSON Input Mode**:
```
Container
├── TextField(
│   controller: _jsonController,
│   maxLines: 5,
│   decoration: InputDecoration(
│     hintText: t.paste.hint,
│     alignLabelWithHint: true,
│   ),
│ )
├── if (errorMessage != null) 
│   Text(errorMessage, style: errorStyle)
└── FilledButton(
    child: Text(t.paste.validate),
    onPressed: _submitJson,
)
```

---

## 5. Navigation Strategy

### Route Registration

**Update**: `lib/core/utils/router.dart`

```dart
// Add to initCubits()
late final ChatFlowCubit _chatFlowCubit;

void initCubits() {
  // ... existing cubits
  _chatFlowCubit = sl<ChatFlowCubit>();
}

// Update _withProviders
Widget _withProviders(Widget child) => MultiBlocProvider(
  providers: [
    // ... existing providers
    BlocProvider.value(value: _chatFlowCubit),
  ],
  child: child,
);

// Replace existing routes
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) {
        _logRoute('/');
        return _withProviders(const ChatFlowPage());
      },
    ),
    // Remove: '/prompt' route (replaced by chat flow)
    GoRoute(
      path: '/review',
      builder: (context, state) {
        _logRoute('/review');
        
        // Primary: Get data from ChatFlowCubit completed state
        final chatState = _chatFlowCubit.state;
        if (chatState is ChatFlowCompleted) {
          return _withProviders(MomentsReviewPage(
            youtubeUrl: chatState.youtubeUrl,
            aiPayload: chatState.aiPayload,
          ));
        }
        
        // Fallback: Try extra params (for direct navigation)
        final extra = state.extra as Map<String, dynamic>?;
        if (extra != null) {
          return _withProviders(MomentsReviewPage(
            youtubeUrl: extra['youtubeUrl'] as String,
            aiPayload: extra['aiPayload'] as Map<String, dynamic>,
          ));
        }
        
        // Guard: Missing data, redirect to start
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/');
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
    // ... existing /processing and /results routes
  ],
);
```

### Navigation from ChatFlowPage

```dart
class ChatFlowPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatFlowCubit, ChatFlowState>(
      listener: (context, state) {
        if (state is ChatFlowCompleted) {
          context.go('/review');
        }
      },
      // ... builder
    );
  }
}
```

### Back Navigation Handling

- **From Review to Chat**: Supported via browser back button
- **From Chat to Review**: Blocked (flow must complete again)
- **Data persistence**: ChatFlowCubit maintains state during session

---

## 6. DI Configuration

### Update: `lib/core/di/injection.dart`

```dart
// Add imports
import '../../features/video_processing/presentation/cubits/chat_flow_cubit.dart';

void setupDependencies() {
  // ... existing registrations

  // ChatFlowCubit - factory (new instance per app start)
  sl.registerFactory(() => ChatFlowCubit(
    analyzeVideoUseCase: sl<AnalyzeVideoUseCase>(),
    buildAiPromptUseCase: sl<BuildAiPromptUseCase>(),
    validateAndParseJsonUseCase: sl<ValidateAndParseJsonUseCase>(),
    log: sl<AppLogger>(),
    clipboard: sl<ClipboardService>(),
    launchService: sl<LaunchService>(),
  ));
}
```

### Required Imports in Cubit File

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/video_metadata.dart';
import '../../domain/entities/analyze_result.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/usecases/analyze_video_usecase.dart';
import '../../domain/usecases/build_ai_prompt_usecase.dart';
import '../../domain/usecases/validate_and_parse_json_usecase.dart';
import '../../../../../core/failures/failure.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';
import '../../../../../core/utils/clipboard_service.dart';
import '../../../../../core/utils/launch_service.dart';
import '../../../../../i18n/strings.g.dart';

part 'chat_flow_state.dart';
```

---

## 7. i18n String Keys

### Update: `lib/i18n/strings.i18n.json`

Add to the root object:

```json
{
  "common": { /* existing */ },
  "analyze": { /* existing */ },
  "chat": {
    "title": "Funny Threads AI",
    "welcomeMessage": "Привіт! Я допоможу перетворити YouTube відео на віральні кліпи. Надішліть мені посилання на відео.",
    "thinking": "Думаю...",
    "analyzingVideo": "Аналізую відео...",
    "videoFound": "Знайшов відео! Виберіть мову для генерації:",
    "buildingPrompt": "Готую AI промпт...",
    "promptReady": "Промпт готовий! Скопіюйте його та відкрийте ваш AI-інструмент.",
    "promptCopied": "Промпт скопійовано!",
    "pasteJsonPrompt": "Вставте JSON відповідь від AI:",
    "validating": "Перевіряю відповідь...",
    "validationSuccess": "Чудово! Знайдено $count моментів. Переходжу до огляду...",
    "validationFailed": "Помилка валідації. Перевірте формат JSON.",
    "retry": "Спробувати ще раз",
    "resetConfirm": "Почати спочатку? Весь прогрес буде втрачено.",
    "aiPromptTitle": "AI Промпт",
    "aiPromptSubtitle": "Скопіюйте та вставте в ChatGPT, Claude або Gemini",
    "copyPrompt": "Копіювати",
    "openAiTool": "Відкрити AI",
    "iHaveResponse": "Вже маю відповідь",
    "send": "Надіслати",
    "urlHint": "https://youtube.com/watch?v=...",
    "jsonHint": "Вставте JSON відповідь тут...",
    "errorNetwork": "Помилка мережі. Перевірте з'єднання.",
    "errorInvalidUrl": "Невірне посилання на YouTube.",
    "errorNoTranscript": "Субтитри не знайдено. Спробуйте інше відео."
  }
}
```

### Key Mapping

| UI Element | i18n Key |
|------------|----------|
| Page title | `t.chat.title` |
| Welcome bot message | `t.chat.welcomeMessage` |
| Analyzing indicator | `t.chat.analyzingVideo` |
| Metadata card header | `t.chat.videoFound` |
| Prompt card title | `t.chat.aiPromptTitle` |
| Prompt card subtitle | `t.chat.aiPromptSubtitle` |
| Copy button | `t.chat.copyPrompt` |
| Open AI button | `t.chat.openAiTool` |
| Proceed button | `t.chat.iHaveResponse` |
| JSON input hint | `t.chat.jsonHint` |
| Send button | `t.chat.send` |

---

## 8. State Transitions Diagram

```
                              CHAT FLOW STATE TRANSITIONS
                              ==========================

┌─────────────────┐
│  ChatFlowInitial│  ← Entry point, welcome message displayed
│   (welcome)     │
└────────┬────────┘
         │ submitUrl(url)
         ▼
┌─────────────────┐     Failure (network/invalid)
│ ChatFlowAnalyzing│ ←──────────────────────────────────┐
│  (analyzing)     │                                    │
└────────┬────────┘                                    │
         │ Success                                      │
         ▼                                              │
┌─────────────────┐                                     │
│ ChatFlowMetadata│  Language selection UI              │
│  (metadata)     │                                     │
└────────┬────────┘                                     │
         │ selectLanguage(lang)                         │
         ▼                                              │
┌─────────────────────┐                                 │
│ ChatFlowBuildingPrompt│ Transient loading state       │
│  (buildingPrompt)   │                                 │
└────────┬────────────┘                                 │
         │ Prompt built                                 │
         ▼                                              │
┌───────────────────┐                                   │
│ ChatFlowPromptReady│ ← AI prompt card displayed       │
│  (promptReady)    │                                   │
└────────┬──────────┘                                   │
         │                                              │
         ├─ copyPrompt() ──→ Shows confirmation        │
         │                                              │
         ├─ openAiTool() ──→ Opens external, then...   │
         │                    proceedToJsonInput()      │
         │                                              │
         └─ proceedToJsonInput() ───────────────────────┘
                          │
                          ▼
┌───────────────────┐
│ ChatFlowJsonInput │  ← JSON input field shown
│  (jsonInput)      │
└────────┬──────────┘
         │ submitJson(json)
         ▼
┌───────────────────┐     Failure (validation error)
│ ChatFlowValidating│ ←──────────────────────────────────┐
│  (validating)     │                                    │
└────────┬──────────┘                                    │
         │ Success                                       │
         ▼                                               │
┌───────────────────┐                                    │
│ ChatFlowCompleted │  → Auto-navigates to /review       │
│  (completed)      │                                    │
└───────────────────┘                                    │
                                                         │
┌───────────────────┐                                    │
│  ChatFlowError    │  ← Any recoverable error           │
│    (error)        │  → retry() returns to              │
│ recoverableStep   │    recoverableStep                 │
└───────────────────┘────────────────────────────────────┘


LEGEND:
────────
┌──┐ = State
──→ = Transition (method call)
│  = Vertical flow (sequential)
├─ = Branching options
```

---

## Implementation Checklist

### Domain Layer
- [ ] Create `ChatMessage` entity
- [ ] No repository changes needed (reuses existing)

### Data Layer  
- [ ] No datasource changes needed

### Presentation Layer
- [ ] Create `chat_flow_state.dart` (sealed classes)
- [ ] Create `chat_flow_cubit.dart`
- [ ] Create `ChatFlowPage`
- [ ] Create `ChatMessageBubble`
- [ ] Create `ChatVideoMetadataCard`
- [ ] Create `ChatPromptCard`
- [ ] Create `ChatInputArea`

### Infrastructure Layer
- [ ] Register `ChatFlowCubit` in `injection.dart`
- [ ] Update `router.dart` to use `ChatFlowPage` as root
- [ ] Add i18n keys to `strings.i18n.json`

### Testing
- [ ] Unit tests for `ChatFlowCubit` state transitions
- [ ] Widget tests for `ChatMessageBubble` rendering
- [ ] Integration test for complete flow

---

## Dependencies Summary

### No New Dependencies Required
All required packages are already in `pubspec.yaml`:
- `flutter_bloc` - State management
- `fpdart` - Either type
- `go_router` - Navigation
- `get_it` - DI
- `slang` - i18n

---

## Migration Notes

### Deprecated Files (keep for reference):
- `analyze_input_page.dart` - Replace with `ChatFlowPage`
- `gemini_step_page.dart` - Remove, functionality merged into chat
- `analyze_cubit.dart` - Logic absorbed into `ChatFlowCubit`
- `analyze_state.dart` - Replaced by `ChatFlowState`
- `prompt_cubit.dart` - Logic absorbed into `ChatFlowCubit`
- `prompt_state.dart` - Replaced by `ChatFlowState`
- `json_paste_cubit.dart` - Logic absorbed into `ChatFlowCubit`
- `json_paste_state.dart` - Replaced by `ChatFlowState`

### Files to Keep:
- `moments_review_page.dart` - Unchanged, receives data from ChatFlow
- `processing_page.dart` - Unchanged
- `results_page.dart` - Unchanged
- All use cases - Reused as-is
- All repositories - Reused as-is
- All entities except new `ChatMessage`

---

End of Technical Specification
