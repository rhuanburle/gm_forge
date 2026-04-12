import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Shows a dialog that lets the user paste JSON to import an entity.
///
/// [title]       — e.g. "Importar NPC / Monstro"
/// [exampleJson] — a pre-formatted JSON string shown as reference
/// [legend]      — optional plain text below the example explaining enum values
/// [onImport]    — called with the parsed Map when the user taps "Importar"
Future<void> showImportJsonDialog({
  required BuildContext context,
  required String title,
  required String exampleJson,
  String? legend,
  required void Function(Map<String, dynamic> json) onImport,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _ImportJsonDialog(
      title: title,
      exampleJson: exampleJson,
      legend: legend,
      onImport: onImport,
    ),
  );
}

class _ImportJsonDialog extends StatefulWidget {
  final String title;
  final String exampleJson;
  final String? legend;
  final void Function(Map<String, dynamic>) onImport;

  const _ImportJsonDialog({
    required this.title,
    required this.exampleJson,
    required this.onImport,
    this.legend,
  });

  @override
  State<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<_ImportJsonDialog> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _exampleCopied = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _copyExample() async {
    await Clipboard.setData(ClipboardData(text: widget.exampleJson));
    setState(() => _exampleCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _exampleCopied = false);
  }

  void _import() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Cole o JSON antes de importar.');
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        setState(() => _error = 'O JSON deve ser um objeto { ... }, não uma lista.');
        return;
      }
      Navigator.pop(context);
      widget.onImport(decoded);
    } on FormatException catch (e) {
      setState(() => _error = 'JSON inválido: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                      widget.title,
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
              const SizedBox(height: 16),

              // Example section
              Row(
                children: [
                  Text(
                    'Exemplo JSON',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _copyExample,
                    icon: Icon(
                      _exampleCopied ? Icons.check : Icons.copy,
                      size: 14,
                      color: _exampleCopied ? AppTheme.success : AppTheme.secondary,
                    ),
                    label: Text(
                      _exampleCopied ? 'Copiado!' : 'Copiar',
                      style: TextStyle(
                        fontSize: 12,
                        color: _exampleCopied ? AppTheme.success : AppTheme.secondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.textMuted.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(
                    widget.exampleJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // Legend
              if (widget.legend != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    widget.legend!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                      height: 1.6,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Input
              Text(
                'Cole o JSON aqui:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _ctrl,
                maxLines: 6,
                minLines: 4,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: InputDecoration(
                  hintText: '{ "name": "...", ... }',
                  hintStyle: const TextStyle(fontSize: 11),
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
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
                    onPressed: _import,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Importar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
