import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pane_node.dart';
import '../services/persistence_service.dart';

class PaneTreeNotifier extends Notifier<PaneNode> {
  @override
  PaneNode build() {
    // Restore pane layout from last session
    final saved = PersistenceService.instance.loadPaneTree();
    if (saved != null) {
      return paneNodeFromJson(saved);
    }
    return LeafNode.empty();
  }

  void _persist() {
    PersistenceService.instance.savePaneTree(paneNodeToJson(state));
  }

  // ---- File operations ----

  void openFile(String leafId, String filePath) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(
          filePath: filePath,
          contentType: inferContentType(filePath),
          isPreviewMode: false,
          hasUnsavedChanges: false,
        ));
    _persist();
  }

  void splitWithFile(String targetLeafId, String filePath, DropZone zone) {
    final newLeaf = LeafNode.forFile(filePath);
    state = insertAtLeaf(state, targetLeafId, newLeaf, zone);
    _persist();
  }

  void moveLeaf(String sourceLeafId, String targetLeafId, DropZone zone) {
    if (sourceLeafId == targetLeafId) return;
    final source = findNode(state, sourceLeafId);
    if (source == null) return;
    final withoutSource = removeLeaf(state, sourceLeafId);
    if (withoutSource == null) {
      // Only one leaf, can't move
      return;
    }
    state = insertAtLeaf(withoutSource, targetLeafId, source, zone);
    _persist();
  }

  void closeLeaf(String leafId) {
    final result = removeLeaf(state, leafId);
    state = result ?? LeafNode.empty();
    _persist();
  }

  void setRatio(String splitNodeId, double ratio) {
    state = updateRatio(state, splitNodeId, ratio);
    _persist();
  }

  void setPreviewMode(String leafId, bool isPreview) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(isPreviewMode: isPreview));
    _persist();
  }

  void openPreviewPane(String sourceLeafId) {
    final source = findNode(state, sourceLeafId);
    if (source is! LeafNode || source.filePath == null) return;
    final preview = LeafNode.previewFor(source.filePath!, source.contentType);
    state = insertAtLeaf(state, sourceLeafId, preview, DropZone.right);
    _persist();
  }

  void markUnsaved(String leafId, bool hasUnsaved) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(hasUnsavedChanges: hasUnsaved));
    // Don't persist on every keystroke; save state is ephemeral
  }

  void markSaved(String leafId) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(hasUnsavedChanges: false));
    _persist();
  }

  /// Reset to initial state (used by trash button).
  void reset() {
    state = LeafNode.empty();
    _persist();
  }
}

final paneTreeProvider = NotifierProvider<PaneTreeNotifier, PaneNode>(
  PaneTreeNotifier.new,
);
