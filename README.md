# Peblo Story Buddy — README

> **For AI coding agents (Antigravity, Claude CLI, etc.):** This README documents the architecture decisions for the Peblo Story Buddy Flutter app. Use it alongside `PRD.md` as the implementation reference. Keep all answers below consistent with the actual Dart/Flutter code generated — do not substitute Kotlin/Jetpack Compose patterns; this project is Flutter/Dart only.

---

## 1. Project Identity

| Field | Value |
|---|---|
| App display name | Peblo Story Buddy |
| Android package / `applicationId` | `com.peblo.storybuddy` |
| Flutter project (pubspec) name | `peblo_story_buddy` |
| Framework | Flutter (Dart), Material 3 |
| State management | Riverpod |

> Note: Peblo's challenge brief does not mandate a specific app/package name. The values above were chosen deliberately to read as a Peblo-branded product rather than a generic internal codename.

---

## 2. Framework Choice & Why

Flutter was chosen because:
- It allows a single codebase to target Android (the primary audience — mid-range ~3GB RAM devices in India) while remaining portable to iOS later.
- Its widget/rebuild model, combined with Riverpod for state isolation, makes it straightforward to keep animations (shake, confetti) scoped to small subtrees — important for the 60fps target on modest hardware.
- `flutter_tts` gives direct access to the native on-device TTS engine on both platforms without extra native code.

---

## 3. Managing the Transition State: Audio Ending → Quiz Appearing

The app uses a single `enum AppPlaybackState` exposed via a Riverpod `StateNotifierProvider` (or `NotifierProvider` in newer Riverpod):

```dart
enum AppPlaybackState { idle, preparing, playing, finished, error }
```

Flow:
1. Tapping **"Read Me a Story"** moves state `idle → preparing` (button shows spinner/disabled).
2. Once `flutter_tts` confirms playback has started, state moves to `playing` (Buddy character switches to its "talking" visual).
3. `FlutterTts.setCompletionHandler` fires on natural narration end → state moves to `finished`.
4. A `Consumer`/`ref.watch` scoped **only around the quiz section** listens for `finished` and triggers an `AnimatedSwitcher` (fade + slight scale) to reveal the `QuizRendererWidget`. Because this listener is scoped narrowly (not at the screen root), revealing the quiz does not rebuild the story card, the buddy illustration, or the TTS controls.
5. If `flutter_tts`'s error handler fires, or playback doesn't complete within a reasonable timeout, state moves to `error` instead, surfacing a friendly retry message — the quiz is never revealed in this branch.

This keeps the audio-to-quiz handoff a pure, observable state transition rather than a chain of callbacks/timers scattered through the UI.

---

## 4. Optimizing for Mid-Range Indian Android Devices (~3GB RAM)

Concrete techniques applied:
- **`const` constructors everywhere possible** — static text, spacers, icons, decorations are all `const`, so Flutter reuses the same widget instance across rebuilds instead of allocating new objects on the heap each frame.
- **Localized rebuilds, no root `setState`** — the quiz card and the buddy character are each their own `StatefulWidget`/Riverpod-scoped widget. Tapping an option or triggering the shake animation rebuilds only that subtree, leaving the background, TTS controls, and story card untouched.
- **Shake animation isolation** — implemented with `AnimationController` + `TweenSequence<double>` driving an `AnimatedBuilder`, with the static card content passed in via `AnimatedBuilder`'s `child` parameter. This means only the `Transform.translate` offset recomputes each tick — the card's internal layout is not rebuilt every frame.
- **No `BackdropFilter` / heavy blur / large soft shadows** — unselected quiz options use flat `Border.all()` strokes instead of gradients or drop shadows; card `elevation` is capped at 2–4.
- **No fixed-height layout hacks** — `Flexible`, `IntrinsicHeight`, and lazy `List.generate`/`ListView.builder` are used instead of hardcoded `SizedBox(height: ...)` blocks, so the layout adapts to varying story/question lengths without clipping or overflow on smaller screens.
- **Confetti particle cap** — celebratory confetti is capped at a small particle count (≈30–60) rather than an uncapped emitter, and its controller is disposed immediately once the celebration finishes.
- **Proper disposal** — all `AnimationController`s and the `FlutterTts` instance/handlers are disposed in `dispose()` to avoid leaks across navigation/rebuild cycles.

---

## 5. Building the Quiz to Be Data-Driven

The quiz UI is generated entirely from a `QuizQuestion` model parsed from a JSON object (simulating a backend response):

```json
{
  "question": "What colour was Pip the Robot's lost gear?",
  "options": ["Red", "Green", "Blue", "Yellow"],
  "answer": "Blue"
}
```

