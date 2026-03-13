# ai_native_editor — Workspace Instructions

VS Code-style adaptive knowledge workbench for tablets. Three-column layout (file list | binary split-tree editor | AI Agent chat), targeted at iPad/Android tablets, touch-first.

---

## Build & Test Commands

```bash
flutter run                          # Debug run (default device)
flutter run -d <device-id>           # Target a specific device
flutter build apk --release          # Android release APK
flutter build windows                # Windows desktop build
flutter analyze                      # Static analysis (must pass before committing)
flutter test                         # Unit tests
flutter pub get                      # Install/update dependencies
```

---

## Architecture Overview

Single-screen app (`Scaffold` → `Row` of three panels). No navigation router.

### State Management — Riverpod 2 (`NotifierProvider` only)

All providers follow the same pattern:

```dart
// immutable state
@immutable
class FooState { final X field; const FooState({required this.field}); FooState copyWith({X? field}) => ...; }

// notifier
class FooNotifier extends Notifier<FooState> {
  @override FooState build() => const FooState(...);
  void doSomething() => state = state.copyWith(...);
}

// provider
final fooProvider = NotifierProvider<FooNotifier, FooState>(FooNotifier.new);
```

**Rule:** `ref.watch` in `build`, `ref.read` in event handlers/callbacks. Never reverse.

---

### Core Data Model — Sealed Recursive Pane Tree (`lib/models/pane_node.dart`)

```dart
sealed class PaneNode { final String id; }
class SplitNode extends PaneNode { Axis axis; double ratio; PaneNode first; PaneNode second; }
class LeafNode  extends PaneNode { String? filePath; ContentType contentType; bool isPreviewMode; bool hasUnsavedChanges; }
```

The tree is **immutable** — all mutations are pure functions returning a new tree:

| Function | Purpose |
|---|---|
| `findNode(tree, id)` | Locate any node by ID |
| `removeLeaf(tree, id)` | Remove leaf, collapse parent split |
| `insertAtLeaf(tree, targetId, newLeaf, zone)` | Split a leaf and insert a sibling |
| `mapLeaf(tree, id, fn)` | Update a leaf in-place (returns new tree) |
| `updateRatio(tree, splitId, ratio)` | Resize a split |
| `collectLeafIds(tree)` | Flat list of all leaf IDs |

**Always call these top-level functions, never mutate nodes directly.**

DropZone detection: `detectDropZone(localPos, size)` uses 25% edge thresholds → `top/bottom/left/right/center`.

---

### Drag and Drop

```dart
sealed class DragPayload {}
class FilePathPayload extends DragPayload { String filePath; }   // from file list
class PanePayload      extends DragPayload { String leafId; }    // from title bar
```

`LongPressDraggable` with `delay: 300ms` (touch-safe). `DragTarget` in `LeafNodeWidget` dispatches to `PaneTreeNotifier` based on detected zone.

---

### AI Integration (`lib/services/qwen_service.dart`)

Alibaba DashScope / OpenAI-compatible endpoint. Uses raw HTTP streaming — manually parses `data: {...}` SSE lines from `http.Request.send()` and yields `Stream<String>` deltas.

`const kAvailableModels = ['qwen-turbo', 'qwen-plus', 'qwen-max', ...]`

API key stored via `flutter_secure_storage` (Android: `encryptedSharedPreferences`, iOS: Keychain).

---

### File I/O (`lib/services/file_service.dart`)

Singleton: `FileService.instance` (note: `static final`, not `const`).

- `readFileSafe(path, {maxChars: 50000})` — silently truncates large files
- `writeFile(path, content)` → `bool` success

Autosave: 2-second debounce `Timer` in `MarkdownEditor._onChanged`. Ctrl+S triggers immediate save.

---

## Design Tokens

**Never use raw `Color` values or `Theme.of(context).colorScheme` in widgets.** Use design tokens:

