import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_node.dart';
import '../providers/workspace_provider.dart';
import 'panel_container.dart';

/// 侧边栏文件管理面板
///
/// 每个文件项都有拖拽把手图标，用户可以：
/// 1. 点击文件名：在活跃面板旁自动分割打开
/// 2. 从拖拽把手拖出：拖入目标面板，根据放下位置决定分割方向
class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  final List<_FileItem> _files = const [
    _FileItem(name: '会议记录.md', icon: Icons.description, type: PanelType.markdown),
    _FileItem(name: '需求文档.md', icon: Icons.description, type: PanelType.markdown),
    _FileItem(name: '灵感随笔.md', icon: Icons.description, type: PanelType.markdown),
    _FileItem(name: '学习笔记.md', icon: Icons.description, type: PanelType.markdown),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.folder_open, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('工作区',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface)),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),

          // 文件列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: _files.map((file) => _buildFileItem(context, file)).toList(),
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // 底部操作区
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildActionButton(context, icon: Icons.note_add, label: '新建笔记',
                    onTap: () => _openNew(PanelType.markdown, '未命名.md')),
                const SizedBox(height: 4),
                _buildActionButton(context, icon: Icons.smart_toy, label: '新建 AI 对话',
                    onTap: () => _openNew(PanelType.aiChat, 'AI Agent')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, _FileItem file) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = PanelContent(
      type: file.type,
      title: file.name,
      filePath: file.name,
    );

    // 整行都是 Draggable
    return Draggable<PanelDragData>(
      data: PanelDragData(content: content),
      // 拖拽时跟随指针的浮动卡片
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.primaryContainer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(file.icon, size: 16, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(file.name, style: TextStyle(
                  fontSize: 13, color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500, decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
      // 拖拽时原位显示半透明
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFileRow(file, colorScheme),
      ),
      // 正常状态：可点击
      child: InkWell(
        onTap: () => _openFileByClick(content),
        child: _buildFileRow(file, colorScheme),
      ),
    );
  }

  Widget _buildFileRow(_FileItem file, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(width: 4),
          Icon(file.icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(file.name,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: colorScheme.primary,
                fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _openFileByClick(PanelContent content) {
    final workspace = ref.read(workspaceProvider);
    final targetId = workspace.activePanelId ?? _findFirstLeafId(workspace.rootNode);
    ref.read(workspaceProvider.notifier).splitPanel(
          targetId, SplitDirection.vertical, content);
  }

  void _openNew(PanelType type, String title) {
    final workspace = ref.read(workspaceProvider);
    final targetId = workspace.activePanelId ?? _findFirstLeafId(workspace.rootNode);
    ref.read(workspaceProvider.notifier).splitPanel(
          targetId, SplitDirection.vertical, PanelContent(type: type, title: title));
  }

  String _findFirstLeafId(SplitNode node) {
    if (node is LeafNode) return node.content.id;
    if (node is BranchNode) return _findFirstLeafId(node.first);
    return '';
  }
}

class _FileItem {
  final String name;
  final IconData icon;
  final PanelType type;
  const _FileItem({required this.name, required this.icon, required this.type});
}
