import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/ai/ai_providers.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../application/adventure_providers.dart';
import '../../../widgets/complications_dialog.dart';
import '../../../widgets/smart_text_renderer.dart';
import '../widgets/section_header.dart';

class SummaryTab extends ConsumerWidget {
  final String adventureId;
  final Function(int) onTabChange;

  const SummaryTab({
    super.key,
    required this.adventureId,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventure = ref.watch(adventureProvider(adventureId));
    final locations = ref.watch(locationsProvider(adventureId));
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final legends = ref.watch(legendsProvider(adventureId));
    final creatures = ref.watch(creaturesProvider(adventureId));
    final randomEvents = ref.watch(randomEventsProvider(adventureId));
    final facts = ref.watch(factsProvider(adventureId));
    final items = ref.watch(itemsProvider(adventureId));
    final quests = ref.watch(questsProvider(adventureId));

    if (adventure == null) {
      return const Center(child: Text('Algo deu errado.'));
    }

    final totalLocations = locations.length + pois.length;
    final totalLegends = legends.length;
    final totalCreatures = creatures.length;

    // --- Checklist items ---
    final checkItems = <_CheckItem>[
      _CheckItem(
        label: 'Conceito definido (Local + Conflito)',
        done: adventure.conceptWhat.isNotEmpty && adventure.conceptConflict.isNotEmpty,
        tabIndex: 1,
      ),
      _CheckItem(
        label: 'Pelo menos 1 Location criado',
        done: locations.isNotEmpty,
        tabIndex: 3,
      ),
      _CheckItem(
        label: 'Pelo menos 3 POIs (salas/cenas)',
        done: pois.length >= 3,
        tabIndex: 3,
      ),
      _CheckItem(
        label: 'POIs com conexões definidas',
        done: pois.isNotEmpty && pois.any((p) => p.connections.isNotEmpty),
        tabIndex: 3,
      ),
      _CheckItem(
        label: 'Pelo menos 1 criatura ou NPC',
        done: creatures.isNotEmpty,
        tabIndex: 5,
      ),
      _CheckItem(
        label: 'Pelo menos 1 rumor/lenda',
        done: legends.isNotEmpty,
        tabIndex: 2,
      ),
      _CheckItem(
        label: 'Eventos aleatórios preparados',
        done: randomEvents.isNotEmpty,
        tabIndex: 4,
      ),
      _CheckItem(
        label: 'Fatos/segredos plantados',
        done: facts.isNotEmpty,
        tabIndex: 5,
      ),
      _CheckItem(
        label: 'Itens/tesouros definidos',
        done: items.isNotEmpty,
        tabIndex: 6,
      ),
      _CheckItem(
        label: 'Missões criadas',
        done: quests.isNotEmpty,
        tabIndex: 7,
      ),
    ];
    final doneCount = checkItems.where((c) => c.done).length;
    final progress = checkItems.isEmpty ? 0.0 : doneCount / checkItems.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Quick Actions ---
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.shield,
                  label: 'Escudo do Mestre',
                  color: AppTheme.primary,
                  onTap: () => context.push('/adventure/play/$adventureId'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.history_edu,
                  label: 'Sessões',
                  color: AppTheme.secondary,
                  onTap: () => context.push('/adventure/$adventureId/sessions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Metrics ---
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.map,
                  label: 'Locais',
                  value: '$totalLocations',
                  color: AppTheme.narrative,
                  onTap: () => onTabChange(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.campaign,
                  label: 'Rumores',
                  value: '$totalLegends',
                  color: AppTheme.discovery,
                  onTap: () => onTabChange(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.pets,
                  label: 'Criaturas',
                  value: '$totalCreatures',
                  color: AppTheme.combat,
                  onTap: () => onTabChange(5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Adventure Checklist ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        progress >= 1.0 ? Icons.check_circle : Icons.checklist,
                        color: progress >= 1.0 ? AppTheme.success : AppTheme.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Checklist de Preparação',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '$doneCount/${checkItems.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: progress >= 1.0 ? AppTheme.success : AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.textMuted.withValues(alpha: 0.15),
                      color: progress >= 1.0 ? AppTheme.success : AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...checkItems.map((item) => InkWell(
                    onTap: item.done ? null : () => onTabChange(item.tabIndex),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            item.done ? Icons.check_circle : Icons.circle_outlined,
                            size: 18,
                            color: item.done
                                ? AppTheme.success
                                : AppTheme.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.done ? AppTheme.textMuted : null,
                                decoration: item.done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (!item.done)
                            const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (ref.watch(hasAiConfiguredProvider)) ...[
            _AiActionCard(
              icon: Icons.auto_awesome,
              title: "Gerar Aventura com IA",
              subtitle: adventure.conceptWhat.isNotEmpty
                  ? "Cria locais, criaturas, rumores e eventos automaticamente"
                  : "Preencha o Conceito primeiro",
              enabled:
                  adventure.conceptWhat.isNotEmpty &&
                  adventure.conceptConflict.isNotEmpty,
              onTap: () => context.push('/adventure/$adventureId/generate'),
            ),
            const SizedBox(height: 8),
            _AiActionCard(
              icon: Icons.bolt,
              title: "Sugerir Complicações",
              subtitle: (creatures.isNotEmpty || locations.isNotEmpty)
                  ? "Twists narrativos baseados na aventura atual"
                  : "Adicione criaturas ou locais primeiro",
              enabled: creatures.isNotEmpty || locations.isNotEmpty,
              onTap: () => showDialog(
                context: context,
                builder: (_) => ComplicationsDialog(adventureId: adventureId),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SectionHeader(
            icon: Icons.dashboard,
            title: 'Visão Geral',
            subtitle: 'Resumo rápido do que está preparado',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conceito',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (adventure.conceptWhat.isEmpty)
                    const Text(
                      'Ainda não definido.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    SmartTextRenderer(
                      text: adventure.conceptWhat,
                      adventureId: adventureId,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Conflito Central',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (adventure.conceptConflict.isEmpty)
                    const Text(
                      'Ainda não definido.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    SmartTextRenderer(
                      text: adventure.conceptConflict,
                      adventureId: adventureId,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => onTabChange(1),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Conceito'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String label;
  final bool done;
  final int tabIndex;
  const _CheckItem({required this.label, required this.done, required this.tabIndex});
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _AiActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: enabled ? AppTheme.primary.withValues(alpha: 0.04) : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppTheme.primary : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: enabled ? null : AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? AppTheme.primary : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
