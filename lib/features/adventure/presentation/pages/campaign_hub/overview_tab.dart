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

  void _saveCampaign(Campaign updated) {
    ref
        .read(campaignListProvider.notifier)
        .update(updated.copyWith(updatedAt: DateTime.now()));
    _markUnsynced();
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
        // 3.1 Header Narrativo
        _buildNarrativeHeader(context, campaign),
        const SizedBox(height: 16),
        // 3.2 Plot Threads
        _buildPlotThreadsSection(context, campaign),
        const SizedBox(height: 16),
        // 3.3 Quests Ativas
        _buildActiveQuestsSection(context),
        const SizedBox(height: 16),
        // 3.4 Status das Facções
        _buildFactionsSection(context),
        const SizedBox(height: 16),
        // 3.5 Fluxo de Aventuras
        _buildAdventureFlowSection(context, campaign, adventures),
        const SizedBox(height: 24),
        // 3.6 Timeline de Sessões
        _buildSessionTimelineSection(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3.1 Header Narrativo
  // ---------------------------------------------------------------------------

  Widget _buildNarrativeHeader(BuildContext context, Campaign campaign) {
    final hasConflict = campaign.centralConflict.isNotEmpty;
    final hasArc = campaign.currentArc.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Central Conflict card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flash_on, size: 20, color: AppTheme.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conflito Central',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasConflict
                          ? campaign.centralConflict
                          : 'Nenhum conflito definido',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle:
                            hasConflict ? FontStyle.normal : FontStyle.italic,
                        color: hasConflict ? null : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _showEditNarrativeDialog(context, campaign),
                tooltip: 'Editar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
        if (hasArc) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.auto_stories, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              const Text(
                'Arco Atual:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  campaign.currentArc,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showEditNarrativeDialog(BuildContext context, Campaign campaign) {
    final conflictCtrl =
        TextEditingController(text: campaign.centralConflict);
    final arcCtrl = TextEditingController(text: campaign.currentArc);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Narrativa da Campanha'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: conflictCtrl,
                decoration: const InputDecoration(
                  labelText: 'Conflito Central',
                  hintText: 'A grande ameaça que move a história...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: arcCtrl,
                decoration: const InputDecoration(
                  labelText: 'Arco Atual',
                  hintText: 'Nome do arco narrativo atual',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveCampaign(campaign.copyWith(
                centralConflict: conflictCtrl.text.trim(),
                currentArc: arcCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3.2 Plot Threads
  // ---------------------------------------------------------------------------

  Widget _buildPlotThreadsSection(BuildContext context, Campaign campaign) {
    final threads = campaign.plotThreads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.timeline,
          title: 'Fios Narrativos',
          onAdd: () => _showAddPlotThreadDialog(context, campaign),
        ),
        if (threads.isEmpty)
          _emptyState(context, 'Nenhum fio narrativo adicionado.')
        else
          ...threads.map((thread) =>
              _buildPlotThreadTile(context, campaign, thread)),
      ],
    );
  }

  Widget _buildPlotThreadTile(
      BuildContext context, Campaign campaign, PlotThread thread) {
    Color statusColor;
    switch (thread.status) {
      case PlotThreadStatus.active:
        statusColor = AppTheme.success;
      case PlotThreadStatus.resolved:
        statusColor = AppTheme.info;
      case PlotThreadStatus.abandoned:
        statusColor = AppTheme.textMuted;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: thread.status != PlotThreadStatus.active
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          thread.status.displayName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (thread.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      thread.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) =>
                  _handlePlotThreadAction(value, campaign, thread),
              itemBuilder: (_) => [
                if (thread.status == PlotThreadStatus.active) ...[
                  const PopupMenuItem(
                    value: 'resolve',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: AppTheme.info),
                        SizedBox(width: 8),
                        Text('Resolver'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'abandon',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Text('Abandonar'),
                      ],
                    ),
                  ),
                ] else
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Row(
                      children: [
                        Icon(Icons.replay, size: 16, color: AppTheme.success),
                        SizedBox(width: 8),
                        Text('Reativar'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('Remover'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlotThreadAction(
      String action, Campaign campaign, PlotThread thread) {
    final threads = List<PlotThread>.from(campaign.plotThreads);
    final index = threads.indexWhere((t) => t.id == thread.id);
    if (index == -1) return;

    switch (action) {
      case 'resolve':
        threads[index] = thread.copyWith(status: PlotThreadStatus.resolved);
        _saveCampaign(campaign.copyWith(plotThreads: threads));
      case 'abandon':
        threads[index] = thread.copyWith(status: PlotThreadStatus.abandoned);
        _saveCampaign(campaign.copyWith(plotThreads: threads));
      case 'reactivate':
        threads[index] = thread.copyWith(status: PlotThreadStatus.active);
        _saveCampaign(campaign.copyWith(plotThreads: threads));
      case 'edit':
        _showEditPlotThreadDialog(context, campaign, thread);
      case 'remove':
        threads.removeAt(index);
        _saveCampaign(campaign.copyWith(plotThreads: threads));
    }
  }

  void _showAddPlotThreadDialog(BuildContext context, Campaign campaign) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Fio Narrativo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título *'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final threads = [
                ...campaign.plotThreads,
                PlotThread.create(
                  title: title,
                  description: descCtrl.text.trim(),
                ),
              ];
              _saveCampaign(campaign.copyWith(plotThreads: threads));
              Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showEditPlotThreadDialog(
      BuildContext context, Campaign campaign, PlotThread thread) {
    final titleCtrl = TextEditingController(text: thread.title);
    final descCtrl = TextEditingController(text: thread.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Fio Narrativo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final threads = List<PlotThread>.from(campaign.plotThreads);
              final index = threads.indexWhere((t) => t.id == thread.id);
              if (index != -1) {
                threads[index] = thread.copyWith(
                  title: title,
                  description: descCtrl.text.trim(),
                );
                _saveCampaign(campaign.copyWith(plotThreads: threads));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3.3 Quests Ativas (cross-adventure)
  // ---------------------------------------------------------------------------

  Widget _buildActiveQuestsSection(BuildContext context) {
    final allQuests = ref.watch(campaignQuestsProvider(campaignId));
    final activeQuests = allQuests
        .where((q) =>
            q.status != QuestStatus.completed &&
            q.status != QuestStatus.failed)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.flag, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quests Ativas',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              Text(
                '${activeQuests.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (activeQuests.isEmpty)
          _emptyState(context, 'Nenhuma quest ativa na campanha.')
        else
          ...activeQuests.map((quest) => _buildQuestTile(context, quest)),
      ],
    );
  }

  Widget _buildQuestTile(BuildContext context, Quest quest) {
    final completedObjectives =
        quest.objectives.where((o) => o.isComplete).length;
    final totalObjectives = quest.objectives.length;
    final progress =
        totalObjectives > 0 ? completedObjectives / totalObjectives : 0.0;

    Color statusColor;
    switch (quest.status) {
      case QuestStatus.notStarted:
        statusColor = AppTheme.textMuted;
      case QuestStatus.inProgress:
        statusColor = AppTheme.warning;
      case QuestStatus.completed:
        statusColor = AppTheme.success;
      case QuestStatus.failed:
        statusColor = AppTheme.error;
    }

    // Find source adventure name
    String? adventureName;
    if (quest.adventureId != null) {
      final adv = ref.read(adventureProvider(quest.adventureId!));
      adventureName = adv?.name;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quest.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quest.status.displayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (totalObjectives > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor:
                            AppTheme.textMuted.withValues(alpha: 0.12),
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedObjectives/$totalObjectives',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
            if (adventureName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.map, size: 10, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    adventureName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3.4 Status das Facções
  // ---------------------------------------------------------------------------

  Widget _buildFactionsSection(BuildContext context) {
    final factions = ref.watch(campaignFactionsProvider(campaignId));
    if (factions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.groups, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Facções',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        ...factions.map((faction) => _buildFactionTile(context, faction)),
      ],
    );
  }

  Widget _buildFactionTile(BuildContext context, Faction faction) {
    final isFront = faction.type == FactionType.front;
    final color = isFront ? AppTheme.warning : AppTheme.accent;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFront ? Icons.warning : Icons.groups,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    faction.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    faction.type.displayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (faction.objectives.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...faction.objectives.asMap().entries.map((entry) {
                final idx = entry.key;
                final obj = entry.value;
                final progress = obj.maxProgress > 0
                    ? obj.currentProgress / obj.maxProgress
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              obj.text,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor:
                                    AppTheme.textMuted.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${obj.currentProgress}/${obj.maxProgress}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _progressButton(
                        icon: Icons.remove,
                        onPressed: obj.currentProgress > 0
                            ? () =>
                                _updateFactionProgress(faction, idx, -1)
                            : null,
                      ),
                      _progressButton(
                        icon: Icons.add,
                        onPressed: obj.currentProgress < obj.maxProgress
                            ? () =>
                                _updateFactionProgress(faction, idx, 1)
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: Icon(icon, size: 14),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: AppTheme.textMuted,
        disabledColor: AppTheme.textMuted.withValues(alpha: 0.3),
      ),
    );
  }

  void _updateFactionProgress(Faction faction, int objectiveIndex, int delta) {
    final objectives = List<FactionObjective>.from(faction.objectives);
    final obj = objectives[objectiveIndex];
    final newProgress =
        (obj.currentProgress + delta).clamp(0, obj.maxProgress);
    objectives[objectiveIndex] =
        obj.copyWith(currentProgress: newProgress);
    final updated = faction.copyWith(objectives: objectives);

    final db = ref.read(hiveDatabaseProvider);
    db.saveFaction(updated);
    ref.invalidate(campaignFactionsProvider(campaignId));
    _markUnsynced();
  }

  // ---------------------------------------------------------------------------
  // 3.5 Fluxo de Aventuras
  // ---------------------------------------------------------------------------

  Widget _buildAdventureFlowSection(
      BuildContext context, Campaign campaign, List<Adventure> adventures) {
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
          ...List.generate(adventures.length, (index) {
            final adventure = adventures[index];
            final isLast = index == adventures.length - 1;

            return Column(
              children: [
                _adventureFlowCard(context, adventure),
                if (!isLast) ...[
                  // Connector with hint
                  _buildAdventureConnector(context, adventure),
                ],
              ],
            );
          }),
      ],
    );
  }

  Widget _adventureFlowCard(BuildContext context, Adventure adventure) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 0),
      child: InkWell(
        onTap: () => context.push('/adventure/play/${adventure.id}'),
        child: Container(
          width: double.infinity,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adventure.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
              const SizedBox(height: 6),
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
              if ((adventure.nextAdventureHint ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward,
                        size: 12, color: AppTheme.discovery),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        adventure.nextAdventureHint!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.discovery,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdventureConnector(BuildContext context, Adventure adventure) {
    final hint = adventure.nextAdventureHint ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                width: 2,
                height: 12,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
              Icon(
                Icons.arrow_downward,
                size: 14,
                color: hint.isNotEmpty
                    ? AppTheme.discovery
                    : AppTheme.textMuted.withValues(alpha: 0.3),
              ),
              Container(
                width: 2,
                height: 12,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.discovery.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddAdventureDialog(BuildContext context) {
    final allAdventures = ref.read(adventuresProvider);
    final campaign = ref.read(campaignProvider(campaignId));
    if (campaign == null) return;

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
                  title: Text(adventure.name,
                      style: const TextStyle(fontSize: 13)),
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
                    final updated =
                        adventure.copyWith(campaignId: campaignId);
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
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                const Divider(height: 24),
              ],
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
                decoration:
                    const InputDecoration(labelText: 'Nome da Aventura *'),
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

  // ---------------------------------------------------------------------------
  // 3.6 Session Timeline
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
