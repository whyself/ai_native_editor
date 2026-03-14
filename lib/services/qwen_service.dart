import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

const _defaultBaseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';

class QwenService {
  final String apiKey;
  final String model;
  final String baseUrl;

  const QwenService({
    required this.apiKey,
    required this.model,
    this.baseUrl = _defaultBaseUrl,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  // ── Chat stream ───────────────────────────────────────────────────────────

  /// Returns a stream of text delta chunks from the model.
  Stream<String> chatStream(List<ChatMessage> history) async* {
    if (!isConfigured) {
      yield 'API Key 未配置，请在设置中填写 Qwen API Key。';
      return;
    }

    final messages = history.map((m) => {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'content': m.content,
        }).toList();

    final uri = Uri.parse('$baseUrl/chat/completions');
    final request = http.Request('POST', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': true,
    });

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        yield '请求失败 (${response.statusCode})：$body';
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          final data = trimmed.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta =
                json['choices']?[0]?['delta']?['content'] as String?;
            if (delta != null && delta.isNotEmpty) yield delta;
          } catch (_) {
            // Skip malformed chunks
          }
        }
      }
    } on Exception catch (e) {
      yield '网络错误：$e';
    }
  }
}

const kAvailableModels = [
  'qwen-turbo',
  'qwen-turbo-latest',
  'qwen-plus',
  'qwen-plus-latest',
  'qwen-max',
  'qwen-max-latest',
];
