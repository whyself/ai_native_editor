import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class ContextFileChip extends StatelessWidget {
  final String filePath;
  final bool isDark;
  final VoidCallback onRemove;

  const ContextFileChip({
    super.key,
    required this.filePath,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = filePath.split(RegExp(r'[/\\]')).last;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark
        ? AppColors.darkPrimary.withOpacity(0.12)
        : AppColors.lightPrimary.withOpacity(0.1);
    final border = isDark
        ? AppColors.darkPrimary.withOpacity(0.3)
        : AppColors.lightPrimary.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radius4),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 12, color: primary),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: primary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: primary),
          ),
        ],
      ),
    );
  }
}
