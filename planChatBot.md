# Chatbot UI Implementation Plan - COMPLETE ✅

## Status: ✅ Fully Implemented

> **Last Updated**: 2026-02-27
> **Implementation Status**: Complete ✅
> **Build Status**: Clean (0 Errors)

---

## Overview

The chatbot-style UI flow has been fully implemented and replaces the initial frontend screens. The conversational interface guides users through video analysis while maintaining strict compliance with `AGENTS.md` constraints.

### Key Correction from Original Plan

**Original Issue**: Language selection happened AFTER analyze API call, but the API requires language as a parameter.

**Corrected Flow**: Language selection happens BEFORE analyze API call.

---

## User Flow (Implemented)

### Step 1: Welcome & URL Input
- **Bot**: Displays welcome message
- **User**: Pastes YouTube URL
- **System**: Shows URL as user message, shows language selection chips

### Step 2: Language Selection  
- **Bot**: "What language should we use for the analysis?"
- **UI**: Language chips/buttons (en, uk, uk_18, ru)
- **User**: Taps preferred language
- **System**: Shows selection, calls `analyze_video_usecase(url, language)`

### Step 3: Analyzing & Metadata Display
- **Bot**: Shows **typing indicator** animation during analysis
- **System**: On success, displays video metadata card (title, duration)
- **Bot**: "Great! I've analyzed the video. Now I'll prepare the AI prompt..."

### Step 4: Prompt Generation
- **System**: Calls `build_ai_prompt_usecase`
- **Bot**: Displays AI prompt in a card
- **Action Buttons**: "Copy Prompt", "Open AI Tool"

### Step 5: AI Interaction & JSON Input
- **User**: Copies prompt, opens AI tool, pastes response
- **Bot**: "Please paste the AI response below"
- **User**: Pastes JSON
- **System**: Validates with `validate_and_parse_json_usecase`

### Step 6: Success & Navigation
- **Bot**: "✅ Found {N} funny moments!"
- **System**: Auto-navigates to `MomentsReviewPage`

---

## Issues Fixed (All Complete)

### 🔴 Critical Issues - FIXED ✅

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 1 | **Hardcoded language** - Uses 'uk' by default | `chat_flow_cubit.dart` | ✅ Fixed - Language selection before analyze |
| 2 | **Wrong flow order** - Analyze called before language selection | `submitUrl()` method | ✅ Fixed - Reorder: URL → Language → Analyze |

### 🟡 Code Quality Issues - FIXED ✅

| # | Issue | Location | Status |
|---|-------|----------|--------|
| 3 | **Cubit too thick** - Message building logic in Cubit | Multiple methods | ✅ Fixed - Cubit manages state only |
| 4 | **Unused import** | `chat_flow_cubit.dart` | ✅ Fixed - Removed `package:web/web.dart` |
| 5 | **Retry logic fragile** - Doesn't preserve state data properly | `retry()` method | ✅ Fixed - Store recovery data in error state |
| 6 | **Direct window.open** - Not abstracted | `openAiTool()` | ✅ Fixed - Uses `LaunchService` from core |

### 🟢 Improvements - IMPLEMENTED ✅

| # | Improvement | Status |
|---|-------------|--------|
| 7 | Add typing indicator animation | ✅ Implemented - `ChatTypingIndicator` widget |
| 8 | Add message timestamps on hover | ⏸️ Deferred - Not critical for MVP |
| 9 | Support keyboard shortcuts (Enter to send) | ⏸️ Deferred - Not critical for MVP |
| 10 | Add message persistence across refresh | ✅ Implemented - `ChatLocalStorageDatasource` |

---

## Technical Implementation

### State Management

```dart
// Sealed class hierarchy (Dart 3)
sealed class ChatFlowState {
  final List<ChatMessage> messages;
  final ChatStep currentStep;
  final String? errorMessage;
}

final class ChatFlowInitial extends ChatFlowState { ... }
final class ChatFlowLanguageSelection extends ChatFlowState { ... }  // ✅ NEW
final class ChatFlowAnalyzing extends ChatFlowState { ... }
final class ChatFlowMetadata extends ChatFlowState { ... }
final class ChatFlowPromptReady extends ChatFlowState { ... }
final class ChatFlowJsonInput extends ChatFlowState { ... }
final class ChatFlowValidating extends ChatFlowState { ... }
final class ChatFlowCompleted extends ChatFlowState { ... }
final class ChatFlowError extends ChatFlowState { ... }
```

