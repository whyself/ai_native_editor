import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/drag_payload.dart';
import '../../models/workspace_file.dart';
import '../../providers/workspace_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class FilePanel extends ConsumerWidget {
  const FilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(workspaceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final surface2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;

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
              // Add file button
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
                    return FileListItem(
                      file: files[index],
                      isDark: isDark,
                      onRemove: () =>
                          ref.read(workspaceProvider.notifier).removeFile(files[index].path),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AddFileButton extends ConsumerWidget {
  final bool isDark;
  const _AddFileButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: '添加文件',
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
            Icons.add,
            size: 18,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

class FileListItem extends StatelessWidget {
  final WorkspaceFile file;
  final bool isDark;
  final VoidCallback onRemove;

  const FileListItem({
    super.key,
    required this.file,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final hoverColor = isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;

    return LongPressDraggable<DragPayload>(
      data: FilePathPayload(file.path),
      delay: const Duration(milliseconds: 300),
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
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              const SizedBox(width: 6),
              Text(
                file.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _ItemContent(
            file: file, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted),
      ),
      child: _ItemContent(
        file: file,
        isDark: isDark,
        textPrimary: textPrimary,
        textMuted: textMuted,
        onRemove: onRemove,
      ),
    );
  }
}

class _ItemContent extends StatefulWidget {
  final WorkspaceFile file;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onRemove;

  const _ItemContent({
    required this.file,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    this.onRemove,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
        color: _hovered ? hoverColor : Colors.transparent,
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 14,
              color: widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(width: AppTheme.sp8),
            Expanded(
              child: Text(
                widget.file.name,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.textPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_hovered && widget.onRemove != null)
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: widget.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 36, color: textMuted),
          const SizedBox(height: AppTheme.sp8),
          Text(
            '点击 + 添加文件',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ],
      ),
    );
  }
}
