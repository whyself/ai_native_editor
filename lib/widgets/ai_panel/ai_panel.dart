import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/drag_payload.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/qwen_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_sheet.dart';
import 'chat_message_item.dart';
import 'context_file_chip.dart';

class AiPanel extends ConsumerStatefulWidget {
  const AiPanel({super.key});

  @override
  ConsumerState<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends ConsumerState<AiPanel> {
  final _scrollController = ScrollController();
  bool _dropHover = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final surface = isDark ? AppColors.darkSurface1 : AppColors.lightSurface1;
    final surface2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Scroll to bottom when new messages arrive
    ref.listen(chatProvider, (_, next) {
      if (next.messages.isNotEmpty) _scrollToBottom();
    });

    return DragTarget<DragPayload>(
      onWillAcceptWithDetails: (details) => details.data is FilePathPayload,
      onMove: (_) => setState(() => _dropHover = true),
      onLeave: (_) => setState(() => _dropHover = false),
      onAcceptWithDetails: (details) {
        setState(() => _dropHover = false);
        if (details.data is FilePathPayload) {
          ref
              .read(chatProvider.notifier)
              .addContextFile((details.data as FilePathPayload).filePath);
        }
      },
      builder: (context, candidates, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: surface,
            border: _dropHover
                ? Border.all(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            children: [
              // Panel header
              Container(
                height: 40,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
                decoration: BoxDecoration(
                  color: surface2,
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined,
                        size: 16, color: textSecondary),
                    const SizedBox(width: AppTheme.sp8),
                    Expanded(
                      child: _ModelSelector(isDark: isDark),
                    ),
                    // Settings button
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SettingsSheet(),
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.settings_outlined,
                            size: 16, color: textSecondary),
                      ),
                    ),
                    // Clear chat
                    if (chat.messages.isNotEmpty)
                      GestureDetector(
                        onTap: () => ref.read(chatProvider.notifier).clearChat(),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(Icons.delete_sweep_outlined,
                              size: 16, color: textSecondary),
                        ),
                      ),
                  ],
                ),
              ),

              // Drop hint
              if (_dropHover)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  color: isDark
                      ? AppColors.darkPrimary.withOpacity(0.1)
                      : AppColors.lightPrimary.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 14,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '松手添加为上下文',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Message list
              Expanded(
                child: chat.messages.isEmpty
                    ? _EmptyChat(isDark: isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.sp8),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) => ChatMessageItem(
                          message: chat.messages[index],
                          isDark: isDark,
                        ),
                      ),
              ),

              // Context file chips
              if (chat.contextFilePaths.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp8, vertical: AppTheme.sp6),
                  decoration: BoxDecoration(
                    color: surface2,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: Wrap(
                    spacing: AppTheme.sp4,
                    runSpacing: AppTheme.sp4,
                    children: chat.contextFilePaths
                        .map(
                          (path) => ContextFileChip(
                            filePath: path,
                            isDark: isDark,
                            onRemove: () => ref
                                .read(chatProvider.notifier)
                                .removeContextFile(path),
                          ),
                        )
                        .toList(),
                  ),
                ),

              // Input bar
              _ChatInputBar(isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

class _ModelSelector extends ConsumerWidget {
  final bool isDark;
  const _ModelSelector({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface3 = isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: kAvailableModels.contains(settings.model)
            ? settings.model
            : kAvailableModels.first,
        items: kAvailableModels
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text(m,
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ),
            )
            .toList(),
        onChanged: (model) {
          if (model != null) {
            ref.read(settingsProvider.notifier).save(model: model);
          }
        },
        isDense: true,
        dropdownColor:
            isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        style: TextStyle(fontSize: 12, color: textSecondary),
        icon: Icon(Icons.keyboard_arrow_down,
            size: 14, color: textSecondary),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final bool isDark;
  const _EmptyChat({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined, size: 40,
              color: primary.withOpacity(0.4)),
          const SizedBox(height: AppTheme.sp12),
          Text('AI 助手',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textMuted)),
          const SizedBox(height: AppTheme.sp8),
          Text('从文件列表拖入文件作为上下文\n然后开始对话',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted)),
        ],
      ),
    );
  }
}

class _ChatInputBar extends ConsumerStatefulWidget {
  final bool isDark;
  const _ChatInputBar({required this.isDark});

  @override
  ConsumerState<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<_ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = ref.watch(chatProvider).canSend;
    final isStreaming = ref.watch(chatProvider).isStreaming;
    final surface2 = widget.isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final surface3 = widget.isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
    final border =
        widget.isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surface2,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.all(AppTheme.sp8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: surface3,
                borderRadius: BorderRadius.circular(AppTheme.radius8),
                border: Border.all(color: border),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                enabled: canSend,
                textInputAction: TextInputAction.send,
                onSubmitted: canSend ? (_) => _send() : null,
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '输入消息...',
                  hintStyle: TextStyle(fontSize: 14, color: textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.sp8),
          GestureDetector(
            onTap: canSend ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: canSend
                    ? primary
                    : primary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
              child: isStreaming
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
