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
