import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

class TimelineTab extends ConsumerWidget {
  final String campaignId;

  const TimelineTab({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignProvider(campaignId));
    final entries = ref.watch(timelineEntriesProvider(campaignId));
    if (campaign == null) return const SizedBox.shrink();

    final past = entries.where((e) => e.day <= campaign.currentDay && e.type != TimelineEntryType.upcoming).toList();
    final upcoming = entries.where((e) => e.day > campaign.currentDay || e.type == TimelineEntryType.upcoming).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntryDialog(context, ref, campaign.currentDay, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento'),
        backgroundColor: AppTheme.secondary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // Current Day card
          _currentDayCard(context, ref, campaign),
          const SizedBox(height: 20),

          // Upcoming events
          if (upcoming.isNotEmpty) ...[
            _sectionHeader(context, 'Próximos Eventos', Icons.schedule, AppTheme.dubious),
            ...upcoming.map((e) => _EntryTile(
                  entry: e,
                  currentDay: campaign.currentDay,
                  onEdit: () => _showEntryDialog(context, ref, campaign.currentDay, e),
                  onDelete: () => _deleteEntry(context, ref, e),
                )),
            const SizedBox(height: 20),
          ],

          // Past events
          if (past.isNotEmpty) ...[
            _sectionHeader(context, 'Histórico', Icons.history, AppTheme.textSecondary),
            ...past.reversed.map((e) => _EntryTile(
                  entry: e,
                  currentDay: campaign.currentDay,
                  onEdit: () => _showEntryDialog(context, ref, campaign.currentDay, e),
                  onDelete: () => _deleteEntry(context, ref, e),
                )),
          ],

          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Linha do tempo vazia',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registre sessões, eventos do mundo\ne o que está por vir.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _currentDayCard(BuildContext context, WidgetRef ref, Campaign campaign) {
    return Card(
      color: AppTheme.secondary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.r12),
        side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.today, color: AppTheme.secondary, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dia atual da campanha',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary)),
                Text(
                  'Dia ${campaign.currentDay}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove, size: 20),
              onPressed: campaign.currentDay <= 1
                  ? null
                  : () => _updateCurrentDay(ref, campaign, campaign.currentDay - 1),
              tooltip: 'Dia anterior',
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _updateCurrentDay(ref, campaign, campaign.currentDay + 1),
              tooltip: 'Próximo dia',
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _editCurrentDay(context, ref, campaign),
              tooltip: 'Definir dia manualmente',
            ),
          ],
        ),
      ),
    );
  }

  void _updateCurrentDay(WidgetRef ref, Campaign campaign, int day) {
    final updated = campaign.copyWith(currentDay: day, updatedAt: DateTime.now());
    ref.read(campaignListProvider.notifier).update(updated);
    ref.invalidate(campaignProvider(campaign.id));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  void _editCurrentDay(BuildContext context, WidgetRef ref, Campaign campaign) {
    final ctrl = TextEditingController(text: campaign.currentDay.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Definir Dia Atual'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Número do dia'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final day = int.tryParse(ctrl.text.trim()) ?? campaign.currentDay;
              if (day >= 1) _updateCurrentDay(ref, campaign, day);
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _deleteEntry(BuildContext context, WidgetRef ref, TimelineEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Evento?'),
        content: Text('"${entry.title}" será removido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(hiveDatabaseProvider).deleteTimelineEntry(entry.id);
              ref.invalidate(timelineEntriesProvider(entry.campaignId));
            },
            child: const Text('Remover', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showEntryDialog(BuildContext context, WidgetRef ref, int currentDay, TimelineEntry? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final dayCtrl = TextEditingController(text: (existing?.day ?? currentDay).toString());
    TimelineEntryType type = existing?.type ?? TimelineEntryType.worldEvent;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Novo Evento' : 'Editar Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dia', prefixIcon: Icon(Icons.today, size: 18)),
                ),
                const SizedBox(height: 12),
                Text('Tipo', style: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: TimelineEntryType.values.map((t) {
                    final selected = type == t;
                    return FilterChip(
                      label: Text(t.displayName),
                      selected: selected,
                      onSelected: (_) => setState(() => type = t),
                      selectedColor: AppTheme.secondary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.secondary,
                      labelStyle: TextStyle(color: selected ? AppTheme.secondary : null),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final day = int.tryParse(dayCtrl.text.trim()) ?? currentDay;
                final db = ref.read(hiveDatabaseProvider);
                if (existing == null) {
                  final entry = TimelineEntry.create(
                    campaignId: campaignId,
                    day: day,
                    title: title,
                    description: descCtrl.text.trim(),
                    type: type,
                  );
                  await db.saveTimelineEntry(entry);
                } else {
                  final updated = existing.copyWith(
                    day: day,
                    title: title,
                    description: descCtrl.text.trim(),
                    type: type,
                  );
                  await db.saveTimelineEntry(updated);
                }
                ref.invalidate(timelineEntriesProvider(campaignId));
                ref.read(unsyncedChangesProvider.notifier).state = true;
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EntryTile extends StatelessWidget {
  final TimelineEntry entry;
  final int currentDay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.currentDay,
    required this.onEdit,
    required this.onDelete,
  });

  Color _typeColor(TimelineEntryType t) {
    switch (t) {
      case TimelineEntryType.session:
        return AppTheme.primary;
      case TimelineEntryType.worldEvent:
        return AppTheme.secondary;
      case TimelineEntryType.upcoming:
        return AppTheme.dubious;
    }
  }

  IconData _typeIcon(TimelineEntryType t) {
    switch (t) {
      case TimelineEntryType.session:
        return Icons.history_edu;
      case TimelineEntryType.worldEvent:
        return Icons.public;
      case TimelineEntryType.upcoming:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(entry.type);
    final isPast = entry.day <= currentDay && entry.type != TimelineEntryType.upcoming;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: isPast ? 0.15 : 0.25),
          child: Icon(_typeIcon(entry.type), size: 16, color: isPast ? color.withValues(alpha: 0.6) : color),
        ),
        title: Text(
          entry.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isPast ? AppTheme.textSecondary : null,
          ),
        ),
        subtitle: entry.description.isNotEmpty
            ? Text(entry.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text('Dia ${entry.day}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              iconSize: 18,
              padding: EdgeInsets.zero,
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppTheme.error), SizedBox(width: 8), Text('Remover', style: TextStyle(color: AppTheme.error))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
