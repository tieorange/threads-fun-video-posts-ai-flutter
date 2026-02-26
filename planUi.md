# planUi.md - UI/UX & Workflow Improvement Plan

This plan outlines the steps to elevate the **Funny Threads AI** application from a functional MVP to a premium, user-friendly tool. The focus is on visual excellence (Material 3), seamless mobile Safari performance, and a more intuitive "manual AI" workflow.

---

## 1. Visual Design & Brand Identity

### Color & Typography
- [ ] **Premium Palette**: Move beyond "default" Material 3. Use a sleek dark-mode-first approach (deep charcoals, vibrant accent for primary actions like "Analyze" and "Generate").
- [ ] **Modern Typography**: Use `Inter` or `Outfit` (loaded via Google Fonts) for a more professional, "app-like" feel.
- [ ] **Consistency**: Standardize spacing (using an 8px grid) and corner radii (16px+ for a softer, modern look).

### App Shell Improvements
- [ ] **Sticky Header**: Ensure the header is always accessible but subtle.
- [ ] **Steppers/Breadcrumbs**: Add a visual 1-2-3-4 stepper at the top (Analyze → Prompt → Paste → Review → Results) to help users understand the multi-step manual workflow.

---

## 2. Workflow Optimizations

### The "Manual Bridge" UX
- [ ] **Phase Transition Clarity**: When moving from "Prompt Builder" to "Paste JSON", provide a clearer "waiting" state or a "Split Screen" on desktop to encourage keeping the application open while using the AI tool.
- [ ] **Auto-Focus & Paste**: On the Paste page, automatically scroll to the input field. Add a "Paste from Clipboard" button (using `Clipboard.getData`) to reduce manual taps on mobile.
- [ ] **Status Feedback**: Use more descriptive snackbars and micro-animations to confirm "Copied!" or "Validating...".

### Input & Analysis
- [ ] **Smart URL Parsing**: Detect if a URL is already in the buffer and suggest it.
- [ ] **Language Selection**: Use a more visual selection (e.g., segmented buttons or tiles) instead of a simple dropdown.

---

## 3. Mobile (Safari/iPhone) Enhancements

### Layout & Sizing
- [ ] **Dynamic Card Widths**: On mobile, use a single-column layout with slightly reduced height for the "Review" cards to avoid excessive scrolling.
- [ ] **Hit Targets**: Increase the size of selection badges and action buttons to a minimum of 48px height for thumb-friendly interaction.
- [ ] **Safe Area Polish**: Ensure the bottom action bar in the "Review" and "Results" pages accounts for the Safari URL bar/switcher.

### Performance & Interaction
- [ ] **YT Iframe Fixes**: Ensure `PointerInterceptor` is applied to all over-laying UI elements (badges, buttons) to prevent clicks from being "swallowed" by the iframe on Safari.
- [ ] **Lazy Loading**: Optimize the results list to only initialize video controllers when a clip is actually viewed or tapped.

---

## 4. Desktop Specifics

### Space Utilization
- [ ] **Side-by-Side Review**: On wide screens (>= 1200px), use a 3-column grid for review cards to show more content at once.
- [ ] **Keyboard Shortcuts**: Introduce shortcuts like `Space` for play/pause in preview, `R` to refresh/start over, and `C` to copy prompt.

---

## 5. Implementation Roadmap

### Phase 1: Foundation (Theme & Navigation)
- Update `AppTheme` with custom color schemes and fonts.
- Implement the `StepIndicator` widget into `AppShellScaffold`.

### Phase 2: Refined Pages
- **Analyze Page**: Redesign as a "Hero" landing page.
- **Prompt/Paste Pages**: Merge visual styles, adding "Quick Action" buttons.
- **Review Page**: Optimize card layout and hit targets.

### Phase 3: Polish & Verification
- Perform cross-device testing specifically on iPhone Safari 17+.
- Smooth out transitions between pages using `PageTransitionsTheme`.
