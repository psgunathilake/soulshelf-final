import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_keys.dart';

/// Wraps the OpenAI Chat Completions API for the SoulShelf chatbot.
///
/// Stateless: each call POSTs the full conversation (system + history +
/// new user message) to /v1/chat/completions. The chat sheet owns the
/// running message list and passes it on every send. Aligned with the
/// memory-only design — no service-level history, no caching.
class OpenAiService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _modelName = 'gpt-4o-mini';

  final Dio _dio = Dio(
    BaseOptions(
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Sends [userMessage] to OpenAI and returns the assistant's text reply.
  ///
  /// - [systemPrompt] becomes a `system` role message at the start.
  /// - [history] is the running conversation in chronological order; each
  ///   entry is `(role: 'user' | 'assistant', text: String)`.
  ///
  /// Throws on network / auth / OpenAI errors so the UI can branch into a
  /// friendly inline error bubble.
  Future<String> sendMessage({
    required String systemPrompt,
    required List<({String role, String text})> history,
    required String userMessage,
  }) async {
    if (!ApiKeys.hasOpenai) {
      throw StateError('OPENAI_API_KEY missing — pass via --dart-define');
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final h in history) {'role': h.role, 'content': h.text},
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiKeys.openai}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _modelName,
          'messages': messages,
        },
      );

      final data = response.data;
      final choices = data?['choices'] as List?;
      final first = (choices != null && choices.isNotEmpty)
          ? choices.first as Map<String, dynamic>
          : null;
      final message = first?['message'] as Map<String, dynamic>?;
      final content = (message?['content'] as String?)?.trim();

      if (content == null || content.isEmpty) {
        throw StateError('OpenAI returned an empty response');
      }
      return content;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final apiMessage = (body is Map && body['error'] is Map)
          ? (body['error']['message'] as String?)
          : null;
      throw StateError(
        'OpenAI request failed${status != null ? ' ($status)' : ''}'
        '${apiMessage != null ? ': $apiMessage' : ''}',
      );
    }
  }
}

final openaiServiceProvider = Provider<OpenAiService>((ref) => OpenAiService());