```dart
// Colors — pick based on isDark bool passed from parent
AppColors.darkBackground / AppColors.lightBackground
AppColors.darkSurface1 / AppColors.lightSurface1      // main panel bg
AppColors.darkSurface2 / AppColors.lightSurface2      // elevated surfaces
AppColors.darkSurface3 / AppColors.lightSurface3      // hover/selected
AppColors.darkPrimary  / AppColors.lightPrimary       // warm violet accent
AppColors.darkAiAccent / AppColors.lightAiAccent      // teal (AI elements)
AppColors.darkTextPrimary / AppColors.lightTextPrimary
AppColors.darkTextSecondary / AppColors.lightTextSecondary
AppColors.darkTextMuted / AppColors.lightTextMuted
AppColors.darkBorder / AppColors.lightBorder
AppColors.darkBorderSubtle / AppColors.lightBorderSubtle

// Spacing (4pt grid)
AppTheme.sp2 / sp4 / sp6 / sp8 / sp12 / sp16 / sp20 / sp24 / sp32

// Border radius
AppTheme.radius4 / radius6 / radius8 / radius12

// Touch targets
AppTheme.touchTarget = 44   // min tap target (44px)

// Fonts
AppTheme.editorStyle()      // JetBrains Mono 14px, line-height 1.6
// UI font: Inter via GoogleFonts
```

---

## Code Conventions

- **Files:** `snake_case` — e.g., `pane_tree_provider.dart`
- **Private widgets** in the same file: leading underscore class — `_TitleBar`, `_Segment`
- **Providers:** `<feature>Provider`, `<Feature>Notifier`, `<Feature>State`
- **Sealed class dispatch** in recursive widgets:
  ```dart
  switch (node) {
    LeafNode()  => LeafNodeWidget(leaf: node),
    SplitNode() => SplitNodeWidget(node: node),
  }
  ```
- **`isDark` bool threading:** Every widget receives `isDark` from its parent instead of calling `Theme.of(context).brightness` internally — be consistent.
- **Imports:** Use relative imports for project files (`../../models/pane_node.dart`), package imports for dependencies.

---

## Platform Notes

**Target:** Android tablets (primary), iPad. Landscape orientation forced (`SystemChrome.setPreferredOrientations`). `SystemUiMode.edgeToEdge` (no status/nav bars).

**Android build toolchain (required for JDK 21 + Windows):**

| Component | Version |
|---|---|
| Gradle | 8.7 |
| AGP | 8.5.2 |
| Kotlin | 1.9.25 |
| Java target | 17 |
| JVM heap | -Xmx4G (gradle.properties) |

**flutter_secure_storage on Android:** `AndroidOptions(encryptedSharedPreferences: true)` — requires API 23+. Works on all current tablets.

**`FilePicker.saveFile()`** is **not supported on Android**. Use `FilePicker.platform.getDirectoryPath()` (SAF folder picker) to let users choose a save location, then construct the path with `p.join(directory, filename)` from `package:path`.

---

## Known Gaps / TODOs

| Item | Location | Notes |
|---|---|---|
| Release signing not configured | `android/app/build.gradle:37` | Uses debug key for release; must fix before Play Store |
| `hasUnsavedChanges` not wired | `markdown_editor.dart` + `pane_tree_provider.dart` | `markUnsaved`/`markSaved` methods exist but editor never calls them |
| Undo button is no-op | `leaf_node_widget.dart` | `onUndo: () {}` — needs focus/keyboard dispatch to `_undoController` |
| No workspace persistence | `providers/` | App state lost on restart; `path_provider` is available for implementing this |
| File truncation silent | `file_service.dart` | `readFileSafe` cuts at 50k chars with no UI warning |
| `url_launcher` unused | `pubspec.yaml` | Likely planned for markdown link handling |

---

## Key Files Quick Reference

| File | Role |
|---|---|
| `lib/main.dart` | Entry point, orientation lock, edge-to-edge, `ProviderScope` |
| `lib/app.dart` | `MaterialApp`, theme wiring |
| `lib/models/pane_node.dart` | **Core domain model** — read before touching editor layout |
| `lib/providers/pane_tree_provider.dart` | All pane split/move/close operations |
| `lib/providers/chat_provider.dart` | AI streaming, context file injection |
| `lib/services/qwen_service.dart` | HTTP SSE streaming implementation |
| `lib/theme/app_colors.dart` | All color tokens |
| `lib/theme/app_theme.dart` | Spacing, radius, font helpers |
| `lib/widgets/editor/leaf_node_widget.dart` | Drop target + drag source for panes |
| `lib/widgets/editor/drop_zone_overlay.dart` | Zone detection geometry + `CustomPaint` highlight |
