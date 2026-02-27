# Plan: Fix Keyboard Covering UI on iPhone Safari

## Problem

On iPhone Safari, when the software keyboard opens it **overlays** the page rather than
pushing content up (unlike native iOS apps). This hides action buttons that sit below
or near text fields.

**Affected pages and exact elements:**

| Page | Input | Button at risk |
|------|-------|---------------|
| `/` — `analyze_input_page.dart` | URL TextField | "Analyze" FilledButton |
| `/prompt` — `gemini_step_page.dart` | JSON TextField (220 px tall) | "Paste", "Validate" buttons |

---

## How Flutter Web + iPhone Safari interact with the keyboard

1. **`visualViewport` API** — Safari fires `resize` on `window.visualViewport` when the
   keyboard opens/closes. Flutter's web engine listens to this and shrinks the Flutter
   logical viewport accordingly.
2. **`resizeToAvoidBottomInset`** — when `true` (Flutter default), Scaffold insets the
   `body` by `MediaQuery.viewInsets.bottom`, which equals the keyboard height once
   Flutter receives the `visualViewport` resize event.
3. **The gap** — Safari sometimes fires the `visualViewport` resize event late or not at
   all (especially for "standalone" PWA mode). The keyboard may overlap before Flutter
   reacts. Additionally a `ConstrainedBox(minHeight: maxHeight)` sized against the
   pre-keyboard viewport can hold the layout too tall and prevent scrolling.
4. **Bottom bar ("Go" / toolbar)** — Safari's bottom toolbar also takes ~50 px of space
   that is not always reflected in `viewInsets`. This needs a bottom padding buffer.

---

## Root causes in the current code

### A. `analyze_input_page.dart`

```
LayoutBuilder → ConstrainedBox(minHeight: constraints.maxHeight)
                  └─ Column → TextField → DropdownMenu → FilledButton(Analyze)
```

- `constraints.maxHeight` is snapped at build time. If it was measured before the
  keyboard appeared (or if `resizeToAvoidBottomInset` is not propagated in time), the
  column stays at full height. Scrolling then cannot reach the button because the
  `Column` itself fills the viewport.
- Fix: replace `ConstrainedBox(minHeight: maxHeight)` with
  `ConstrainedBox(minHeight: max(maxHeight, 0))` is not enough — we need to consume
  `MediaQuery.viewInsets.bottom` explicitly or move to a simpler scroll layout that
  does not pin height to the screen.

### B. `gemini_step_page.dart`

```
SingleChildScrollView
  └─ Step1Card (prompt preview + Copy button)
  └─ Step2Card
       └─ Row(Paste button)
       └─ SizedBox(height: 220) ← TextField receives focus
       └─ FilledButton(Validate)  ← keyboard covers this
```

- The `Validate` button is ~260 px below the bottom of the text field. When the
  keyboard (≈300 px) opens, both the field and the button disappear below the fold.
- Flutter does not auto-scroll a `SingleChildScrollView` to ensure the *focused*
  widget is above the keyboard — it only does that for `TextField` via
  `Scrollable.ensureVisible`. But the *button below* the field is never scrolled into
  view automatically.

### C. `app_shell_scaffold.dart`

- `SafeArea(top: false)` leaves `bottom: true` active, which adds home-indicator
  padding. But **keyboard inset is separate** (`viewInsets.bottom`) and is only
  handled by `Scaffold(resizeToAvoidBottomInset: true)`.
- The parameter is passed through as nullable; callers do not set it explicitly. This
  works (Flutter Scaffold defaults `null` → `true`) but is fragile and invisible.

### D. `web/index.html`

- Viewport: `width=device-width, initial-scale=1.0` — missing `viewport-fit=cover`.
  Without it, Safari may not report the correct safe-area insets for notched devices,
  slightly misreporting available height.

---

## Proposed fixes

### Fix 1 — `index.html`: add `viewport-fit=cover`

```html
<!-- before -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<!-- after -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
```

Low-risk, one line. Required for correct notch/safe-area reporting.

---

