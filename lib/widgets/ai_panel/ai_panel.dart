import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/drag_payload.dart';
import '../../models/workspace_file.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workspace_provider.dart';
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

  /// Whether we are showing the session list page (vs. the chat view).
  bool _showSessionList = false;

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

  void _showRenameDialog(
      BuildContext ctx, String sessionId, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '重命名对话',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '对话名称',
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onSubmitted: (v) => Navigator.of(dCtx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dCtx).pop(ctrl.text),
            child: const Text('确认'),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name.trim().isNotEmpty) {
        ref.read(chatProvider.notifier).renameSession(sessionId, name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final surface =
        isDark ? AppColors.darkSurface1 : AppColors.lightSurface1;
    final primary =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    ref.listen(chatProvider, (prev, next) {
      if (!_showSessionList && next.current.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return DragTarget<DragPayload>(
      onWillAcceptWithDetails: (details) {
        final d = details.data;
        if (d is FilePathPayload) return true;
        if (d is TitleBarPayload) return d.filePath != null;
        return false;
      },
      onMove: (_) => setState(() => _dropHover = true),
      onLeave: (_) => setState(() => _dropHover = false),
      onAcceptWithDetails: (details) {
        setState(() => _dropHover = false);
        String? filePath;
        if (details.data is FilePathPayload) {
          filePath = (details.data as FilePathPayload).filePath;
        } else if (details.data is TitleBarPayload) {
          filePath = (details.data as TitleBarPayload).filePath;
        }
        if (filePath != null) {
          ref.read(chatProvider.notifier).addContextFile(filePath);
        }
      },
      builder: (context, candidates, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: surface,
            border: _dropHover
                ? Border.all(color: primary, width: 2)
                : null,
          ),
          child: _showSessionList
              ? _buildSessionList(context, chat)
              : _buildChatView(context, chat),
        );
      },
    );
  }

  // ── Session list page ─────────────────────────────────────────────────────

  Widget _buildSessionList(BuildContext context, ChatState chat) {
    final surface2 =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final primary =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Column(
      children: [
        // Header bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
          decoration: BoxDecoration(
            color: surface2,
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 16, color: textSecondary),
              const SizedBox(width: AppTheme.sp8),
              Text(
                'AI 对话',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: '新建对话',
                child: InkWell(
                  onTap: () {
                    ref.read(chatProvider.notifier).newSession();
                    setState(() => _showSessionList = false);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Icon(Icons.add, size: 18, color: textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Session list
        Expanded(
          child: chat.sessions.isEmpty
              ? Center(
                  child: Text('暂无对话',
                      style: TextStyle(color: textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.sp8),
                  itemCount: chat.sessions.length,
                  itemBuilder: (ctx, i) {
                    final s = chat.sessions[i];
                    final isCurrent = s.id == chat.currentSessionId;
                    final lastMsg = s.messages.isEmpty
                        ? '暂无消息'
                        : s.messages.last.content;

                    return InkWell(
                      onTap: () {
                        ref
                            .read(chatProvider.notifier)
                            .switchSession(s.id);
                        setState(() => _showSessionList = false);
                      },
                      onLongPress: () =>
                          _showRenameDialog(context, s.id, s.name),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.sp8, vertical: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.sp12,
                            vertical: AppTheme.sp8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? primary.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(
                                  color: primary.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 16,
                              color: isCurrent ? primary : textSecondary,
                            ),
                            const SizedBox(width: AppTheme.sp8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCurrent
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isCurrent
                                          ? primary
                                          : textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastMsg,
                                    style: TextStyle(
                                        fontSize: 11, color: textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.sp8),
                            // Delete button
                            GestureDetector(
                              onTap: () => ref
                                  .read(chatProvider.notifier)
                                  .deleteSession(s.id),
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                child: Icon(Icons.delete_outline,
                                    size: 16, color: textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Chat view ─────────────────────────────────────────────────────────────

  Widget _buildChatView(BuildContext context, ChatState chat) {
    final surface2 =
        isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final primary =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final current = chat.current;

    return Column(
      children: [
        // ── Top bar: [<-] [session name] [settings] ──────────────────────
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
          decoration: BoxDecoration(
            color: surface2,
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              // Back to session list
              Tooltip(
                message: '所有对话',
                child: InkWell(
                  onTap: () => setState(() => _showSessionList = true),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 16, color: textSecondary),
                  ),
                ),
              ),
              // Session name (double-tap to rename)
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _showRenameDialog(
                      context, current.id, current.name),
                  child: Text(
                    current.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Settings
              Tooltip(
                message: '设置',
                child: InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SettingsSheet(),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(Icons.settings_outlined,
                        size: 16, color: textSecondary),
                  ),
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
                    size: 14, color: primary),
                const SizedBox(width: 6),
                Text('松手添加为上下文',
                    style: TextStyle(fontSize: 12, color: primary)),
              ],
            ),
          ),

        // Message list
        Expanded(
          child: current.messages.isEmpty
              ? _EmptyChat(isDark: isDark)
              : ListView.builder(
                  key: ValueKey(chat.currentSessionId),
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.sp8),
                  itemCount: current.messages.length,
                  itemBuilder: (context, index) => ChatMessageItem(
                    message: current.messages[index],
                    isDark: isDark,
                  ),
                ),
        ),

        // Context file chips
        if (current.contextFilePaths.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp8, vertical: AppTheme.sp6),
            decoration: BoxDecoration(
              color: surface2,
              border: Border(top: BorderSide(color: border)),
            ),
            child: Wrap(
              spacing: AppTheme.sp4,
              runSpacing: AppTheme.sp4,
              children: current.contextFilePaths
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
    );
  }
}

// ── Empty chat placeholder ────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final bool isDark;
  const _EmptyChat({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final primary =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined,
              size: 40, color: primary.withOpacity(0.4)),
          const SizedBox(height: AppTheme.sp12),
          Text('AI 助手',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textMuted)),
          const SizedBox(height: AppTheme.sp8),
          Text('从文件列表拖入，或点 + 添加上下文\nPDF 和文本文件内容将自动提取并附加',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted)),
        ],
      ),
    );
  }
}

// ── Chat input bar ────────────────────────────────────────────────────────────

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

  /// Shows a popup menu anchored above the [+] button to pick a context file.
  Future<void> _pickContextFile(BuildContext btnCtx) async {
    final files = ref.read(workspaceProvider);
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('工作区暂无文件，请先添加文件')),
      );
      return;
    }

    final isDark = widget.isDark;
    final RenderBox button =
        btnCtx.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset pos =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    final result = await showMenu<WorkspaceFile>(
      context: context,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy - 8,
        overlay.size.width - pos.dx - button.size.width,
        overlay.size.height - pos.dy,
      ),
      items: files.map((f) {
        final ext = f.name.split('.').last.toLowerCase();
        return PopupMenuItem<WorkspaceFile>(
          value: f,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                ext == 'pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  f.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
      elevation: 8,
    );

    if (result != null) {
      ref.read(chatProvider.notifier).addContextFile(result.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = ref.watch(chatProvider).canSend;
    final isStreaming = ref.watch(chatProvider).current.isStreaming;
    final surface2 =
        widget.isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final surface3 =
        widget.isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
    final border = widget.isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final primary =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surface2,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppTheme.sp8, AppTheme.sp8, AppTheme.sp8, AppTheme.sp6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Text input ─────────────────────────────────────────────────
          Container(
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

          const SizedBox(height: AppTheme.sp6),

          // ── Bottom toolbar: [+] [model ───────] [send] ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // + Add context file (uses Builder for local context)
              Builder(
                builder: (btnCtx) => Tooltip(
                  message: '添加文件上下文',
                  child: InkWell(
                    onTap: () => _pickContextFile(btnCtx),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 28,
                      alignment: Alignment.center,
                      child: Icon(Icons.add_circle_outline,
                          size: 18, color: textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.sp4),
              // Model selector – Expanded so it fills middle and never overflows
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ModelSelector(isDark: widget.isDark),
                ),
              ),
              // Send button
              GestureDetector(
                onTap: canSend ? _send : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: canSend
                        ? primary
                        : primary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isStreaming
                      ? const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(Icons.send,
                          color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Model selector ────────────────────────────────────────────────────────────

class _ModelSelector extends ConsumerWidget {
  final bool isDark;
  const _ModelSelector({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: kAvailableModels.contains(settings.model)
            ? settings.model
            : kAvailableModels.first,
        items: kAvailableModels.map((m) {
          return DropdownMenuItem(
            value: m,
            child: Text(m,
                style: TextStyle(fontSize: 12, color: textSecondary)),
          );
        }).toList(),
        onChanged: (model) {
          if (model != null) {
            ref.read(settingsProvider.notifier).save(model: model);
          }
        },
        isDense: true,
        dropdownColor:
            isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        style: TextStyle(fontSize: 12, color: textSecondary),
        icon:
            Icon(Icons.keyboard_arrow_down, size: 14, color: textSecondary),
      ),
    );
  }
}
