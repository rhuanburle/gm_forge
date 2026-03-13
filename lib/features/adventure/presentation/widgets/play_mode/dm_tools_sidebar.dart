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
import 'combat_tracker_panel.dart';
import 'dice_roller_panel.dart';
import 'session_timer_panel.dart';

class DMToolsSidebar extends ConsumerStatefulWidget {
  final String adventureId;

  const DMToolsSidebar({super.key, required this.adventureId});

  @override
  ConsumerState<DMToolsSidebar> createState() => _DMToolsSidebarState();
}

class _DMToolsSidebarState extends ConsumerState<DMToolsSidebar> {
  final ScrollController _scrollController = ScrollController();

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
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.secondary.withValues(alpha: 0.1),
            width: double.infinity,
            child: const Text(
              'Escudo do Mestre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/adventure/${widget.adventureId}');
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'Editar Aventura',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: activeState.currentLocationId == null
                      ? null
                      : () {
                          context.push(
                            '/adventure/${widget.adventureId}/location/${activeState.currentLocationId}',
                          );
                        },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text(
                    'Editar Local Atual',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/adventure/${widget.adventureId}/session/new');
                  },
                  icon: const Icon(Icons.note_alt, size: 16),
                  label: const Text(
                    'Prep de Sessão',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                if (adventure.campaignId != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/campaign/${adventure.campaignId}');
                    },
                    icon: const Icon(Icons.auto_awesome_motion, size: 16),
                    label: const Text(
                      'Hub da Campanha',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const NameGeneratorDialog(),
                          );
                        },
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text(
                          'Nomes',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rollRandomEvent(context, ref),
                        icon: const Icon(Icons.casino, size: 16),
                        label: const Text(
                          'Evento',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppTheme.warning,
                          side: const BorderSide(color: AppTheme.warning),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Session timer
                    const SessionTimerPanel(),

                    // Combat tracker (always visible)
                    CombatTrackerPanel(adventureId: widget.adventureId),

                    // Dice roller
                    const DiceRollerPanel(),

                    if (adventure.conceptWhat.isNotEmpty ||
                        adventure.conceptConflict.isNotEmpty) ...[
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: const Text(
                            'Conceito da Aventura',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          children: [
                            if (adventure.conceptWhat.isNotEmpty) ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'O que está acontecendo?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  adventure.conceptWhat,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (adventure.conceptConflict.isNotEmpty) ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Qual é o conflito?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  adventure.conceptConflict,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bloco de Notas da Partida',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 400, // Fixed height for log inside scrollview
                      child: SessionLogPanel(adventureId: widget.adventureId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
