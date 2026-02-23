import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_providers.dart';
import '../ai/ai_prompts.dart';
import '../theme/app_theme.dart';
import 'ai_settings_dialog.dart';

class AiAssistButton extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final AiFieldType fieldType;
  final Map<String, String> adventureContext;
  final Map<String, String>? extraContext;

  const AiAssistButton({
    super.key,
    required this.controller,
    required this.fieldType,
    required this.adventureContext,
    this.extraContext,
  });

  @override
  ConsumerState<AiAssistButton> createState() => _AiAssistButtonState();
}

class _AiAssistButtonState extends ConsumerState<AiAssistButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Tooltip(
      message: 'Assistente de IA ✨',
      child: IconButton(
        icon: const Icon(Icons.auto_awesome, size: 18),
        color: AppTheme.primary.withValues(alpha: 0.7),
        onPressed: () => _onPressed(context),
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final hasAi = ref.read(hasAiConfiguredProvider);

    if (!hasAi) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => const AiSettingsDialog(),
      );
      return;
    }

    if (!context.mounted) return;
    _showAssistMenu(context);
  }

  void _showAssistMenu(BuildContext context) {
    final currentText = widget.controller.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AiAssistSheet(
        currentText: currentText,
        onImprove: () {
          Navigator.pop(ctx);
          _runImprove();
        },
        onSuggest: () {
          Navigator.pop(ctx);
          _runSuggest();
        },
      ),
    );
  }

  Future<void> _runImprove() async {
    final service = ref.read(geminiServiceProvider);
    if (service == null) return;

    final originalText = widget.controller.text;

    setState(() => _loading = true);

    try {
      final result = await service.improve(
        fieldType: widget.fieldType,
        currentText: originalText,
        adventureContext: widget.adventureContext,
      );

      if (mounted) {
        setState(() => _loading = false);
        _showPreview(result, originalText);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _runSuggest() async {
    final service = ref.read(geminiServiceProvider);
    if (service == null) return;

    final originalText = widget.controller.text;

    setState(() => _loading = true);

    try {
      final result = await service.suggest(
        fieldType: widget.fieldType,
        adventureContext: widget.adventureContext,
        extraContext: widget.extraContext,
      );

      if (mounted) {
        setState(() => _loading = false);
        _showPreview(result, originalText);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString());
      }
    }
  }

  void _showPreview(String suggestedText, String originalText) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _AiPreviewDialog(
        suggestedText: suggestedText,
        originalText: originalText,
        onAccept: () {
          widget.controller.text = suggestedText;
          widget.controller.selection = TextSelection.collapsed(
            offset: suggestedText.length,
          );
          Navigator.pop(ctx);
        },
        onReject: () => Navigator.pop(ctx),
        onRegenerate: () {
          Navigator.pop(ctx);
          _runSuggest();
        },
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Erro na IA: $message',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AiAssistSheet extends StatelessWidget {
  final String currentText;
  final VoidCallback onImprove;
  final VoidCallback onSuggest;

  const _AiAssistSheet({
    required this.currentText,
    required this.onImprove,
    required this.onSuggest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Assistente de IA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.auto_fix_high,
              title: '✨ Melhorar texto',
              subtitle: currentText.isNotEmpty
                  ? 'Refina e aprimora o que você já escreveu'
                  : 'Campo sem texto — será gerado conteúdo novo',
              enabled: true,
              onTap: onImprove,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.lightbulb_outline,
              title: '💡 Sugerir do zero',
              subtitle:
                  'Gera uma sugestão nova com base no contexto da aventura',
              enabled: true,
              onTap: onSuggest,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: enabled
                ? AppTheme.primary.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? AppTheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: enabled ? null : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: enabled ? AppTheme.primary : Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiPreviewDialog extends StatelessWidget {
  final String suggestedText;
  final String originalText;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onRegenerate;

  const _AiPreviewDialog({
    required this.suggestedText,
    required this.originalText,
    required this.onAccept,
    required this.onReject,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text('Sugestão da IA'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(suggestedText, style: const TextStyle(height: 1.5)),
              ),
              if (originalText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Texto original:',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  originalText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.close, size: 16, color: AppTheme.error),
          label: const Text(
            'Descartar',
            style: TextStyle(color: AppTheme.error),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRegenerate,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Regenerar'),
        ),
        ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Aceitar'),
        ),
      ],
    );
  }
}
