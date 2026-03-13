import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/layout_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../ai_panel/ai_panel.dart';
import '../editor/pane_tree_widget.dart';
import '../file_panel/file_panel.dart';
import 'resize_divider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutProvider);
    final notifier = ref.read(layoutProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface1 : AppColors.lightSurface1;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top toolbar
            _TopBar(isDark: isDark),
            // Main content row
            Expanded(
              child: Row(
                children: [
                  // Left panel
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: layout.leftVisible ? layout.leftWidth : 0,
                      child: layout.leftVisible
                          ? Container(
                              color: surfaceColor,
                              child: const FilePanel(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Left divider
                  if (layout.leftVisible)
                    ResizeDivider(
                      axis: Axis.vertical,
                      onDrag: (delta) => notifier.resizeLeft(delta),
                      onDoubleTap: () => ref
                          .read(layoutProvider.notifier)
                          .resizeLeft(LayoutState.defaultLeftWidth - layout.leftWidth),
                    ),

                  // Center editor area
                  const Expanded(
                    child: PaneTreeWidget(),
                  ),

                  // Right divider
                  if (layout.rightVisible)
                    ResizeDivider(
                      axis: Axis.vertical,
                      onDrag: (delta) => notifier.resizeRight(delta),
                      onDoubleTap: () => ref
                          .read(layoutProvider.notifier)
                          .resizeRight(-(LayoutState.defaultRightWidth - layout.rightWidth)),
                    ),

                  // Right panel
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: layout.rightVisible ? layout.rightWidth : 0,
                      child: layout.rightVisible
                          ? Container(
                              color: surfaceColor,
                              child: const AiPanel(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final bool isDark;
  const _TopBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final layout = ref.watch(layoutProvider);
    final notifier = ref.read(layoutProvider.notifier);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
      child: Row(
        children: [
          // Left panel toggle
          _ToolbarBtn(
            icon: Icons.view_sidebar_outlined,
            tooltip: layout.leftVisible ? '隐藏文件面板' : '显示文件面板',
            isActive: layout.leftVisible,
            onTap: notifier.toggleLeft,
            isDark: isDark,
          ),
          const SizedBox(width: AppTheme.sp4),
          // App title
          Expanded(
            child: Text(
              'AI Native Editor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Right panel toggle
          _ToolbarBtn(
            icon: Icons.smart_toy_outlined,
            tooltip: layout.rightVisible ? '隐藏 AI 助手' : '显示 AI 助手',
            isActive: layout.rightVisible,
            onTap: notifier.toggleRight,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius6),
        child: Container(
          width: AppTheme.touchTarget,
          height: AppTheme.touchTarget,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isActive ? primary : secondary,
          ),
        ),
      ),
    );
  }
}
