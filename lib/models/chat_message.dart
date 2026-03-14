import 'package:flutter/foundation.dart';

enum MessageRole { user, assistant }

@immutable
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final List<String> contextFilePaths; // only for user messages
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.contextFilePaths = const [],
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
  }) =>
      ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        contextFilePaths: contextFilePaths,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'contextFilePaths': contextFilePaths,
        // isStreaming intentionally omitted — always false on restore
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: MessageRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => MessageRole.user,
        ),
        content: json['content'] as String,
        contextFilePaths:
            List<String>.from(json['contextFilePaths'] as List? ?? []),
      );
}

