import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_prompts.dart';

class GeminiService {
  final String _apiKey;
  late final GenerativeModel _model;

  GeminiService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(AiPrompts.getSystemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 2048,
      ),
    );
  }

  Future<String> improve({
    required AiFieldType fieldType,
    required String currentText,
    required Map<String, String> adventureContext,
  }) async {
    if (currentText.trim().isEmpty) {
      return await suggest(
        fieldType: fieldType,
        adventureContext: adventureContext,
      );
    }

    final prompt = AiPrompts.buildImprovePrompt(
      fieldType: fieldType,
      currentText: currentText,
      adventureContext: adventureContext,
    );

    return await _generate(prompt);
  }

  Future<String> suggest({
    required AiFieldType fieldType,
    required Map<String, String> adventureContext,
    Map<String, String>? extraContext,
  }) async {
    final prompt = AiPrompts.buildSuggestPrompt(
      fieldType: fieldType,
      adventureContext: adventureContext,
      extraContext: extraContext,
    );

    return await _generate(prompt);
  }

  Future<String> _generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);

    final candidates = response.candidates;
    if (candidates.isEmpty) {
      throw Exception('No candidates in Gemini API response');
    }

    final candidate = candidates.first;
    if (candidate.finishReason == FinishReason.maxTokens) {
      // Response was truncated due to token limit
      final partial = candidate.text ?? '';
      if (partial.isNotEmpty) {
        return partial.trim();
      }
      throw Exception('Response truncated and empty');
    }

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Gemini API');
    }
    return text.trim();
  }

  Future<bool> testConnection() async {
    try {
      final response = await _model.generateContent([
        Content.text('Reply with exactly: OK'),
      ]);
      return (response.text?.trim().isNotEmpty) == true;
    } catch (_) {
      return false;
    }
  }
}
