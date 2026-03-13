import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 分割方向
enum SplitDirection {
  horizontal, // 横向分割（上下排列）
  vertical,   // 纵向分割（左右排列）
}

/// 面板内容类型
enum PanelType {
  markdown,
  aiChat,
  empty, // 用于欢迎页或起始面板
}

/// 面板内容数据
class PanelContent {
  final String id;
  final PanelType type;
  final String title;
  final String? filePath; // MD 面板对应的文件路径

  PanelContent({
    String? id,
    required this.type,
    required this.title,
    this.filePath,
  }) : id = id ?? _uuid.v4();

  PanelContent copyWith({
    PanelType? type,
    String? title,
    String? filePath,
  }) {
    return PanelContent(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
    );
  }
}

/// 递归分区树节点
///
/// 采用类似 VS Code Editor Group 的设计：
/// - 叶子节点 (LeafNode): 包含具体面板内容
/// - 分支节点 (BranchNode): 包含分割方向、比例和两个子节点
sealed class SplitNode {
  final String id;

  SplitNode({String? id}) : id = id ?? _uuid.v4();
}

/// 叶子节点——包含一个实际的面板
class LeafNode extends SplitNode {
  final PanelContent content;

  LeafNode({
    super.id,
    required this.content,
  });

  LeafNode copyWith({PanelContent? content}) {
    return LeafNode(
      id: id,
      content: content ?? this.content,
    );
  }
}

/// 分支节点——将空间分割为两个子区域
class BranchNode extends SplitNode {
  final SplitDirection direction;
  final double ratio; // 第一个子节点占据的比例 (0.0 ~ 1.0)
  final SplitNode first;
  final SplitNode second;

  BranchNode({
    super.id,
    required this.direction,
    this.ratio = 0.5,
    required this.first,
    required this.second,
  });

  BranchNode copyWith({
    SplitDirection? direction,
    double? ratio,
    SplitNode? first,
    SplitNode? second,
  }) {
    return BranchNode(
      id: id,
      direction: direction ?? this.direction,
      ratio: ratio ?? this.ratio,
      first: first ?? this.first,
      second: second ?? this.second,
    );
  }
}
