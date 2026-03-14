import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live (unsaved) editor content per file path.
///
/// Set by [MarkdownEditor] 800 ms after the user stops typing.
/// Cleared to null when the file is saved or first loaded.
/// [MarkdownPreview] watches this and prefers it over disk content,
/// producing VS Code-style delayed preview sync.
final liveContentProvider = StateProvider.family<String?, String>(
  (ref, filePath) => null,
);

/// Normalized scroll position (0.0 – 1.0) for editor ↔ preview sync.
///
/// Whichever pane scrolls writes a new fraction; the other pane
/// reads it and jumps to the proportional position.
final scrollSyncProvider = StateProvider.family<double, String>(
  (ref, filePath) => 0.0,
);
