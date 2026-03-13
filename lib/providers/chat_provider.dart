import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/file_service.dart';
import '../services/qwen_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class ChatState {
  final List<ChatMessage> messages;
  final List<String> contextFilePaths;
  final bool isStreaming;

  const ChatState({
    this.messages = const [],
    this.contextFilePaths = const [],
    this.isStreaming = false,
  });

  bool get canSend => !isStreaming;

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<String>? contextFilePaths,
    bool? isStreaming,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        contextFilePaths: contextFilePaths ?? this.contextFilePaths,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  void addContextFile(String filePath) {
    if (state.contextFilePaths.contains(filePath)) return;
    state = state.copyWith(
      contextFilePaths: [...state.contextFilePaths, filePath],
    );
  }

  void removeContextFile(String filePath) {
    state = state.copyWith(
      contextFilePaths: state.contextFilePaths.where((p) => p != filePath).toList(),
    );
  }

  void clearChat() {
    state = const ChatState();
  }

  Future<void> sendMessage(String text) async {
    if (!state.canSend || text.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    final qwen = QwenService(
      apiKey: settings.apiKey,
      model: settings.model,
      baseUrl: settings.baseUrl,
    );

    // Build context string from attached files
    final contextPaths = List<String>.from(state.contextFilePaths);
    String contextPrefix = '';

    if (contextPaths.isNotEmpty) {
      final buffer = StringBuffer('以下是用户提供的参考文件：\n\n');
      for (final path in contextPaths) {
        final content = await FileService.instance.readFileSafe(path);
        final name = path.split(RegExp(r'[/\\]')).last;
        if (content != null) {
          buffer.writeln('--- $name ---');
          buffer.writeln(content);
          buffer.writeln();
        }
      }
      contextPrefix = buffer.toString();
    }

    final userContent = contextPrefix.isEmpty ? text : '$contextPrefix用户问题：$text';

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text, // display only the user's actual text
      contextFilePaths: contextPaths,
    );

    // Build full history for API (include context in hidden first user msg if needed)
    final apiHistory = [
      ...state.messages.map((m) => ChatMessage(
            id: m.id,
            role: m.role,
            content: m.content,
          )),
      ChatMessage(id: userMsg.id, role: MessageRole.user, content: userContent),
    ];

    final assistantId = _uuid.v4();
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      contextFilePaths: [],
      isStreaming: true,
    );

    try {
      await for (final delta in qwen.chatStream(apiHistory)) {
        final msgs = state.messages.map((m) {
          if (m.id == assistantId) {
            return m.copyWith(content: m.content + delta);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: msgs);
      }
    } finally {
      final msgs = state.messages.map((m) {
        if (m.id == assistantId) return m.copyWith(isStreaming: false);
        return m;
      }).toList();
      state = state.copyWith(messages: msgs, isStreaming: false);
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
