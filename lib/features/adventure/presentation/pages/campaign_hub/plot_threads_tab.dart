import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

class PlotThreadsTab extends ConsumerWidget {
  final String campaignId;

  const PlotThreadsTab({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignProvider(campaignId));
    if (campaign == null) return const SizedBox.shrink();

    final threads = campaign.plotThreads;
    final active = threads.where((t) => t.status == PlotThreadStatus.active).toList();
    final dormant = threads.where((t) => t.status == PlotThreadStatus.dormant).toList();
    final resolved = threads.where((t) => t.status == PlotThreadStatus.resolved).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showThreadDialog(context, ref, campaign, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo Fio'),
        backgroundColor: AppTheme.secondary,
      ),
      body: threads.isEmpty
          ? _emptyState(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (active.isNotEmpty) ...[
                  _groupHeader(context, 'Ativos', PlotThreadStatus.active, active.length),
                  ...active.map((t) => _ThreadCard(
                        thread: t,
                        campaign: campaign,
                        onEdit: () => _showThreadDialog(context, ref, campaign, t),
                        onDelete: () => _deleteThread(context, ref, campaign, t),
                        onStatusChange: (s) => _changeStatus(ref, campaign, t, s),
                      )),
                  const SizedBox(height: 16),
                ],
                if (dormant.isNotEmpty) ...[
                  _groupHeader(context, 'Dormentes', PlotThreadStatus.dormant, dormant.length),
                  ...dormant.map((t) => _ThreadCard(
                        thread: t,
                        campaign: campaign,
                        onEdit: () => _showThreadDialog(context, ref, campaign, t),
                        onDelete: () => _deleteThread(context, ref, campaign, t),
                        onStatusChange: (s) => _changeStatus(ref, campaign, t, s),
                      )),
                  const SizedBox(height: 16),
                ],
                if (resolved.isNotEmpty) ...[
                  _groupHeader(context, 'Resolvidos', PlotThreadStatus.resolved, resolved.length),
                  ...resolved.map((t) => _ThreadCard(
                        thread: t,
                        campaign: campaign,
                        onEdit: () => _showThreadDialog(context, ref, campaign, t),
                        onDelete: () => _deleteThread(context, ref, campaign, t),
                        onStatusChange: (s) => _changeStatus(ref, campaign, t, s),
                      )),
                ],
              ],
            ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Nenhum fio de trama',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Registre consequências abertas, ganchos e\ntramas que precisam de resolução.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(BuildContext context, String label, PlotThreadStatus status, int count) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text('($count)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Color _statusColor(PlotThreadStatus s) {
    switch (s) {
      case PlotThreadStatus.active:
        return AppTheme.warning;
      case PlotThreadStatus.dormant:
        return AppTheme.info;
      case PlotThreadStatus.resolved:
        return AppTheme.success;
    }
  }

  void _changeStatus(WidgetRef ref, Campaign campaign, PlotThread thread, PlotThreadStatus newStatus) {
    final updated = campaign.copyWith(
      plotThreads: campaign.plotThreads
          .map((t) => t.id == thread.id ? t.copyWith(status: newStatus) : t)
          .toList(),
      updatedAt: DateTime.now(),
    );
    ref.read(campaignListProvider.notifier).update(updated);
    ref.invalidate(campaignProvider(campaign.id));
  }

  void _deleteThread(BuildContext context, WidgetRef ref, Campaign campaign, PlotThread thread) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Fio?'),
        content: Text('"${thread.title}" será removido permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final updated = campaign.copyWith(
                plotThreads: campaign.plotThreads.where((t) => t.id != thread.id).toList(),
                updatedAt: DateTime.now(),
              );
              ref.read(campaignListProvider.notifier).update(updated);
              ref.invalidate(campaignProvider(campaign.id));
            },
            child: const Text('Remover', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showThreadDialog(BuildContext context, WidgetRef ref, Campaign campaign, PlotThread? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    PlotThreadStatus status = existing?.status ?? PlotThreadStatus.active;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Novo Fio de Trama' : 'Editar Fio'),
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
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'O que está em jogo? Quem está envolvido?',
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Text('Status', style: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                SegmentedButton<PlotThreadStatus>(
                  segments: PlotThreadStatus.values
                      .map((s) => ButtonSegment(value: s, label: Text(s.displayName)))
                      .toList(),
                  selected: {status},
                  onSelectionChanged: (v) => setState(() => status = v.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                    selectedForegroundColor: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final thread = existing == null
                    ? PlotThread.create(
                        title: title,
                        description: descCtrl.text.trim(),
                      ).copyWith(status: status)
                    : existing.copyWith(
                        title: title,
                        description: descCtrl.text.trim(),
                        status: status,
                      );
                final newList = existing == null
                    ? [...campaign.plotThreads, thread]
                    : campaign.plotThreads.map((t) => t.id == thread.id ? thread : t).toList();
                final updated = campaign.copyWith(plotThreads: newList, updatedAt: DateTime.now());
                ref.read(campaignListProvider.notifier).update(updated);
                ref.invalidate(campaignProvider(campaign.id));
                ref.read(unsyncedChangesProvider.notifier).state = true;
                Navigator.pop(ctx);
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
// Thread Card
// ---------------------------------------------------------------------------

class _ThreadCard extends StatelessWidget {
  final PlotThread thread;
  final Campaign campaign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<PlotThreadStatus> onStatusChange;

  const _ThreadCard({
    required this.thread,
    required this.campaign,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  Color _statusColor(PlotThreadStatus s) {
    switch (s) {
      case PlotThreadStatus.active:
        return AppTheme.warning;
      case PlotThreadStatus.dormant:
        return AppTheme.info;
      case PlotThreadStatus.resolved:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(thread.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      decoration: thread.status == PlotThreadStatus.resolved
                          ? TextDecoration.lineThrough
                          : null,
                      color: thread.status == PlotThreadStatus.resolved
                          ? AppTheme.textMuted
                          : null,
                    ),
                  ),
                  if (thread.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      thread.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              iconSize: 18,
              padding: EdgeInsets.zero,
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
                if (v == 'active') onStatusChange(PlotThreadStatus.active);
                if (v == 'dormant') onStatusChange(PlotThreadStatus.dormant);
                if (v == 'resolved') onStatusChange(PlotThreadStatus.resolved);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'active', child: Row(children: [Icon(Icons.flash_on, size: 16, color: AppTheme.warning), SizedBox(width: 8), Text('Ativo')])),
                const PopupMenuItem(value: 'dormant', child: Row(children: [Icon(Icons.bedtime, size: 16, color: AppTheme.info), SizedBox(width: 8), Text('Dormente')])),
                const PopupMenuItem(value: 'resolved', child: Row(children: [Icon(Icons.check_circle, size: 16, color: AppTheme.success), SizedBox(width: 8), Text('Resolvido')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppTheme.error), SizedBox(width: 8), Text('Remover', style: TextStyle(color: AppTheme.error))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
