import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../application/adventure_providers.dart';
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

    if (adventure == null) {
      return const Center(child: Text('Algo deu errado.'));
    }

    final totalLocations = locations.length + pois.length;
    final totalLegends = legends.length;
    final totalCreatures = creatures.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.map,
                  label: 'Locais',
                  value: '$totalLocations',
                  color: Colors.blue,
                  onTap: () => onTabChange(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.campaign,
                  label: 'Rumores',
                  value: '$totalLegends',
                  color: Colors.amber,
                  onTap: () => onTabChange(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.pets,
                  label: 'Criaturas',
                  value: '$totalCreatures',
                  color: Colors.red,
                  onTap: () => onTabChange(5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