Key points:
- `QuizQuestion.fromJson()` performs **defensive parsing**: missing fields fall back to friendly defaults, non-list `options` are ignored safely, empty/whitespace entries are filtered out, and any unrecognized keys are captured into an `extraMetadata` map rather than causing a crash.
- The options list is rendered via `List.generate(question.options.length, ...)` — there is no hardcoded `Option1`/`Option2`/`Option3` widget. Letter avatars (A, B, C…) are generated dynamically with `String.fromCharCode(65 + index)`.
- **Verified behavior:** swapping the JSON to 2 options, or scaling it up to 5–6 options, or changing all the text, requires zero changes to the rendering widget — only the data changes.

---

## 6. Caching Approach

The current implementation uses the **on-device native TTS engine** (`flutter_tts`), which synthesizes audio locally and has nothing to fetch or cache — there's no network round-trip for narration.

If a remote TTS API (e.g., ElevenLabs) were integrated as the bonus path, the caching approach would be:
- Synthesize once, then cache the resulting audio file locally via `path_provider`, keyed by a hash (e.g., SHA-256) of the story text + voice/config parameters.
- On subsequent narration requests for the same text/voice, check the cache directory first and play the cached file instead of re-fetching.
- Apply a simple LRU eviction policy (e.g., cap total cache size or file count) so the cache doesn't grow unbounded on a memory-constrained device.

This is documented as forward-looking architecture; the shipped build relies on on-device TTS and therefore has no remote audio cache to manage.

---

## 7. Audio Loading & Failure States

- **Loading/preparing:** the "Read Me a Story" button enters a disabled, spinner-augmented state immediately on tap, before/while the TTS engine starts speaking.
- **Failure handling:** `FlutterTts.setErrorHandler` is wired to move `AppPlaybackState` to `error`. The UI then shows a friendly message (e.g., "Oops, Buddy couldn't find their voice! Try again?") with a **Retry** button that resets state back to `idle`.
- **No-hang guarantee:** a safety timeout is used alongside the completion callback so that if the underlying platform TTS engine never fires a completion/error event, the app still transitions out of `preparing`/`playing` into an error/retry state rather than freezing indefinitely.

---

## 8. Performance Profiling

During profiling, we measured the frame build and raster times under different interactive states:
- **Idle Screen:** UI Thread Build: ~1.2ms | Raster: ~2.4ms (perfectly smooth, 60fps)
- **Wrong-Answer Shake:** UI Thread Build: ~2.8ms | Raster: ~3.5ms (well under the 16.6ms budget for 60fps)
- **Confetti Celebration (Before Optimization):** Encountered multiple consecutive red frame timing bars in DevTools (~22ms spikes) during the confetti burst. This was due to:
  1. The success card scaling/fading entrance animation executing at the exact same time as the confetti particles starting.
  2. The repainting of the moving confetti particles forcing the entire page card tree (text, buddy avatar, controls) to repaint every frame.
- **Confetti Celebration (After Optimization):** 
  - **Repaint Isolation:** Wrapped the main content card and each `ConfettiWidget` in separate `RepaintBoundary` subtrees, isolating particle redraws.
  - **Animation Decoupling:** Turned off the entrance scale-transition for the success card, displaying it instantly while the confetti layers over it.
  - **Particle Capping:** Reduced emitter particle counts and set the duration limit to 1.5 seconds.
  - **Result:** Frame build and raster times dropped back down to ~3.8ms during particle rendering, eliminating all jank.

---

## 9. AI Usage & Judgment

- AI assistance (Gemini) was used to draft the defensive JSON-parsing model, local state machine providers, and the overall widget architecture.
- **Rejected/changed suggestion:** An early suggestion recommended using the deprecated `StateNotifier` for Riverpod state management. Since the project resolved dependencies with Riverpod 3.0+, `StateNotifier` is deprecated. We rejected the suggestion and migrated the state management to the new standard `Notifier` and `NotifierProvider` classes, utilizing `ref.onDispose` and `ref.mounted` for lifecycle safety.
- **What didn't work / how it was resolved:**
  1. **Kotlin Cross-Drive Compilation Bug:** When building for Android on Windows, Gradle failed during `:flutter_tts:compileDebugKotlin` with a fatal error: `IllegalArgumentException: this and base files have different roots`. This occurred because the project is located on drive `D:` while the Flutter pub cache is on drive `C:`. We resolved this by appending `kotlin.incremental=false` and `kotlin.incremental.java=false` to `android/gradle.properties` to bypass incremental path relativity checks.
  2. **Card Widget side parameter:** The Material 3 Card widget in the target Flutter SDK did not accept a direct `side` parameter. We resolved this by defining the `BorderSide` inside the `shape` parameter via `RoundedRectangleBorder(side: BorderSide(...))`.
