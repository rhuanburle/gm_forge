import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_key_repository.dart';
import 'gemini_service.dart';

final apiKeyRepositoryProvider = Provider<ApiKeyRepository>((ref) {
  return ApiKeyRepository();
});

final apiKeyProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(apiKeyRepositoryProvider);
  return await repo.getApiKey();
});

final geminiServiceProvider = Provider<GeminiService?>((ref) {
  final apiKeyAsync = ref.watch(apiKeyProvider);
  return apiKeyAsync.when(
    data: (key) {
      if (key == null || key.isEmpty) return null;
      return GeminiService(key);
    },
    loading: () => null,
    error: (e, s) => null,
  );
});

final hasAiConfiguredProvider = Provider<bool>((ref) {
  final apiKeyAsync = ref.watch(apiKeyProvider);
  return apiKeyAsync.when(
    data: (key) => key != null && key.isNotEmpty,
    loading: () => false,
    error: (e, s) => false,
  );
});