### Fix 2 — `app_shell_scaffold.dart`: make `resizeToAvoidBottomInset` explicit

Change the Scaffold call to default `resizeToAvoidBottomInset` to `true` explicitly so
the intent is clear and future readers don't rely on the undocumented `null`→`true`
default:

```dart
// In AppShellScaffold, change parameter default:
final bool resizeToAvoidBottomInset;
// constructor default value: true (not null)
```

---

### Fix 3 — `analyze_input_page.dart`: drop the height-pinning `ConstrainedBox`

The current pattern:

```dart
LayoutBuilder(builder: (context, constraints) {
  return SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Column(...),
    ),
  );
})
```

This is the "center vertically while allowing scroll" idiom, but it fights keyboard
resizing because `constraints.maxHeight` is the *full* viewport height at layout time.

**Replacement approach** — use `IntrinsicHeight` + an `Expanded` spacer, or simply
accept top-aligned layout with enough top padding to look good:

```dart
SingleChildScrollView(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 48),   // breathing room at top
      // ... subtitle, text field, dropdown, button ...
      // Add bottom buffer so button clears the Safari toolbar:
      const SizedBox(height: 80),
    ],
  ),
)
```

The `SizedBox(height: 80)` at the bottom ensures the "Analyze" button is never flush
with the bottom of the scroll area, giving the Safari toolbar room.

---

### Fix 4 — `gemini_step_page.dart`: make Validate button always reachable

**Option A (preferred) — move Validate button above the textarea**

Reorder Step 2 card children:

```
Row(Paste button)          ← stays at top
FilledButton(Validate)     ← moved UP, just below the paste row
SizedBox(height: 220) TextField  ← now at bottom of card
```

Rationale: user must paste first, then validate. Putting Validate above the big
textarea means it is visible *before* the keyboard opens and remains in view when
the keyboard is up (since the textarea is scrolled down, not the button).

**Option B (alternative) — sticky bottom bar**

Lift the Validate button out of the scroll tree and into a `bottomNavigationBar`
slot (or a persistent `Padding` below the `SingleChildScrollView`). Flutter will
automatically keep this above the keyboard inset.

```dart
AppShellScaffold(
  title: ...,
  bottomBar: Padding(
    padding: const EdgeInsets.all(16),
    child: FilledButton.icon(
      onPressed: _validate,
      icon: const Icon(Icons.check_circle_outline),
      label: Text(t.geminiStep.validate),
    ),
  ),
  body: ...,
)
```

This requires adding a `bottomBar` slot to `AppShellScaffold` and passing it to
`Scaffold.bottomNavigationBar` (which respects `resizeToAvoidBottomInset`
automatically).

**Recommendation:** Option A is simpler (no scaffold changes). Option B is more
robust for future pages with similar patterns.

---

### Fix 5 — `gemini_step_page.dart`: add bottom padding buffer

Regardless of option chosen above, add a `SizedBox(height: 100)` at the end of the
scroll column (already has `SizedBox(height: 24)`). This ensures the content can
always be scrolled to fully above the keyboard.

---

## Implementation order

1. `index.html` — viewport-fit=cover (1 line, no risk)
2. `app_shell_scaffold.dart` — explicit `resizeToAvoidBottomInset: true` default
3. `gemini_step_page.dart` — reorder Validate above textarea (Option A) + increase bottom padding
4. `analyze_input_page.dart` — replace height-pinning LayoutBuilder with simpler scroll + bottom padding

---

## Testing checklist (iPhone Safari)

- [ ] Tap URL field on `/` → keyboard opens → "Analyze" button visible without manual scroll
- [ ] Tap URL field on `/` → type → tap "Analyze" → no manual scroll needed
- [ ] On `/prompt` → tap JSON textarea → keyboard opens → "Validate" button visible
- [ ] On `/prompt` → "Paste" button visible when keyboard is open
- [ ] Both pages on notched iPhone (iPhone 14+) — content not clipped by notch or home indicator
- [ ] Landscape orientation — layout does not overflow
- [ ] PWA standalone mode — same behaviour as browser (most critical edge case)
