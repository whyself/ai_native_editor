import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_node.dart';

/// 工作区状态
class WorkspaceState {
  final SplitNode rootNode;
  final String? activePanelId; // 当前高亮/聚焦的面板 ID

  const WorkspaceState({
    required this.rootNode,
    this.activePanelId,
  });

  WorkspaceState copyWith({
    SplitNode? rootNode,
    String? activePanelId,
  }) {
    return WorkspaceState(
      rootNode: rootNode ?? this.rootNode,
      activePanelId: activePanelId ?? this.activePanelId,
    );
  }
}

/// 工作区状态管理 Notifier
class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier()
      : super(
          WorkspaceState(
            rootNode: LeafNode(
              content: PanelContent(
                type: PanelType.empty,
                title: '欢迎',
              ),
            ),
          ),
        );

  /// 设置活跃面板
  void setActivePanel(String panelId) {
    state = state.copyWith(activePanelId: panelId);
  }

  /// 在指定面板旁边分割插入新面板
  void splitPanel(
    String targetPanelId,
    SplitDirection direction,
    PanelContent newContent, {
    bool insertBefore = false,
  }) {
    final newRoot = _splitAt(state.rootNode, targetPanelId, direction, newContent, insertBefore);
    if (newRoot != null) {
      state = state.copyWith(
        rootNode: newRoot,
        activePanelId: newContent.id,
      );
    }
  }

  /// 关闭面板（从分区树中移除）
  void closePanel(String panelId) {
    final result = _removeNode(state.rootNode, panelId);
    if (result != null) {
      state = state.copyWith(
        rootNode: result,
        activePanelId: state.activePanelId == panelId ? null : state.activePanelId,
      );
    }
  }

  /// 更新分割比例（用于拖拽分割线）
  void updateRatio(String branchNodeId, double newRatio) {
    final clamped = newRatio.clamp(0.15, 0.85); // 最小/最大比例限制
    final newRoot = _updateRatio(state.rootNode, branchNodeId, clamped);
    if (newRoot != null) {
      state = state.copyWith(rootNode: newRoot);
    }
  }

  /// 替换指定叶子的内容（例如打开新文件到现有面板）
  void replacePanelContent(String panelId, PanelContent newContent) {
    final newRoot = _replaceContent(state.rootNode, panelId, newContent);
    if (newRoot != null) {
      state = state.copyWith(rootNode: newRoot);
    }
  }

  // === 递归操作辅助方法 ===

  /// 在目标叶子节点处拆分
  SplitNode? _splitAt(
    SplitNode node,
    String targetId,
    SplitDirection direction,
    PanelContent newContent,
    bool insertBefore,
  ) {
    switch (node) {
      case LeafNode():
        if (node.content.id == targetId) {
          final newLeaf = LeafNode(content: newContent);
          return BranchNode(
            direction: direction,
            ratio: 0.5,
            first: insertBefore ? newLeaf : node,
            second: insertBefore ? node : newLeaf,
          );
        }
        return node;
      case BranchNode():
        final newFirst = _splitAt(node.first, targetId, direction, newContent, insertBefore);
        final newSecond = _splitAt(node.second, targetId, direction, newContent, insertBefore);
        if (newFirst != node.first || newSecond != node.second) {
          return node.copyWith(first: newFirst, second: newSecond);
        }
        return node;
    }
  }

  /// 移除指定面板，返回剩余的树
  SplitNode? _removeNode(SplitNode node, String targetId) {
    switch (node) {
      case LeafNode():
        if (node.content.id == targetId) {
          return null; // 需要移除这个节点
        }
        return node;
      case BranchNode():
        final newFirst = _removeNode(node.first, targetId);
        final newSecond = _removeNode(node.second, targetId);

        if (newFirst == null && newSecond == null) return null;
        if (newFirst == null) return newSecond;
        if (newSecond == null) return newFirst;

        if (newFirst != node.first || newSecond != node.second) {
          return node.copyWith(first: newFirst, second: newSecond);
        }
        return node;
    }
  }

  /// 更新指定分支节点的比例
  SplitNode? _updateRatio(SplitNode node, String branchId, double newRatio) {
    switch (node) {
      case LeafNode():
        return node;
      case BranchNode():
        if (node.id == branchId) {
          return node.copyWith(ratio: newRatio);
        }
        final newFirst = _updateRatio(node.first, branchId, newRatio);
        final newSecond = _updateRatio(node.second, branchId, newRatio);
        if (newFirst != node.first || newSecond != node.second) {
          return node.copyWith(first: newFirst, second: newSecond);
        }
        return node;
    }
  }

  /// 替换指定叶子节点的内容
  SplitNode? _replaceContent(SplitNode node, String panelId, PanelContent newContent) {
    switch (node) {
      case LeafNode():
        if (node.content.id == panelId) {
          return node.copyWith(content: newContent);
        }
        return node;
      case BranchNode():
        final newFirst = _replaceContent(node.first, panelId, newContent);
        final newSecond = _replaceContent(node.second, panelId, newContent);
        if (newFirst != node.first || newSecond != node.second) {
          return node.copyWith(first: newFirst, second: newSecond);
        }
        return node;
    }
  }
}

/// 全局 Provider
final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>(
  (ref) => WorkspaceNotifier(),
);
