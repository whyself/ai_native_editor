import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/drag_payload.dart';
import '../../models/pane_node.dart';
import '../../models/workspace_file.dart';
import '../../providers/pane_tree_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class FilePanel extends ConsumerWidget {
  const FilePanel({super.key});

  /// Open [filePath] in the editor:
  /// - if the first leaf is empty → openFile (replace)
  /// - otherwise → split alongside first leaf (add as right sibling)
  void _openOrSplit(WidgetRef ref, String filePath) {
    final paneTree = ref.read(paneTreeProvider);
    final leafIds = collectLeafIds(paneTree);
    if (leafIds.isEmpty) return;
    final firstLeaf = findNode(paneTree, leafIds.first);
    if (firstLeaf is LeafNode && firstLeaf.filePath == null) {
      ref.read(paneTreeProvider.notifier).openFile(leafIds.first, filePath);
    } else {
      ref
          .read(paneTreeProvider.notifier)
          .splitWithFile(leafIds.first, filePath, DropZone.right);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(workspaceProvider);
    final paneTree = ref.watch(paneTreeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    // Build set of file paths currently open in any leaf.
    final openPaths = collectLeafIds(paneTree)
        .map((id) => findNode(paneTree, id))
        .whereType<LeafNode>()
        .where((n) => n.filePath != null)
        .map((n) => n.filePath!)
        .toSet();

    return Column(
      children: [
        // Panel header
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Text(
                '工作区',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // New file button
              _NewFileButton(isDark: isDark),
              const SizedBox(width: AppTheme.sp4),
              // Add existing file button
              _AddFileButton(isDark: isDark),
            ],
          ),
        ),

        // File list
        Expanded(
          child: files.isEmpty
              ? _EmptyState(isDark: isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.sp4),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final filePath = files[index].path;
                    return FileListItem(
                      file: files[index],
                      isDark: isDark,
                      isOpen: openPaths.contains(filePath),
                      onRemove: () => ref
                          .read(workspaceProvider.notifier)
                          .removeFile(filePath),
                      onOpen: () => _openOrSplit(ref, filePath),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---- New File Button ----

class _NewFileButton extends ConsumerWidget {
  final bool isDark;
  const _NewFileButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: '新建 Markdown 文件',
      child: InkWell(
        onTap: () => _createNewFile(context, ref),
        borderRadius: BorderRadius.circular(AppTheme.radius4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            Icons.note_add_outlined,
            size: 18,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _createNewFile(BuildContext context, WidgetRef ref) async {
    // 1. Ask for filename
    final filename = await _showFilenameDialog(context);
    if (filename == null || filename.trim().isEmpty) return;

    final name =
        filename.trim().endsWith('.md') ? filename.trim() : '${filename.trim()}.md';

    // 2. 保存到应用文档目录（无需任何 Android 权限，始终可写）
    final docsDir = await getApplicationDocumentsDirectory();
    final finalPath = p.join(docsDir.path, name);

    // 3. Write default content
    const defaultContent = '# 新文档\n\n';
    final ok = await FileService.instance.writeFile(finalPath, defaultContent);

    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建文件失败，请检查路径权限')),
        );
      }
      return;
    }

    // 4. Add to workspace
    ref.read(workspaceProvider.notifier).addFiles([finalPath]);

    // Show success snackbar with save path
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已创建：$finalPath'),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // 5. Open in editor: empty first leaf → replace, otherwise → sibling split
    final paneTree = ref.read(paneTreeProvider);
    final leafIds = collectLeafIds(paneTree);
    if (leafIds.isNotEmpty) {
      final firstLeaf = findNode(paneTree, leafIds.first);
      if (firstLeaf is LeafNode && firstLeaf.filePath == null) {
        ref.read(paneTreeProvider.notifier).openFile(leafIds.first, finalPath);
      } else {
        ref
            .read(paneTreeProvider.notifier)
            .splitWithFile(leafIds.first, finalPath, DropZone.right);
      }
    }
  }

  Future<String?> _showFilenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: 'untitled');
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = isDark ? AppColors.darkSurface2 : AppColors.lightSurface1;
        final textPrimary =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final borderColor =
            isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
          ),
          title: Text(
            '新建 Markdown 文件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: '文件名（无需填写 .md 扩展名）',
              hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted),
              suffixText: '.md',
              suffixStyle:
                  TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius8),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('取消',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius6)),
              ),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
}

// ---- Add Existing File Button ----

class _AddFileButton extends ConsumerWidget {
  final bool isDark;
  const _AddFileButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: '添加已有文件',
      child: InkWell(
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: ['md', 'markdown', 'txt'],
          );
          if (result != null) {
            final paths = result.paths.whereType<String>().toList();
            ref.read(workspaceProvider.notifier).addFiles(paths);
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radius4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            Icons.folder_open_outlined,
            size: 18,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ---- File List Item ----

class FileListItem extends StatelessWidget {
  final WorkspaceFile file;
  final bool isDark;
  final bool isOpen;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const FileListItem({
    super.key,
    required this.file,
    required this.isDark,
    required this.isOpen,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return LongPressDraggable<DragPayload>(
      data: FilePathPayload(file.path),
      delay: const Duration(milliseconds: 400),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface3 : AppColors.lightSurface3,
            borderRadius: BorderRadius.circular(AppTheme.radius6),
            border: Border.all(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 14,
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              const SizedBox(width: 6),
              Text(
                file.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _ItemContent(
            file: file,
            isDark: isDark,
            isOpen: isOpen,
            textPrimary: textPrimary,
            textMuted: textMuted),
      ),
      child: _ItemContent(
        file: file,
        isDark: isDark,
        isOpen: isOpen,
        textPrimary: textPrimary,
        textMuted: textMuted,
        onRemove: onRemove,
        onOpen: onOpen,
      ),
    );
  }
}

class _ItemContent extends StatefulWidget {
  final WorkspaceFile file;
  final bool isDark;
  final bool isOpen;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;

  const _ItemContent({
    required this.file,
    required this.isDark,
    required this.isOpen,
    required this.textPrimary,
    required this.textMuted,
    this.onRemove,
    this.onOpen,
  });

  @override
  State<_ItemContent> createState() => _ItemContentState();
}

class _ItemContentState extends State<_ItemContent> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor =
        widget.isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
    final primary =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final openBg = primary.withOpacity(0.08);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOpen,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: widget.isOpen
                ? openBg
                : (_hovered ? hoverColor : Colors.transparent),
            border: widget.isOpen
                ? Border(
                    left: BorderSide(color: primary, width: 2),
                  )
                : null,
          ),
          padding: EdgeInsets.only(
            left: widget.isOpen ? AppTheme.sp12 - 2 : AppTheme.sp12,
            right: AppTheme.sp12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 14,
                color: widget.isOpen
                    ? primary
                    : (widget.isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
              const SizedBox(width: AppTheme.sp8),
              Expanded(
                child: Text(
                  widget.file.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isOpen
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.isOpen ? primary : widget.textPrimary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_hovered && widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(Icons.close, size: 14, color: widget.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Empty State ----

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 36, color: textMuted),
          const SizedBox(height: AppTheme.sp8),
          Text(
            '📝 新建  或  📂 添加文件',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ],
      ),
    );
  }
}
