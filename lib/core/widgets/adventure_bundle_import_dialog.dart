import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/adventure_bundle_service.dart';
import '../sync/unsynced_changes_provider.dart';
import '../theme/app_theme.dart';
import '../../features/adventure/application/adventure_providers.dart';

/// Shows the two-step adventure bundle import dialog.
Future<void> showAdventureBundleImportDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AdventureBundleImportDialog(ref: ref),
  );
}

class _AdventureBundleImportDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AdventureBundleImportDialog({required this.ref});

  @override
  ConsumerState<_AdventureBundleImportDialog> createState() =>
      _AdventureBundleImportDialogState();
}

class _AdventureBundleImportDialogState
    extends ConsumerState<_AdventureBundleImportDialog> {
  // Step 1 state
  final _ctrl = TextEditingController();
  String? _parseError;
  bool _isLoadingFile = false;
  bool _exampleCopied = false;

  // Step 2 state
  Map<String, dynamic>? _bundle;
  String? _selectedCampaignId; // null = standalone
  bool _isImporting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step 1: Load / Paste JSON
  // ---------------------------------------------------------------------------

  void _pickFile() async {
    setState(() {
      _isLoadingFile = true;
      _parseError = null;
    });

    final completer = Completer<String?>();

    final input = html.FileUploadInputElement()
      ..accept = '.json,application/json'
      ..style.display = 'none';
    html.document.body!.append(input);

    input.onChange.first.then((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        input.remove();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.first.then((_) {
        input.remove();
        final result = reader.result;
        if (!completer.isCompleted) {
          completer.complete(result is String ? result : null);
        }
      });
      reader.readAsText(files[0]);
    });

    // If user dismisses file picker without selecting, cancel after a timeout
    Future.delayed(const Duration(minutes: 2), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    input.click();

    final text = await completer.future;
    if (!mounted) return;

    setState(() => _isLoadingFile = false);

    if (text != null) {
      _ctrl.text = text;
      _tryParseAndAdvance(text);
    }
  }

  void _tryParseAndAdvance(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _parseError = 'Cole o JSON antes de continuar.');
      return;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        setState(() => _parseError = 'O JSON deve ser um objeto { ... }, não uma lista.');
        return;
      }
      if (!AdventureBundleService.isValidBundle(decoded)) {
        setState(() => _parseError =
            'JSON inválido: falta o campo "adventure" com "name".');
        return;
      }
      setState(() {
        _bundle = decoded;
        _parseError = null;
      });
    } on FormatException catch (e) {
      setState(() => _parseError = 'JSON inválido: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2: Confirm & Import
  // ---------------------------------------------------------------------------

  Future<void> _doImport() async {
    if (_bundle == null) return;
    setState(() => _isImporting = true);

    try {
      final service = ref.read(adventureBundleServiceProvider);
      await service.importBundle(
        _bundle!,
        targetCampaignId: _selectedCampaignId,
      );

      ref.read(adventureListProvider.notifier).refresh();
      ref.read(campaignListProvider.notifier).refresh();
      ref.read(unsyncedChangesProvider.notifier).state = true;

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.success(context, 'Aventura importada com sucesso!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      AppSnackBar.error(context, 'Erro ao importar: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _bundle == null ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  Future<void> _copyExample() async {
    await Clipboard.setData(
        ClipboardData(text: AdventureBundleService.exampleJson));
    setState(() => _exampleCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _exampleCopied = false);
  }

  // ---- Step 1 ---------------------------------------------------------------

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.upload_file, color: AppTheme.secondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Importar Aventura',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Cole o JSON da aventura abaixo ou carregue um arquivo .json.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 16),

        // File picker + example buttons row
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _isLoadingFile ? null : _pickFile,
              icon: _isLoadingFile
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open, size: 16),
              label: Text(
                _isLoadingFile ? 'Carregando...' : 'Carregar .json',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _copyExample,
              icon: Icon(
                _exampleCopied ? Icons.check : Icons.copy,
                size: 14,
                color: _exampleCopied ? AppTheme.success : AppTheme.secondary,
              ),
              label: Text(
                _exampleCopied ? 'Copiado!' : 'Copiar exemplo',
                style: TextStyle(
                  fontSize: 12,
                  color: _exampleCopied ? AppTheme.success : AppTheme.secondary,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Paste area label
        Text(
          'Ou cole o JSON aqui:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          maxLines: 8,
          minLines: 6,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          decoration: InputDecoration(
            hintText:
                '{ "adventure": { "name": "..." }, "creatures": [...], ... }',
            hintStyle: const TextStyle(fontSize: 11),
            errorText: _parseError,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(10),
          ),
          onChanged: (_) {
            if (_parseError != null) setState(() => _parseError = null);
          },
        ),
        const SizedBox(height: 16),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _tryParseAndAdvance(_ctrl.text),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Próximo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Step 2 ---------------------------------------------------------------

  Widget _buildStep2() {
    final bundle = _bundle!;
    final advName = (bundle['adventure'] as Map)['name'] as String? ?? 'Aventura';
    final counts = AdventureBundleService.countEntities(bundle);
    final campaigns = ref.watch(campaignListProvider);

    final countWidgets = <Widget>[];
    final quickRuleCount = counts['quickRules'] ?? 0;
    final labels = {
      'creatures': 'criaturas',
      'locations': 'locais',
      'pointsOfInterest': 'pontos de interesse',
      'quests': 'missões',
      'facts': 'fatos',
      'items': 'itens',
      'factions': 'facções',
      'legends': 'rumores',
      'randomEvents': 'eventos aleatórios',
      'sessions': 'sessões',
      'quickRules': 'regras de jogo',
    };
    for (final entry in counts.entries) {
      if (entry.value > 0) {
        countWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  '${entry.value} ${labels[entry.key] ?? entry.key}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirmar Importação',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _isImporting ? null : () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Adventure name highlight
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.map, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  advName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Entity summary
        if (countWidgets.isNotEmpty) ...[
          Text(
            'Conteúdo incluído:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          ...countWidgets,
          const SizedBox(height: 4),
          Text(
            'Imagens não são importadas — adicione manualmente após a importação.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          if (quickRuleCount > 0 && _selectedCampaignId == null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 13, color: AppTheme.warning),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$quickRuleCount regra(s) de jogo só serão importadas se vincular a uma campanha.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],

        // Campaign selector
        Text(
          'Vincular a uma campanha (opcional):',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCampaignId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Sem campanha (aventura independente)'),
            ),
            ...campaigns.map((c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged:
              _isImporting ? null : (v) => setState(() => _selectedCampaignId = v),
        ),
        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            TextButton(
              onPressed: _isImporting
                  ? null
                  : () => setState(() => _bundle = null),
              child: const Text('Voltar'),
            ),
            const Spacer(),
            TextButton(
              onPressed:
                  _isImporting ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _doImport,
              icon: _isImporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_done, size: 16),
              label: Text(_isImporting ? 'Importando...' : 'Importar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
