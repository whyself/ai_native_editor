import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/file_service.dart';
import '../services/persistence_service.dart';
import '../services/qwen_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class ChatState {
  final List<ChatSession> sessions;
  final String currentSessionId;

  const ChatState({
    required this.sessions,
    required this.currentSessionId,
  });

  ChatSession get current =>
      sessions.firstWhere((s) => s.id == currentSessionId);

  bool get canSend => !current.isStreaming;

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? currentSessionId,
  }) =>
      ChatState(
        sessions: sessions ?? this.sessions,
        currentSessionId: currentSessionId ?? this.currentSessionId,
      );

  /// Return a new state with the current session replaced by [updated].
  ChatState withUpdatedCurrent(ChatSession updated) => copyWith(
        sessions: sessions
            .map((s) => s.id == updated.id ? updated : s)
            .toList(),
      );
}

ChatState _defaultState() {
  final first = ChatSession(id: _uuid.v4(), name: '对话 1');
  return ChatState(sessions: [first], currentSessionId: first.id);
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final saved = PersistenceService.instance.loadChatSessions();
    if (saved.sessions != null && (saved.sessions as List).isNotEmpty) {
      try {
        final sessions = (saved.sessions as List)
            .map((j) => ChatSession.fromJson(j as Map<String, dynamic>))
            .toList();
        final activeId = saved.activeId ?? sessions.first.id;
        final validId = sessions.any((s) => s.id == activeId)
            ? activeId
            : sessions.first.id;
        return ChatState(sessions: sessions, currentSessionId: validId);
      } catch (_) {}
    }
    return _defaultState();
  }

  void _persist() {
    PersistenceService.instance.saveChatSessions(
      state.sessions.map((s) => s.toJson()).toList(),
      state.currentSessionId,
    );
  }

  // ── Session management ───────────────────────────────────────────────────

  void newSession() {
    final n = state.sessions.length + 1;
    final session = ChatSession(id: _uuid.v4(), name: '对话 $n');
    state = state.copyWith(
      sessions: [...state.sessions, session],
      currentSessionId: session.id,
    );
    _persist();
  }

  void deleteSession(String id) {
    if (state.sessions.length == 1) {
      // Last session: clear messages instead of deleting
      state = state.withUpdatedCurrent(
        state.current.copyWith(messages: [], contextFilePaths: []),
      );
      _persist();
      return;
    }
    final idx = state.sessions.indexWhere((s) => s.id == id);
    final remaining = state.sessions.where((s) => s.id != id).toList();
    final newActive = id == state.currentSessionId
        ? remaining[idx.clamp(0, remaining.length - 1)].id
        : state.currentSessionId;
    state = ChatState(sessions: remaining, currentSessionId: newActive);
    _persist();
  }

  void switchSession(String id) {
    if (state.currentSessionId == id) return;
    state = state.copyWith(currentSessionId: id);
    _persist();
  }

  void renameSession(String id, String name) {
    if (name.trim().isEmpty) return;
    state = state.copyWith(
      sessions: state.sessions
          .map((s) => s.id == id ? s.copyWith(name: name.trim()) : s)
          .toList(),
    );
    _persist();
  }

  // ── Context files ────────────────────────────────────────────────────────

  void addContextFile(String filePath) {
    final cur = state.current;
    if (cur.contextFilePaths.contains(filePath)) return;
    state = state.withUpdatedCurrent(
      cur.copyWith(
        contextFilePaths: [...cur.contextFilePaths, filePath],
      ),
    );
  }

  void removeContextFile(String filePath) {
    final cur = state.current;
    state = state.withUpdatedCurrent(
      cur.copyWith(
        contextFilePaths:
            cur.contextFilePaths.where((p) => p != filePath).toList(),
      ),
    );
  }

  void clearCurrentChat() {
    state = state.withUpdatedCurrent(
      state.current.copyWith(messages: [], contextFilePaths: []),
    );
    _persist();
  }

  // ── Send message ─────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (!state.canSend || text.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    final qwen = QwenService(
      apiKey: settings.apiKey,
      model: settings.model,
      baseUrl: settings.baseUrl,
    );

    var cur = state.current;

    // ── Auto-name session from first user message ─────────────────────────
    final isDefaultName = RegExp(r'^对话 \d+$').hasMatch(cur.name);
    if (isDefaultName && cur.messages.isEmpty) {
      final snippet = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final autoName =
          snippet.length > 18 ? '${snippet.substring(0, 18)}…' : snippet;
      cur = cur.copyWith(name: autoName);
      state = state.withUpdatedCurrent(cur);
    }
    final contextPaths = List<String>.from(cur.contextFilePaths);
    final previousMessages = List<ChatMessage>.from(cur.messages);

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      contextFilePaths: contextPaths,
    );

    final assistantId = _uuid.v4();
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );

    // ① Show user bubble + loading indicator immediately – UI stays responsive
    state = state.withUpdatedCurrent(
      cur.copyWith(
        messages: [...cur.messages, userMsg, assistantMsg],
        contextFilePaths: [],
        isStreaming: true,
      ),
    );

    try {
      // ② Extract file content in background (compute() keeps UI thread free)
      String contextPrefix = '';
      if (contextPaths.isNotEmpty) {
        final buffer = StringBuffer('以下是用户提供的参考文件：\n\n');
        for (final path in contextPaths) {
          final content = path.toLowerCase().endsWith('.pdf')
              ? await FileService.instance.extractPdfText(path)
              : await FileService.instance.readFileSafe(path);
          final name = path.split(RegExp(r'[/\\]')).last;
          if (content != null) {
            buffer.writeln('--- $name ---');
            buffer.writeln(content);
            buffer.writeln();
          }
        }
        contextPrefix = buffer.toString();
      }

      final userContent =
          contextPrefix.isEmpty ? text : '$contextPrefix用户问题：$text';

      final apiHistory = [
        ...previousMessages.map((m) => ChatMessage(
              id: m.id,
              role: m.role,
              content: m.content,
            )),
        ChatMessage(
            id: userMsg.id, role: MessageRole.user, content: userContent),
      ];

      // ③ Stream API response
      await for (final delta in qwen.chatStream(apiHistory)) {
        final current = state.current;
        final msgs = current.messages.map((m) {
          if (m.id == assistantId) {
            return m.copyWith(content: m.content + delta);
          }
          return m;
        }).toList();
        state = state.withUpdatedCurrent(current.copyWith(messages: msgs));
      }
    } finally {
      final current = state.current;
      final msgs = current.messages.map((m) {
        if (m.id == assistantId) return m.copyWith(isStreaming: false);
        return m;
      }).toList();
      state = state.withUpdatedCurrent(
        current.copyWith(messages: msgs, isStreaming: false),
      );
      _persist();
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
