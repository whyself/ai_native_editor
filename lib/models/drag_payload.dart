/// Payloads carried during drag-and-drop operations.
sealed class DragPayload {}

/// Dragging a file from the workspace file list.
class FilePathPayload extends DragPayload {
  final String filePath;
  FilePathPayload(this.filePath);
}

/// Dragging an existing pane to move it.
class PanePayload extends DragPayload {
  final String leafId;
  PanePayload(this.leafId);
}

/// Unified title-bar drag: carries the pane identity and optionally the file
/// path. Drop targets use whichever field is relevant:
///   - LeafNodeWidget  → pane reorder via leafId
///   - AiPanel         → add context file via filePath
class TitleBarPayload extends DragPayload {
  final String leafId;
  final String? filePath;
  TitleBarPayload({required this.leafId, this.filePath});
}
