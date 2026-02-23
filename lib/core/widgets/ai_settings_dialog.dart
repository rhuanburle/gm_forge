import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai/ai_providers.dart';
import '../ai/gemini_service.dart';
import '../theme/app_theme.dart';

class AiSettingsDialog extends ConsumerStatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  ConsumerState<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends ConsumerState<AiSettingsDialog> {
  late TextEditingController _keyController;
  bool _obscure = true;
  bool _testing = false;
  bool? _testResult;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final key = await ref.read(apiKeyRepositoryProvider).getApiKey();
    if (mounted && key != null) {
      setState(() {
        _keyController.text = key;
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_keyController.text.trim().isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final service = GeminiService(_keyController.text.trim());
      final result = await service.testConnection();
      setState(() {
        _testing = false;
        _testResult = result;
      });
    } catch (_) {
      setState(() {
        _testing = false;
        _testResult = false;
      });
    }
  }

  Future<void> _save() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _saving = true);

    await ref.read(apiKeyRepositoryProvider).saveApiKey(key);
    ref.invalidate(apiKeyProvider);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave de IA salva com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearKey() async {
    await ref.read(apiKeyRepositoryProvider).clearApiKey();
    ref.invalidate(apiKeyProvider);
    if (mounted) {
      setState(() {
        _keyController.clear();
        _testResult = null;
      });
    }
  }

  Future<void> _launchUrl() async {
    final url = Uri.parse('https://aistudio.google.com/app/apikey');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Assistente de IA'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Use sua própria chave Gemini (gratuita)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A chave fica salva apenas no seu dispositivo. Você não paga nada além da sua quota pessoal do Google.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _launchUrl,
                    child: const Text(
                      '→ Obter chave no Google AI Studio',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Mostrar chave' : 'Ocultar chave',
                    ),
                    if (_keyController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.error),
                        onPressed: _clearKey,
                        tooltip: 'Remover chave',
                      ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _testResult = null),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 16),
                  label: Text(_testing ? 'Testando...' : 'Testar Conexão'),
                ),
                const SizedBox(width: 12),
                if (_testResult != null)
                  Row(
                    children: [
                      Icon(
                        _testResult! ? Icons.check_circle : Icons.cancel,
                        color: _testResult! ? AppTheme.success : AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _testResult! ? 'Conexão OK' : 'Chave inválida',
                        style: TextStyle(
                          color: _testResult!
                              ? AppTheme.success
                              : AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 16),
          label: const Text('Salvar'),
        ),
      ],
    );
  }
}
