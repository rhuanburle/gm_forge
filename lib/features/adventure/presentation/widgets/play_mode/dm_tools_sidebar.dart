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
            Text('Evento Aleatório: $d1$d2'),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          foregroundColor: color,
          side: color != null ? BorderSide(color: color) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            Text(label, style: const TextStyle(fontSize: 9)),
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
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Dice roller
            const DiceRollerPanel(),

            // Adventure concept (always expanded for quick reference)
            if (adventure.conceptWhat.isNotEmpty ||
                adventure.conceptConflict.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 12),
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
}
