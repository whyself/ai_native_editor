import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---- Enums ----

enum ContentType { markdown, plainText, unknown }

enum DropZone { top, bottom, left, right, center }

// ---- Helpers ----

ContentType inferContentType(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'md' || 'markdown' => ContentType.markdown,
    'txt' => ContentType.plainText,
    _ => ContentType.unknown,
  };
}

// ---- Node sealed class ----

sealed class PaneNode {
  final String id;
  const PaneNode({required this.id});
}

class SplitNode extends PaneNode {
  /// horizontal = children side by side (Row / left-right split)
  /// vertical   = children stacked (Column / top-bottom split)
  final Axis axis;

  /// Ratio of the FIRST child (0.0 – 1.0)
  final double ratio;

  final PaneNode first;
  final PaneNode second;

  const SplitNode({
    required super.id,
    required this.axis,
    required this.ratio,
    required this.first,
    required this.second,
  });

  SplitNode copyWith({
    Axis? axis,
    double? ratio,
    PaneNode? first,
    PaneNode? second,
  }) =>
      SplitNode(
        id: id,
        axis: axis ?? this.axis,
        ratio: ratio ?? this.ratio,
        first: first ?? this.first,
        second: second ?? this.second,
      );
}

class LeafNode extends PaneNode {
  final String? filePath;
  final ContentType contentType;
  final bool isPreviewMode;
  final bool hasUnsavedChanges;

  const LeafNode({
    required super.id,
    this.filePath,
    this.contentType = ContentType.markdown,
    this.isPreviewMode = false,
    this.hasUnsavedChanges = false,
  });

  factory LeafNode.empty() => LeafNode(id: _uuid.v4());

  factory LeafNode.forFile(String path) => LeafNode(
        id: _uuid.v4(),
        filePath: path,
        contentType: inferContentType(path),
      );

  factory LeafNode.previewFor(String path, ContentType contentType) => LeafNode(
        id: _uuid.v4(),
        filePath: path,
        contentType: contentType,
        isPreviewMode: true,
      );

  LeafNode copyWith({
    String? filePath,
    ContentType? contentType,
    bool? isPreviewMode,
    bool? hasUnsavedChanges,
  }) =>
      LeafNode(
        id: id,
        filePath: filePath ?? this.filePath,
        contentType: contentType ?? this.contentType,
        isPreviewMode: isPreviewMode ?? this.isPreviewMode,
        hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      );

  String get displayName {
    if (filePath == null) return 'Welcome';
    return filePath!.split(RegExp(r'[/\\]')).last;
  }
}

// ---- Pure tree operations ----

PaneNode? findNode(PaneNode tree, String id) {
  if (tree.id == id) return tree;
  if (tree is SplitNode) {
    return findNode(tree.first, id) ?? findNode(tree.second, id);
  }
  return null;
}

/// Remove leaf by id. Returns null if the entire tree collapses.
PaneNode? removeLeaf(PaneNode tree, String leafId) {
  if (tree is LeafNode) return tree.id == leafId ? null : tree;
  if (tree is SplitNode) {
    if (tree.first.id == leafId) return tree.second;
    if (tree.second.id == leafId) return tree.first;
    final newFirst = removeLeaf(tree.first, leafId);
    final newSecond = removeLeaf(tree.second, leafId);
    if (newFirst == null) return newSecond;
    if (newSecond == null) return newFirst;
    return tree.copyWith(first: newFirst, second: newSecond);
  }
  return tree;
}

/// Insert [newLeaf] by splitting [targetLeafId] at [zone].
PaneNode insertAtLeaf(PaneNode tree, String targetLeafId, PaneNode newLeaf, DropZone zone) {
  if (tree is LeafNode) {
    if (tree.id != targetLeafId) return tree;
    if (zone == DropZone.center) {
      // Replace file in same leaf (keep same id)
      if (newLeaf is LeafNode) {
        return tree.copyWith(
          filePath: newLeaf.filePath,
          contentType: newLeaf.contentType,
          isPreviewMode: false,
          hasUnsavedChanges: false,
        );
      }
      return newLeaf;
    }
    final axis = (zone == DropZone.left || zone == DropZone.right)
        ? Axis.horizontal
        : Axis.vertical;
    final newFirst = zone == DropZone.top || zone == DropZone.left;
    return SplitNode(
      id: _uuid.v4(),
      axis: axis,
      ratio: 0.5,
      first: newFirst ? newLeaf : tree,
      second: newFirst ? tree : newLeaf,
    );
  }
  if (tree is SplitNode) {
    return tree.copyWith(
      first: insertAtLeaf(tree.first, targetLeafId, newLeaf, zone),
      second: insertAtLeaf(tree.second, targetLeafId, newLeaf, zone),
    );
  }
  return tree;
}

/// Update a specific leaf using [transform].
PaneNode mapLeaf(PaneNode tree, String leafId, LeafNode Function(LeafNode) transform) {
  if (tree is LeafNode) return tree.id == leafId ? transform(tree) : tree;
  if (tree is SplitNode) {
    return tree.copyWith(
      first: mapLeaf(tree.first, leafId, transform),
      second: mapLeaf(tree.second, leafId, transform),
    );
  }
  return tree;
}

/// Update a SplitNode ratio.
PaneNode updateRatio(PaneNode tree, String splitNodeId, double ratio) {
  if (tree is SplitNode) {
    if (tree.id == splitNodeId) return tree.copyWith(ratio: ratio.clamp(0.1, 0.9));
    return tree.copyWith(
      first: updateRatio(tree.first, splitNodeId, ratio),
      second: updateRatio(tree.second, splitNodeId, ratio),
    );
  }
  return tree;
}

/// Collect all leaf ids in order (left-to-right, top-to-bottom).
List<String> collectLeafIds(PaneNode tree) {
  if (tree is LeafNode) return [tree.id];
  if (tree is SplitNode) {
    return [...collectLeafIds(tree.first), ...collectLeafIds(tree.second)];
  }
  return [];
}
