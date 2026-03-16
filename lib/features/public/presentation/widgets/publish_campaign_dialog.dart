import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/publish_service.dart';

class PublishCampaignDialog extends ConsumerStatefulWidget {
  final String campaignId;

  const PublishCampaignDialog({super.key, required this.campaignId});

  @override
  ConsumerState<PublishCampaignDialog> createState() =>
      _PublishCampaignDialogState();
}

class _PublishCampaignDialogState
    extends ConsumerState<PublishCampaignDialog> {
  bool _publishing = false;
  String? _shareId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shareId = ref.read(shareIdProvider(widget.campaignId));
  }

  String get _shareUrl {
    // Build the public URL relative to current host
    final shareId = _shareId ?? '';
    return '${Uri.base.origin}/p/$shareId';
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });

    try {
      final service = ref.read(publishServiceProvider);
      final shareId = await service.publishCampaign(widget.campaignId);
      if (mounted) {
        setState(() {
          _shareId = shareId;
          _publishing = false;
        });
        ref.invalidate(shareIdProvider(widget.campaignId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _publishing = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _unpublish() async {
    setState(() => _publishing = true);
    try {
      final service = ref.read(publishServiceProvider);
      await service.unpublishCampaign(widget.campaignId);
      if (mounted) {
        setState(() {
          _publishing = false;
        });
        AppSnackBar.success(context, 'Página desativada.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _publishing = false;
          _error = e.toString();
        });
      }
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _shareUrl));
    AppSnackBar.success(context, 'Link copiado!');
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = _shareId != null;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.share, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Compartilhar com Jogadores'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publique uma página com informações da campanha que seus jogadores podem acessar sem precisar de login.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // What gets published
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O que os jogadores veem:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _checkRow(Icons.auto_stories, 'Recaps das sessoes'),
                  _checkRow(Icons.people, 'Personagens do grupo'),
                  _checkRow(Icons.assignment, 'Status das missoes'),
                  _checkRow(Icons.person, 'NPCs (nome e descricao)'),
                  _checkRow(Icons.lightbulb, 'Fatos nao-secretos'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.lock, size: 14,
                          color: AppTheme.combat.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Segredos, motivacoes e dados do mestre ficam ocultos.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.combat.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],

            // Share link (if published)
            if (hasExisting) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        _shareUrl,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: _copyLink,
                      tooltip: 'Copiar link',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (hasExisting)
          TextButton(
            onPressed: _publishing ? null : _unpublish,
            child: const Text('Desativar',
                style: TextStyle(color: AppTheme.error)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton.icon(
          onPressed: _publishing ? null : _publish,
          icon: _publishing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(hasExisting ? Icons.refresh : Icons.publish),
          label: Text(hasExisting ? 'Atualizar' : 'Publicar'),
        ),
      ],
    );
  }

  Widget _checkRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 14, color: AppTheme.success),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
