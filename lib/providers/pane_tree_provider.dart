import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pane_node.dart';

class PaneTreeNotifier extends Notifier<PaneNode> {
  @override
  PaneNode build() => LeafNode.empty();

  // ---- File operations ----

  void openFile(String leafId, String filePath) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(
          filePath: filePath,
          contentType: inferContentType(filePath),
          isPreviewMode: false,
          hasUnsavedChanges: false,
        ));
  }

  void splitWithFile(String targetLeafId, String filePath, DropZone zone) {
    final newLeaf = LeafNode.forFile(filePath);
    state = insertAtLeaf(state, targetLeafId, newLeaf, zone);
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
  }

  void closeLeaf(String leafId) {
    final result = removeLeaf(state, leafId);
    state = result ?? LeafNode.empty();
  }

  void setRatio(String splitNodeId, double ratio) {
    state = updateRatio(state, splitNodeId, ratio);
  }

  void setPreviewMode(String leafId, bool isPreview) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(isPreviewMode: isPreview));
  }

  void openPreviewPane(String sourceLeafId) {
    final source = findNode(state, sourceLeafId);
    if (source is! LeafNode || source.filePath == null) return;
    final preview = LeafNode.previewFor(source.filePath!, source.contentType);
    state = insertAtLeaf(state, sourceLeafId, preview, DropZone.right);
  }

  void markUnsaved(String leafId, bool hasUnsaved) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(hasUnsavedChanges: hasUnsaved));
  }

  void markSaved(String leafId) {
    state = mapLeaf(state, leafId, (leaf) => leaf.copyWith(hasUnsavedChanges: false));
  }
}

final paneTreeProvider = NotifierProvider<PaneTreeNotifier, PaneNode>(
  PaneTreeNotifier.new,
);
