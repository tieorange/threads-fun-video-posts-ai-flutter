# AI Implementation Plan: User Flow & Navigation Fixes

## 🎯 Objective
Resolve 5 bugs, 8 UX issues, and 4 navigation problems across the entire video processing flow (Chat → Review → Processing → Results).

---

## 🏗️ Technical Context
- **Core Loop**: `ChatFlowPage` (/) handles URL, Language, Analysis, and AI Prompt input.
- **Review**: `MomentsReviewPage` (/review) handles moment selection and job submission.
- **Processing**: `ProcessingPage` (/processing) polls for video cutting progress.
- **Results**: `ResultsPage` (/results) displays final clips.
- **State Management**: Uses `flutter_bloc`. `ChatFlowCubit` manages the chat, `ProcessCubit` manages the job submission and results. Both persist state to `localStorage`.

---

## 🛠️ Critical Issues & Implementation Details

### 🔴 1. Broken Back Navigation from Review
- **Issue**: Pressing 'Back' on `/review` takes the user to `/prompt` (a dead legacy route).
- **Target File**: `moments_review_page.dart`
- **Fix**: Change `leading: BackButton(onPressed: () => context.go('/prompt'))` to `context.go('/')`.

### 🔴 2. Broken Error Recovery in Chat
- **Issue**: `ChatFlowError` state defaults `currentStep` to `welcome`, showing the URL input box even if the error was in the JSON paste step.
- **Target Files**: `chat_flow_state.dart`, `chat_flow_cubit.dart`, `chat_message_bubble.dart`.
- **Logic**:
  1.  In `ChatFlowError` constructor: Set `currentStep` based on `recoverableStep`. If `recoverableStep == ChatStep.jsonInput`, set `currentStep: ChatStep.jsonInput`.
  2.  In `ChatFlowCubit.validateAndParseJson()`: On failure, store `prompt` and `analyzeResult` in `recoverableData`.
  3.  In `ChatFlowCubit.retry()`: Correct the code to use `recoverableData` to restore the `ChatFlowJsonInput` state instead of resetting to `ChatFlowInitial`.
  4.  In `ChatMessageBubble`: Add a "Try Again" button to the error bubble when `state is ChatFlowError` that calls `cubit.retry()`.

### 🔴 3. Results Persistence (Survive Refresh)
- **Issue**: `/results` loses its state on browser refresh because `ProcessDone` isn't saved to localStorage.
- **Target File**: `process_cubit.dart`
- **Fix**: Update `_saveJob()` to persist the final `jobStatus` when the job transitions to `ProcessDone`. Update `_restoreState()` to handle the "Done" state.

---

## ⚠️ UX Higher-Priority Fixes

### 🟡 1. Generate Double-Submit Guard
- **Issue**: Users can press 'Generate' multiple times or navigate back to review while processing is active.
- **Target File**: `moments_review_page.dart`
- **Fix**:
  1.  `_BottomBar` must accept a `nullable` `onGenerate` callback.
  2.  Watch `ProcessCubit.state` in the builder. If `state is! ProcessIdle`, pass `onGenerate: null` to disable the button.
  3.  Add a guard in the `_generate()` function itself.

### 🟡 2. Selection Constant Mismatch
- **Issue**: `_BottomBar` uses `_minMomentsToGenerate = 1` while the page uses `3`.
- **Target File**: `moments_review_page.dart`
- **Fix**: Standardize both to `3`. Update the `FilledButton.icon` enabled condition in `_BottomBar`.

### 🟡 3. Prompt Action Inconsistency
- **Issue**: Tapping "Open in ChatGPT" auto-transitions to the JSON paste box, hiding the prompt card while the user is still in the external tool.
- **Target File**: `chat_flow_cubit.dart`
- **Fix**: In `openAiTool()`, remove the state transition. Only move to the JSON step when the user taps "I have the response" on the prompt card.

## 🧪 Verification Steps
1.  **Navigation**: Navigate `/review` → Back. Should land on `/`.
2.  **Error Recovery**: Purposely paste bad JSON. Should see "Retry" button. Tapping it should keep the JSON input box visible and keep the prompt card.
3.  **Persistence**: Start a job → Go to `/results` → Refresh page. Results must still be there.
4.  **UI Logic**: Select 1 moment on review page. Generate button must be **disabled**.
5.  **Concurrent Jobs**: Submit a job → Go back to Review. Generate button must be **disabled** while job runs.
