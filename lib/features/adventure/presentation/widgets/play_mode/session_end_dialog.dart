import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../core/ai/ai_providers.dart';
import '../../../../adventure/application/adventure_providers.dart';
import '../../../../adventure/application/active_adventure_state.dart';
import '../../../../adventure/domain/domain.dart';

class SessionEndDialog extends ConsumerStatefulWidget {
  final String adventureId;

  const SessionEndDialog({super.key, required this.adventureId});

  @override
  ConsumerState<SessionEndDialog> createState() => _SessionEndDialogState();
}

class _SessionEndDialogState extends ConsumerState<SessionEndDialog> {
  final _recapController = TextEditingController();
  bool _isGenerating = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _recapController.dispose();
    super.dispose();
  }

  Future<void> _generateRecapWithAI() async {
    final activeState = ref.read(activeAdventureProvider);
    final activeSessionId = activeState.activeSessionId;
    if (activeSessionId == null) return;

    final gemini = ref.read(geminiServiceProvider);
    if (gemini == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure a chave de API da IA primeiro.'),
        ),
      );
      return;
    }

    final adventure = ref.read(adventureProvider(widget.adventureId));
    final entries = ref.read(sessionEntriesProvider(widget.adventureId));
    final sessionEntries = entries
        .where((e) => e.sessionId == activeSessionId)
        .toList();

    if (sessionEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma entrada no log para gerar recap.'),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final sortedEntries = List<SessionEntry>.from(sessionEntries)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final logText = sortedEntries
          .map((e) {
            final type = e.entryType.displayName;
            final turn = e.turnLabel?.isNotEmpty == true
                ? '[${e.turnLabel}] '
                : '';
            return '- ($type) $turn${e.text}';
          })
          .join('\n');

      final prompt =
          '''
Você é um mestre de RPG experiente. Com base no log de sessão abaixo, gere um resumo narrativo envolvente da sessão para compartilhar com os jogadores.

**Aventura:** ${adventure?.name ?? 'Sem nome'}
**Conceito:** ${adventure?.conceptWhat ?? ''}
**Conflito:** ${adventure?.conceptConflict ?? ''}

**Log da Sessão:**
$logText

Instruções:
- Escreva em português do Brasil
- Use tom narrativo e envolvente (como se fosse um narrador contando a história)
- Organize em 2-4 parágrafos
- Destaque momentos dramáticos, descobertas e decisões importantes
- Termine com um gancho para a próxima sessão se possível
- Não invente fatos que não estejam no log
- Máximo 300 palavras
''';

      final recap = await gemini.generateLongText(prompt);

      if (!mounted) return;

      setState(() {
        _recapController.text = recap;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar recap: $e')));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _endSession() async {
    final activeState = ref.read(activeAdventureProvider);
    final activeSessionId = activeState.activeSessionId;
    if (activeSessionId == null) return;

    setState(() => _isSaving = true);

    try {
      final sessions = ref.read(sessionsProvider(widget.adventureId));
      final session = sessions
          .where((s) => s.id == activeSessionId)
          .firstOrNull;
      if (session != null) {
        final updated = session.copyWith(
          status: SessionStatus.reviewed,
          recap: _recapController.text.trim(),
        );
        await ref.read(hiveDatabaseProvider).saveSession(updated);
        ref.invalidate(sessionsProvider(widget.adventureId));
      }

      ref.read(activeAdventureProvider.notifier).setActiveSession(null);
      ref.read(unsyncedChangesProvider.notifier).state = true;

      if (!mounted) return;

      Navigator.pop(context);
      context.go('/adventure/${widget.adventureId}/sessions');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sessão encerrada!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao encerrar sessão: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeAdventureProvider);
    final activeSessionId = activeState.activeSessionId;

    if (activeSessionId == null) {
      return AlertDialog(
        title: const Text('Encerrar Sessão'),
        content: const Text('Nenhuma sessão selecionada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.flag, color: AppTheme.secondary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Encerrar Sessão')),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edite o recap da sessão:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recapController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Resumo do que aconteceu na sessão...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isGenerating ? null : _generateRecapWithAI,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_isGenerating ? 'Gerando...' : 'Gerar com IA'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _endSession,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check, size: 16),
          label: Text(_isSaving ? 'Salvando...' : 'Encerrar'),
        ),
      ],
    );
  }
}