### Cubit Interface

```dart
class ChatFlowCubit extends Cubit<ChatFlowState> {
  // Step 1
  void submitUrl(String url);
  
  // Step 2 - Language selection then analyze
  Future<void> selectLanguage(String language);
  
  // Step 3 - Build prompt after metadata shown
  void buildPrompt();
  
  // Step 4
  void copyPrompt();
  void openAiTool(String toolUrl);
  
  // Step 5
  Future<void> submitJson(String jsonInput);
  
  // Utilities
  void retry();
  void reset();
}
```

### File Structure

```
lib/features/video_processing/
├── domain/
│   ├── entities/
│   │   └── chat_message.dart          ✅ Immutable message entity
├── data/
│   └── datasources/
│       └── chat_local_storage_datasource.dart  ✅ Persistence layer
├── presentation/
│   ├── cubits/
│   │   ├── chat_flow_cubit.dart       ✅ State management with persistence
│   │   └── chat_flow_state.dart       ✅ Sealed classes
│   ├── pages/
│   │   └── chat_flow_page.dart        ✅ Main page
│   └── widgets/
│       ├── chat_message_bubble.dart   ✅ Message display
│       ├── chat_input_area.dart       ✅ Dynamic input
│       ├── chat_typing_indicator.dart ✅ Animated typing dots
│       ├── chat_video_metadata_card.dart ✅ Metadata display
│       └── chat_prompt_card.dart      ✅ Prompt display
```

---

## UI/UX Design (Material 3)

### Message Bubbles

| Type | Alignment | Background | Text Style |
|------|-----------|------------|------------|
| Bot | Left | `surfaceContainerHighest` | `bodyMedium` |
| User | Right | `primaryContainer` | `bodyMedium` |
| Error | Left | `errorContainer` | `bodyMedium` + error color |
| Loading | Left | `surfaceContainerHighest` | Typing indicator animation |

### Input Area States

| Step | Input Type | Hint Text |
|------|------------|-----------|
| Welcome | Single-line URL | "Paste YouTube URL..." |
| Language | Hidden (chips shown) | N/A |
| Analyzing | Disabled + Typing Indicator | "Analyzing..." |
| Prompt | Hidden | N/A |
| JSON Input | Multi-line | "Paste AI response..." |

---

## i18n Keys Added

```json
{
  "chat": {
    "title": "Funny Threads AI",
    "welcomeMessage": "Hi! I'm here to help you create funny clips...",
    "selectLanguagePrompt": "What language should I use for the analysis?",
    "analyzingVideo": "Analyzing video...",
    "videoFound": "Great! I found the video...",
    "promptReady": "I've prepared a prompt for your AI tool...",
    "copyPrompt": "Copy Prompt",
    "openAiTool": "Open AI Tool",
    "pasteJsonPrompt": "Please paste the AI response below:",
    "validating": "Validating response...",
    "validationSuccess": "✅ Found {count} funny moments!",
    "validationFailed": "❌ Validation failed",
    "retry": "Try Again",
    "resetConfirm": "Start over? This will clear the current conversation.",
    "proceed": "Continue"
  }
}
```

---

## Integration Points

### With Existing Flow

```
┌─────────────────────────────────────────────────────────────┐
│  ChatFlowPage (NEW)                                         │
│  - Replaces AnalyzeInputPage                                │
│  - Replaces GeminiStepPage                                  │
│  - Replaces JsonPaste flow                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │ Navigates to /review
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  MomentsReviewPage (EXISTING)                               │
│  - Receives youtubeUrl and aiPayload from ChatFlowCubit     │
│  - Fixed i18n string interpolation issues                   │
└──────────────────────┬──────────────────────────────────────┘
                       │ Navigates to /processing
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  ProcessingPage → ResultsPage (EXISTING - unchanged)        │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```dart
// On ChatFlowCompleted state
context.go('/review');

