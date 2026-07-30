import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  late final Dio _dio;
  List<Map<String, String>> _history = [];

  AIService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://openrouter.ai/api/v1',
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENROUTER_API_KEY'] ?? ''}',
        'Content-Type': 'application/json',
      },
    ));
  }

  static Future<void> initialize() async {}

  void resetSession() {
    _history.clear();
  }

  void restoreHistory(List<Map<String, String>> messages) {
    _history = messages;
  }

  bool get isReady =>
      (dotenv.env['OPENROUTER_API_KEY'] ?? '').isNotEmpty;

  Future<String> sendMessage(String message) async {
    try {
      _history.add({'role': 'user', 'content': message});

      final messages = _history
          .map((m) => {'role': m['role'] == 'user' ? 'user' : 'assistant', 'content': m['content']})
          .toList();

      final response = await _dio.post('/chat/completions', data: {
        'model': 'openai/gpt-4o-mini',
        'messages': messages,
      });

      final reply =
          response.data['choices'][0]['message']['content'] as String;
      _history.add({'role': 'assistant', 'content': reply});
      return reply;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if (status == 429 || body?.toString().contains('quota') == true) {
        return 'Quota exceeded for today. Please try your new API key!';
      }
      return 'Error: ${e.message}';
    }
  }
}
