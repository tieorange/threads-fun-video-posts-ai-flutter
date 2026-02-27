# Mobile Chat UI/UX Improvement Plan (iPhone Safari)

## Goal
Improve chat usability on iPhone Safari with better keyboard behavior, safe-area support, message readability, and input ergonomics.

## Scope
- `apps/frontend/lib/features/video_processing/presentation/pages/chat_flow_page.dart`
- `apps/frontend/lib/features/video_processing/presentation/widgets/chat_input_area.dart`
- `apps/frontend/lib/features/video_processing/presentation/widgets/chat_message_bubble.dart`

## Implementation Steps
1. Stabilize keyboard + viewport behavior
- Dismiss keyboard on drag/tap outside chat input.
- Add bottom spacing logic that respects both keyboard inset and iPhone safe area.
- Use animated inset transitions to reduce visual jumps.

2. Improve chat list UX
- Increase message list horizontal/vertical padding for narrow screens.
- Keep auto-scroll behavior while preventing abrupt movement.
- Ensure input area does not visually overlap the last message.

3. Improve input composer ergonomics
- Add minimum tap-target sizes for send/validate actions.
- Disable send actions when input is empty.
- Improve composer container styling and spacing for thumb reach.

4. Improve message readability
- Adjust bubble width constraints for mobile screens.
- Add timestamp text under message content.
- Increase text line-height for long messages and JSON previews.

5. Validation
- Run `flutter analyze` for frontend.
- Manually verify on iPhone Safari:
  - Keyboard open/close does not hide composer.
  - Last message remains visible while typing.
  - Dragging list dismisses keyboard.
  - Message timestamps and spacing remain readable.
