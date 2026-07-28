import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../providers/chat_provider.dart' show ChatMessage;

// TODO: replace with the final Red Pill analytical system prompt.
const String _kSystemPrompt = '''
You are a direct, analytical relationship advisor.
Be blunt, concise, and practical. No disclaimers, no fluff.
Keep every response under 150 tokens.
''';

const int _kMaxOutputTokens = 150;

// gemini-1.5-flash was fully shut down (requests now 404) — the entire
// 1.5 line is retired. gemini-3.5-flash-lite is the current cheapest/
// fastest Flash-tier model, matching this app's cost-efficiency requirement.
const String _kModel = 'gemini-3.5-flash-lite';

/// Wraps the Gemini Flash model with a fixed system prompt and a hard
/// output-token cap, keeping every call cheap and predictable.
class GeminiService {
  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: _kModel,
          apiKey: apiKey,
          systemInstruction: Content.system(_kSystemPrompt),
          generationConfig: GenerationConfig(
            maxOutputTokens: _kMaxOutputTokens,
          ),
        );

  final GenerativeModel _model;

  /// [contextMessages] must already be trimmed by the caller (last 10 max) —
  /// this service never re-fetches or widens that window.
  Future<String> send({
    required List<ChatMessage> contextMessages,
    required String newMessage,
  }) async {
    final history = contextMessages
        .map(
          (m) => Content(
            m.role == 'user' ? 'user' : 'model',
            [TextPart(m.text)],
          ),
        )
        .toList();

    final chat = _model.startChat(history: history);
    final response = await chat.sendMessage(Content.text(newMessage));
    return response.text?.trim() ?? '';
  }
}

/// Supply the key at build/run time:
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: _geminiApiKey);
});
