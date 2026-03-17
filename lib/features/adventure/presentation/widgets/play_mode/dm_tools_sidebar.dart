import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';
import 'session_log_panel.dart';
import 'name_generator_dialog.dart';
import 'quick_reference_panel.dart';
import 'campaign_summary_panel.dart';
import 'dice_roller_panel.dart';
import 'combat_tracker_panel.dart';
import 'exploration_tracker_panel.dart';
import 'previous_session_recap.dart';
import 'gm_inspiration_panel.dart';

class DMToolsSidebar extends ConsumerStatefulWidget {
  final String adventureId;

  const DMToolsSidebar({super.key, required this.adventureId});

  @override
  ConsumerState<DMToolsSidebar> createState() => _DMToolsSidebarState();
}

class _DMToolsSidebarState extends ConsumerState<DMToolsSidebar> {
  final ScrollController _scrollController = ScrollController();
  int _currentPanel = 0; // 0=tools, 1=combat, 2=log

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _rollRandomEvent(BuildContext context, WidgetRef ref) {
    final events = ref.read(randomEventsProvider(widget.adventureId));
    if (events.isEmpty) {
      AppSnackBar.info(context, 'Nenhum evento aleatório cadastrado nesta aventura.');
      return;
    }

    final rng = Random();
    final d1 = rng.nextInt(6) + 1;
    final d2 = rng.nextInt(6) + 1;
    final resultScore = int.parse('$d1$d2');

    RandomEvent? found;
    for (final e in events) {
      if (e.diceRange.contains('-')) {
        final parts = e.diceRange.split('-');
        final start = int.tryParse(parts[0]) ?? 0;
        final end = int.tryParse(parts[1]) ?? 0;
        if (resultScore >= start && resultScore <= end) {
          found = e;
          break;
        }
      } else if (int.tryParse(e.diceRange) == resultScore) {
        found = e;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino, color: AppTheme.warning),
            const SizedBox(width: 8),
            Expanded(child: Text('Evento Aleatório: $d1$d2')),
          ],
        ),
        content: found != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      found.eventType.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    found.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (found.impact.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Impacto: ${found.impact}'),
                  ],
                ],
              )
            : const Text('Nenhum evento correspondente para este resultado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    if (adventure == null) return const SizedBox.shrink();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Panel selector tabs
          Container(
            color: AppTheme.secondary.withValues(alpha: 0.1),
            child: Row(
              children: [
                _tabButton(0, Icons.shield, 'Escudo'),
                _tabButton(1, Icons.flash_on, 'Combate'),
                _tabButton(2, Icons.menu_book, 'Log'),
              ],
            ),
          ),
          // Quick Actions (always visible)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _quickActionButton(
                  icon: Icons.person_add,
                  label: 'Nomes',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const NameGeneratorDialog(),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _quickActionButton(
                  icon: Icons.casino,
                  label: 'Evento',
                  color: AppTheme.warning,
                  onPressed: () => _rollRandomEvent(context, ref),
                ),
                const SizedBox(width: 6),
                _quickActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  onPressed: () {
                    context.push('/adventure/${widget.adventureId}');
                  },
                ),
                if (adventure.campaignId != null) ...[
                  const SizedBox(width: 6),
                  _quickActionButton(
                    icon: Icons.auto_awesome_motion,
                    label: 'Camp.',
                    onPressed: () {
                      context.push('/campaign/${adventure.campaignId}');
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Panel content
          Expanded(
            child: IndexedStack(
              index: _currentPanel,
              children: [
                // Panel 0: Escudo (Tools)
                _buildToolsPanel(context, adventure, activeState),
                // Panel 1: Combate
                CombatTrackerPanel(adventureId: widget.adventureId),
                // Panel 2: Session Log
                SessionLogPanel(adventureId: widget.adventureId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final isSelected = _currentPanel == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentPanel = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.secondary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppTheme.secondary : AppTheme.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.secondary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          foregroundColor: color,
          side: color != null ? BorderSide(color: color) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsPanel(
    BuildContext context,
    Adventure adventure,
    ActiveAdventureState activeState,
  ) {
    final pois = ref.watch(pointsOfInterestProvider(widget.adventureId));
    final creatures = ref.watch(creaturesProvider(widget.adventureId));
    final facts = ref.watch(factsProvider(widget.adventureId));

    // Current location info
    PointOfInterest? currentPoi;
    if (activeState.currentLocationId != null) {
      currentPoi = pois
          .where((p) => p.id == activeState.currentLocationId)
          .firstOrNull;
    }

    // Fact tracking
    final totalFacts = facts.length;
    final revealedCount = facts.where((f) => activeState.revealedFacts.contains(f.id)).length;
    final secretFacts = facts.where((f) => f.isSecret).length;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Dice roller
            const DiceRollerPanel(),

            // Exploration tracker (turns, resources, checkboxes)
            const ExplorationTrackerPanel(),
            const Divider(height: 1),

            // Previous session recap
            PreviousSessionRecap(adventureId: widget.adventureId),
            const Divider(height: 1),

            // GM Inspiration (random tables)
            GmInspirationPanel(campaignId: adventure.campaignId),
            const Divider(height: 1),

            // Scratchpad
            const _ScratchpadPanel(),
            const Divider(height: 1),

            // March & Watch Order
            const _OrdersPanel(),
            const Divider(height: 1),

            // Narrative panel (campaign context)
            if (adventure.campaignId != null)
              _buildNarrativePanel(context, adventure),

            // Current scene quick reference
            if (currentPoi != null) ...[
              _buildCurrentSceneCard(context, currentPoi, creatures, activeState),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],

            // Fact/Discovery tracker
            if (totalFacts > 0) ...[
              _buildFactTracker(context, totalFacts, revealedCount, secretFacts),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],

            // Adventure concept (always expanded for quick reference)
            if (adventure.conceptWhat.isNotEmpty ||
                adventure.conceptConflict.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, size: 14, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'Conceito da Aventura',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (adventure.conceptWhat.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        adventure.conceptWhat,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                    if (adventure.conceptConflict.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, size: 12, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              adventure.conceptConflict,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Secondary conflicts
                    if (adventure.conceptSecondaryConflicts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...adventure.conceptSecondaryConflicts.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.subdirectory_arrow_right, size: 12,
                                color: AppTheme.textMuted.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    // Narrative hook
                    if ((adventure.nextAdventureHint ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.link, size: 12, color: AppTheme.discovery),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              adventure.nextAdventureHint!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.discovery,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            if (adventure.campaignId != null) ...[
              CampaignSummaryPanel(campaignId: adventure.campaignId!),
              const Divider(height: 1),
            ],
            QuickReferencePanel(campaignId: adventure.campaignId),
          ],
        ),
      ),
    );
  }

  /// Narrative context panel showing campaign plot threads, quests, and hint
  Widget _buildNarrativePanel(BuildContext context, Adventure adventure) {
    final campaign = ref.watch(campaignProvider(adventure.campaignId!));
    if (campaign == null) return const SizedBox.shrink();

    final activeThreads = campaign.plotThreads
        .where((t) => t.status == PlotThreadStatus.active)
        .toList();
    final quests = ref.watch(questsProvider(adventure.id));
    final activeQuests = quests
        .where((q) =>
            q.status != QuestStatus.completed &&
            q.status != QuestStatus.failed)
        .toList();
    final hint = adventure.nextAdventureHint ?? '';

    if (activeThreads.isEmpty && activeQuests.isEmpty && hint.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories, size: 14, color: AppTheme.secondary),
              SizedBox(width: 6),
              Text(
                'Contexto Narrativo',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Plot threads
          if (activeThreads.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...activeThreads.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],
          // Active quests for this adventure
          if (activeQuests.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...activeQuests.map((q) {
              final statusIcon = q.status == QuestStatus.inProgress
                  ? Icons.flag
                  : Icons.flag_outlined;
              final statusColor = q.status == QuestStatus.inProgress
                  ? AppTheme.warning
                  : AppTheme.textMuted;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 10, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        q.name,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Next adventure hint
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_forward, size: 10, color: AppTheme.discovery),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.discovery,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Quick reference card showing the current scene's creatures and purpose
  Widget _buildCurrentSceneCard(
    BuildContext context,
    PointOfInterest poi,
    List<Creature> allCreatures,
    ActiveAdventureState activeState,
  ) {
    final sceneCreatures = allCreatures
        .where((c) => poi.creatureIds.contains(c.id))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, size: 14, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '#${poi.number} ${poi.name}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  poi.purpose.displayName,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          if (sceneCreatures.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...sceneCreatures.map((c) {
              final maxHp = _parseHp(c.stats);
              final currentHp = activeState.monsterHp[c.id] ?? maxHp;
              final hpRatio = maxHp > 0 ? currentHp / maxHp : 1.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      c.type == CreatureType.npc ? Icons.person : Icons.pets,
                      size: 12,
                      color: c.type == CreatureType.npc ? AppTheme.npc : AppTheme.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.type == CreatureType.monster) ...[
                      SizedBox(
                        width: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: hpRatio.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppTheme.textMuted.withValues(alpha: 0.15),
                            color: hpRatio > 0.5
                                ? AppTheme.success
                                : hpRatio > 0.25
                                    ? AppTheme.warning
                                    : AppTheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentHp',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hpRatio > 0.5
                              ? AppTheme.success
                              : hpRatio > 0.25
                                  ? AppTheme.warning
                                  : AppTheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          if (poi.connections.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.alt_route, size: 10, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  'Saídas: ${poi.connections.join(", ")}',
                  style: TextStyle(fontSize: 9, color: AppTheme.textMuted.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tracker showing how many facts have been revealed to players
  Widget _buildFactTracker(BuildContext context, int total, int revealed, int secrets) {
    final progress = total > 0 ? revealed / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, size: 14, color: AppTheme.discovery),
              const SizedBox(width: 6),
              const Text(
                'Revelações',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.discovery,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$revealed/$total revelados',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                ),
              ),
              if (secrets > 0) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock, size: 10, color: AppTheme.combat.withValues(alpha: 0.6)),
                const SizedBox(width: 2),
                Text(
                  '$secrets',
                  style: TextStyle(fontSize: 10, color: AppTheme.combat.withValues(alpha: 0.6)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.textMuted.withValues(alpha: 0.12),
              color: AppTheme.discovery,
            ),
          ),
        ],
      ),
    );
  }

  int _parseHp(String stats) {
    final regex = RegExp(r'(?:HP|PV|Vida)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    return match != null ? (int.tryParse(match.group(1) ?? '') ?? 10) : 10;
  }
}

// ---------------------------------------------------------------------------
// Scratchpad — stateful to keep TextEditingController stable
// ---------------------------------------------------------------------------

class _ScratchpadPanel extends ConsumerStatefulWidget {
  const _ScratchpadPanel();

  @override
  ConsumerState<_ScratchpadPanel> createState() => _ScratchpadPanelState();
}

class _ScratchpadPanelState extends ConsumerState<_ScratchpadPanel> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(activeAdventureProvider).scratchpad,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _controller.text.isNotEmpty,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: const Icon(Icons.note_alt, size: 16, color: AppTheme.warning),
        title: const Text(
          'Rascunho',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.warning,
          ),
        ),
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Anotações rápidas...',
              hintStyle: TextStyle(fontSize: 11, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(10),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeAdventureProvider.notifier).updateScratchpad(val);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// March / Watch Order — stateful to keep TextEditingControllers stable
// ---------------------------------------------------------------------------

class _OrdersPanel extends ConsumerStatefulWidget {
  const _OrdersPanel();

  @override
  ConsumerState<_OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends ConsumerState<_OrdersPanel> {
  late TextEditingController _marchController;
  late TextEditingController _watchController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(activeAdventureProvider);
    _marchController = TextEditingController(text: state.marchOrder);
    _watchController = TextEditingController(text: state.watchOrder);
  }

  @override
  void dispose() {
    _marchController.dispose();
    _watchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _marchController.text.isNotEmpty || _watchController.text.isNotEmpty,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: const Icon(Icons.group, size: 16, color: AppTheme.secondary),
        title: const Text(
          'Ordem de Marcha / Vigília',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondary,
          ),
        ),
        children: [
          TextField(
            controller: _marchController,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              labelText: 'Marcha',
              labelStyle: const TextStyle(fontSize: 11),
              hintText: 'ex: Guerreiro > Mago > Ladino > Clérigo',
              hintStyle: TextStyle(fontSize: 10, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(8),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeAdventureProvider.notifier).updateMarchOrder(val);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _watchController,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              labelText: 'Vigília',
              labelStyle: const TextStyle(fontSize: 11),
              hintText: 'ex: 1o turno: Guerreiro, 2o turno: Mago...',
              hintStyle: TextStyle(fontSize: 10, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(8),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(activeAdventureProvider.notifier).updateWatchOrder(val);
            },
          ),
        ],
      ),
    );
  }
}
