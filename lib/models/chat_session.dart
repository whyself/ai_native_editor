import 'package:flutter/foundation.dart';
import 'chat_message.dart';

@immutable
class ChatSession {
  final String id;
  final String name;
  final List<ChatMessage> messages;
  final List<String> contextFilePaths;
  final bool isStreaming;

  const ChatSession({
    required this.id,
    required this.name,
    this.messages = const [],
    this.contextFilePaths = const [],
    this.isStreaming = false,
  });

  bool get canSend => !isStreaming;

  ChatSession copyWith({
    String? name,
    List<ChatMessage>? messages,
    List<String>? contextFilePaths,
    bool? isStreaming,
  }) =>
      ChatSession(
        id: id,
        name: name ?? this.name,
        messages: messages ?? this.messages,
        contextFilePaths: contextFilePaths ?? this.contextFilePaths,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'messages': messages.map((m) => m.toJson()).toList(),
        'contextFilePaths': contextFilePaths,
        // isStreaming intentionally omitted — always false on restore
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String,
        name: json['name'] as String,
        messages: (json['messages'] as List<dynamic>)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        contextFilePaths:
            List<String>.from(json['contextFilePaths'] as List? ?? []),
      );
}