// In router.dart
if (chatState is ChatFlowCompleted) {
  return MomentsReviewPage(
    youtubeUrl: chatState.youtubeUrl,
    aiPayload: chatState.aiPayload,
  );
}
```

---

## Quality Gates (AGENTS.md Compliance)

- [x] `ChatFlowState` is a `sealed class` (Dart 3)
- [x] Uses `fpdart` `Either` for all use case results
- [x] Material Design 3 only (no custom theming)
- [x] Manual DTOs (no `freezed`/`json_serializable`)
- [x] i18n strings in `.i18n.json` files
- [x] No AI API integration (manual copy/paste)
- [x] Cubit is thin (state management only)
- [x] No business logic in UI layer

---

## Implementation Checklist

### Phase 1: Critical Fixes ✅
- [x] Fix language selection flow order
- [x] Remove hardcoded 'uk' language
- [x] Add `ChatFlowLanguageSelection` state
- [x] Create language selector in chat page

### Phase 2: Code Quality ✅
- [x] Refactor Cubit to be thinner
- [x] Remove unused imports
- [x] Improve error recovery with recoverableData
- [x] Use LaunchService abstraction

### Phase 3: Polish ✅
- [x] Add typing indicators
- [x] Add message persistence across refresh
- [x] Fix i18n errors in moments_review_page.dart
- [x] Build compiles successfully

---

## New Files Created

| File | Purpose |
|------|---------|
| `widgets/chat_typing_indicator.dart` | Animated 3-dot typing indicator |
| `data/datasources/chat_local_storage_datasource.dart` | localStorage persistence |
| `domain/entities/chat_message.dart` | Immutable chat message entity |

---

## Key Modified Files

| File | Changes |
|------|---------|
| `cubits/chat_flow_cubit.dart` | Added persistence, fixed flow, uses LaunchService |
| `cubits/chat_flow_state.dart` | Added ChatFlowLanguageSelection |
| `pages/chat_flow_page.dart` | Added language selector widget |
| `widgets/chat_message_bubble.dart` | Integrated typing indicator |
| `widgets/chat_video_metadata_card.dart` | Changed to Continue button |
| `core/di/injection.dart` | Registered new dependencies |
| `core/utils/launch_service*.dart` | Added `launchUrl()` method |
| `moments_review_page.dart` | Fixed i18n string interpolation |

---

## Build Status

```bash
$ cd apps/frontend && flutter analyze
Analyzing frontend...
No errors found!
# 5 infos about dart:html deprecation (acceptable for web)
# 2 warnings in generated strings.g.dart (harmless)
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │  ChatFlowPage                                   │   │
│  │  ├─ ListView (messages)                         │   │
│  │  └─ ChatInputArea (dynamic input)               │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  ChatFlowCubit                                  │   │
│  │  ├─ Manages conversation flow                   │   │
│  │  ├─ Persists state to localStorage              │   │
│  │  └─ Restores state on init                      │   │
│  └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Use Cases (existing)                           │   │
│  │  ├─ AnalyzeVideoUseCase                         │   │
│  │  ├─ BuildAiPromptUseCase                        │   │
│  │  └─ ValidateAndParseJsonUseCase                 │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Entities                                       │   │
│  │  ├─ ChatMessage                                 │   │
│  │  ├─ VideoMetadata                               │   │
│  │  └─ FunnyMoment                                 │   │
│  └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│  DATA LAYER                                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Repositories                                   │   │
│  │  └─ VideoRepositoryImpl                         │   │
│  ├─────────────────────────────────────────────────┤   │
│  │  Local Storage                                  │   │
│  │  └─ ChatLocalStorageDatasource                  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Notes

1. **No AI API Integration**: The app remains AI-agnostic. Users manually copy prompts to their preferred AI tool (ChatGPT, Claude, Gemini) and paste back the JSON response.

2. **YouTube-First Review**: Video download is still deferred until the review page, maintaining the bandwidth-saving design principle.

3. **State Persistence**: Chat state is automatically saved to localStorage after each change and restored on page refresh (valid for 24 hours).

4. **Typing Indicator**: Animated 3-dot indicator shows during analysis and validation operations.

5. **Error Recovery**: Improved retry logic with recoverable data - can return to language selection with URL preserved.
