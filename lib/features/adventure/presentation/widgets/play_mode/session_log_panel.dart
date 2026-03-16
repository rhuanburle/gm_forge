import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../core/ai/ai_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/session_export_service.dart';
import '../../../domain/domain.dart';
import '../../widgets/smart_text_field.dart';
import '../../widgets/smart_text_renderer.dart';

class SessionLogPanel extends ConsumerStatefulWidget {
  final String adventureId;

  const SessionLogPanel({super.key, required this.adventureId});

  @override
  ConsumerState<SessionLogPanel> createState() => _SessionLogPanelState();
}

class _SessionLogPanelState extends ConsumerState<SessionLogPanel> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _turnController = TextEditingController();
  SessionEntryType _selectedType = SessionEntryType.note;

  @override
  void dispose() {
    _textController.dispose();
    _turnController.dispose();
    super.dispose();
  }

  void _addEntry() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final db = ref.read(hiveDatabaseProvider);
    final activeSessionId = ref.read(activeAdventureProvider).activeSessionId;
    final entry = SessionEntry.create(
      adventureId: widget.adventureId,
      text: text,
      entryType: _selectedType,
      turnLabel: _turnController.text.trim(),
      sessionId: activeSessionId,
    );

    await db.saveSessionEntry(entry);

    _textController.clear();
    ref.invalidate(sessionEntriesProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  void _deleteEntry(SessionEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir entrada?'),
        content: const Text(
          'Tem certeza de que deseja excluir este registro do log?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = ref.read(hiveDatabaseProvider);
    await db.deleteSessionEntry(entry.id);
    ref.invalidate(sessionEntriesProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  bool _isGeneratingRecap = false;

  void _exportPlayerRecap() async {
    final exportService = ref.read(sessionExportServiceProvider);
    await exportService.copyPlayerRecapToClipboard(widget.adventureId);

    if (!mounted) return;
    AppSnackBar.success(context, 'Resumo para jogadores copiado! (sem notas do mestre)');
  }

  void _exportLog() async {
    final exportService = ref.read(sessionExportServiceProvider);
    await exportService.copySessionLogToClipboard(widget.adventureId);

    if (!mounted) return;
    AppSnackBar.success(context, 'Log da sessão copiado para área de transferência!');
  }

  void _generateAiRecap() async {
    final gemini = ref.read(geminiServiceProvider);
    if (gemini == null) {
      AppSnackBar.error(context, 'Configure a chave de API da IA primeiro.');
      return;
    }

    final adventure = ref.read(adventureProvider(widget.adventureId));
    final entries = ref.read(sessionEntriesProvider(widget.adventureId));
    if (entries.isEmpty) {
      AppSnackBar.info(context, 'Nenhuma entrada no log para gerar recap.');
      return;
    }

    setState(() => _isGeneratingRecap = true);

    try {
      final sortedEntries = List<SessionEntry>.from(entries)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final logText = sortedEntries.map((e) {
        final type = e.entryType.displayName;
        final turn = e.turnLabel?.isNotEmpty == true ? '[${e.turnLabel}] ' : '';
        return '- ($type) $turn${e.text}';
      }).join('\n');

      final prompt = '''
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

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recap da Sessão'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                recap,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: recap));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  AppSnackBar.success(context, 'Recap copiado!');
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Erro ao gerar recap: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingRecap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    final entries = ref.watch(sessionEntriesProvider(widget.adventureId));

    if (adventure == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📜 Log da Sessão',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isGeneratingRecap)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  tooltip: 'Gerar Recap com IA',
                  onPressed: entries.isEmpty ? null : _generateAiRecap,
                  splashRadius: 16,
                  color: AppTheme.secondary,
                ),
              IconButton(
                icon: const Icon(Icons.people, size: 16),
                tooltip: 'Exportar para Jogadores (sem segredos)',
                onPressed: entries.isEmpty ? null : _exportPlayerRecap,
                splashRadius: 16,
                color: AppTheme.info,
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Exportar Resumo Completo (Markdown)',
                onPressed:
                    entries.isEmpty && (adventure.sessionNotes?.isEmpty ?? true)
                    ? null
                    : _exportLog,
                splashRadius: 16,
              ),
            ],
          ),
        ),

        // Input Area
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.overlay(context),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SessionEntryType>(
                          value: _selectedType,
                          isExpanded: true,
                          isDense: true,
                          style: Theme.of(context).textTheme.bodySmall,
                          items: SessionEntryType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text('${type.icon} ${type.displayName}'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedType = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _turnController,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Turno/Tempo',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppTheme.overlay(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SmartTextField(
                  adventureId: widget.adventureId,
                  controller: _textController,
                  label: '',
                  hint: 'Acontecimento (@npc, #local)...',
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _addEntry,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Registrar'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Timeline
        Expanded(
          child: entries.isEmpty && (adventure.sessionNotes?.isEmpty ?? true)
              ? Center(
                  child: Text(
                    'Nenhum acontecimento registrado.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount:
                      entries.length +
                      (adventure.sessionNotes?.isNotEmpty == true ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == entries.length) {
                      return _buildLegacyNotes(adventure.sessionNotes!);
                    }

                    final entry = entries[index];
                    return _SessionEntryCard(
                      adventureId: widget.adventureId,
                      entry: entry,
                      onDelete: () => _deleteEntry(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLegacyNotes(String notes) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text(
          'Notas Antigas',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        collapsedBackgroundColor: AppTheme.surfaceLight.withValues(alpha: 0.15),
        backgroundColor: AppTheme.surfaceLight.withValues(alpha: 0.15),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              notes,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionEntryCard extends StatelessWidget {
  final String adventureId;
  final SessionEntry entry;
  final VoidCallback onDelete;

  const _SessionEntryCard({
    required this.adventureId,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: _getTimelineColor(context, entry.entryType),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getTimelineBorderColor(context, entry.entryType),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.entryType.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      if (entry.turnLabel?.isNotEmpty == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.overlay(context, alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.turnLabel!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        timeFormat.format(entry.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SmartTextRenderer(
              text: entry.text,
              adventureId: adventureId,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimelineColor(BuildContext context, SessionEntryType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 0.15 : 0.05;

    switch (type) {
      case SessionEntryType.combat:
        return AppTheme.combat.withValues(alpha: alpha);
      case SessionEntryType.discovery:
        return AppTheme.discovery.withValues(alpha: alpha);
      case SessionEntryType.narrative:
        return AppTheme.narrative.withValues(alpha: alpha);
      case SessionEntryType.note:
        return AppTheme.overlay(context);
    }
  }

  Color _getTimelineBorderColor(BuildContext context, SessionEntryType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 0.3 : 0.2;

    switch (type) {
      case SessionEntryType.combat:
        return AppTheme.combat.withValues(alpha: alpha);
      case SessionEntryType.discovery:
        return AppTheme.discovery.withValues(alpha: alpha);
      case SessionEntryType.narrative:
        return AppTheme.narrative.withValues(alpha: alpha);
      case SessionEntryType.note:
        return AppTheme.textMuted.withValues(alpha: alpha);
    }
  }
}
