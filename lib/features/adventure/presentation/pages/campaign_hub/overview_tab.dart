import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';
import '../../widgets/campaign/session_timeline.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final String campaignId;

  const OverviewTab({super.key, required this.campaignId});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  String get campaignId => widget.campaignId;

  void _markUnsynced() {
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final campaign = ref.watch(campaignProvider(campaignId));
    if (campaign == null) return const SizedBox.shrink();

    final adventures = campaign.adventureIds
        .map((id) => ref.watch(adventureProvider(id)))
        .whereType<Adventure>()
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (campaign.description.isNotEmpty) ...[
          Text(
            campaign.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildAdventuresSection(context, adventures),
        const SizedBox(height: 24),
        _buildSessionTimelineSection(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Session Timeline
  // ---------------------------------------------------------------------------

  Widget _buildSessionTimelineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Histórico de Sessões',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        SessionTimeline(campaignId: campaignId),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Aventuras
  // ---------------------------------------------------------------------------

  Widget _buildAdventuresSection(
      BuildContext context, List<Adventure> adventures) {
    final scrollController = ScrollController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.map,
          title: 'Aventuras',
          onAdd: () => _showAddAdventureDialog(context),
        ),
        if (adventures.isEmpty)
          _emptyState(context, 'Nenhuma aventura vinculada a esta campanha.')
        else
          SizedBox(
            height: 180,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: adventures.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final adventure = adventures[index];
                  return SizedBox(
                    width: 220,
                    child: _adventureMiniCard(context, adventure),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _showAddAdventureDialog(BuildContext context) {
    final allAdventures = ref.read(adventuresProvider);
    final campaign = ref.read(campaignProvider(campaignId));
    if (campaign == null) return;

    // Filter adventures not yet linked to this campaign
    final unlinked = allAdventures
        .where((a) => a.campaignId == null || a.campaignId != campaignId)
        .toList();

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Aventura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Option 1: Link existing
              if (unlinked.isNotEmpty) ...[
                const Text(
                  'Vincular aventura existente:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ...unlinked.take(5).map((adventure) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.map, size: 18),
                  title: Text(adventure.name, style: const TextStyle(fontSize: 13)),
                  subtitle: adventure.description.isNotEmpty
                      ? Text(
                          adventure.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        )
                      : null,
                  onTap: () async {
                    final db = ref.read(hiveDatabaseProvider);
                    final updated = adventure.copyWith(campaignId: campaignId);
                    await db.saveAdventure(updated);
                    ref.invalidate(campaignListProvider);
                    ref.invalidate(adventureListProvider);
                    _markUnsynced();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                )),
                if (unlinked.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${unlinked.length - 5} mais...',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                const Divider(height: 24),
              ],
              // Option 2: Create new
              const Text(
                'Ou criar nova aventura:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Aventura *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final adventure = await ref
                  .read(adventureListProvider.notifier)
                  .create(
                    name: name,
                    description: descCtrl.text.trim(),
                    conceptWhat: '',
                    conceptConflict: '',
                    campaignId: campaignId,
                  );

              ref.invalidate(campaignListProvider);
              _markUnsynced();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                context.push('/adventure/${adventure.id}');
              }
            },
            child: const Text('Criar Aventura'),
          ),
        ],
      ),
    );
  }

  Widget _adventureMiniCard(BuildContext context, Adventure adventure) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/adventure/play/${adventure.id}'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface,
                AppTheme.primaryDark.withValues(alpha: 0.4),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.map, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  if (adventure.isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRONTA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                adventure.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                adventure.conceptWhat.isNotEmpty
                    ? adventure.conceptWhat
                    : adventure.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
