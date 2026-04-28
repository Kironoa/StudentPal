import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_app/config/env.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  late final GenerativeModel _model;
  ChatSession? _chatSession;

  AIService._internal();

  static Future<void> initialize() async {
    try {
      _instance._model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: Env.geminiApiKey,
      );
      _instance._chatSession = _instance._model.startChat();
    } catch (e) {
      debugPrint('AIService init failed: $e');
    }
  }

  void resetSession() {
    _chatSession = _model.startChat();
  }

  void restoreHistory(List<Map<String, String>> messages) {
    try {
      final history = messages.map((msg) {
        final role = msg['role'] == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(msg['content'] ?? '')]);
      }).toList();
      _chatSession = _model.startChat(history: history);
    } catch (e) {
      debugPrint('Failed to restore chat history: $e');
      _chatSession = _model.startChat();
    }
  }

  bool get isReady => _chatSession != null;

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession?.sendMessage(Content.text(message));
      return response?.text ?? "I couldn't generate a response.";
    } catch (e) {
      if (e.toString().contains('429')) {
        return "Quota exceeded for today. Please try your new API key!";
      }
      return "Error: $e";
    }
  }
}
