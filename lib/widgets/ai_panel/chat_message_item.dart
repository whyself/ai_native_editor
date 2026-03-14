import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_message.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp12, vertical: AppTheme.sp4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Context file tags (user messages only)
          if (isUser && message.contextFilePaths.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: message.contextFilePaths.map((path) {
                final rawName = path.split(RegExp(r'[/\\]')).last;
                final name = rawName.length > 18
                    ? '${rawName.substring(0, 15)}…'
                    : rawName;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimary.withOpacity(0.15)
                        : AppColors.lightPrimary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radius4),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkPrimary.withOpacity(0.4)
                          : AppColors.lightPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 11,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.sp4),
          ],

          // Message bubble
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp12, vertical: AppTheme.sp8),
            decoration: BoxDecoration(
              color: isUser
                  ? (isDark
                      ? AppColors.darkUserBubble
                      : AppColors.lightUserBubble)
                  : (isDark
                      ? AppColors.darkAiBubble
                      : AppColors.lightAiBubble),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 12),
              ),
            ),
            child: isUser
                ? Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  )
                : message.isStreaming && message.content.isEmpty
                    ? _StreamingIndicator(isDark: isDark)
                    : MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          code: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9B8DF7)
                                : AppColors.lightPrimary,
                            backgroundColor: isDark
                                ? AppColors.darkSurface3
                                : AppColors.lightSurface3,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface3
                                : AppColors.lightSurface3,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radius6),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StreamingIndicator extends StatefulWidget {
  final bool isDark;
  const _StreamingIndicator({required this.isDark});

  @override
  State<_StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<_StreamingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return FadeTransition(
      opacity: _ctrl,
      child: Text(
        '▋',
        style: TextStyle(color: color, fontSize: 14),
      ),
    );
  }
}
