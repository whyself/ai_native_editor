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
