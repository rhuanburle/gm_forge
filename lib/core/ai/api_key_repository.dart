import 'package:hive_ce/hive.dart';

class ApiKeyRepository {
  static const String _boxName = 'ai_settings';
  static const String _apiKeyKey = 'gemini_api_key';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  Future<void> saveApiKey(String key) async {
    final box = await _openBox();
    await box.put(_apiKeyKey, key.trim());
  }

  Future<String?> getApiKey() async {
    final box = await _openBox();
    final value = box.get(_apiKeyKey);
    if (value == null || (value as String).trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> clearApiKey() async {
    final box = await _openBox();
    await box.delete(_apiKeyKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}
