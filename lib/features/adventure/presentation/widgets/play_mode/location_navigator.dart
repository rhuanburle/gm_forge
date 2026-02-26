import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';
import 'detail_row.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';

class LocationNavigator extends ConsumerStatefulWidget {
  final String adventureId;
  const LocationNavigator({super.key, required this.adventureId});

  @override
  ConsumerState<LocationNavigator> createState() => _LocationNavigatorState();
}

class _LocationNavigatorState extends ConsumerState<LocationNavigator> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pois = ref.watch(pointsOfInterestProvider(widget.adventureId));
    final locations = ref.watch(locationsProvider(widget.adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    final filteredPois = pois.where((poi) {
      if (_searchQuery.isEmpty) return true;
      return poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.number.toString().contains(_searchQuery);
    }).toList();

    final poisByLocation = <String, List<PointOfInterest>>{};
    final orphanedPois = <PointOfInterest>[];

    for (final poi in filteredPois) {
      if (poi.locationId != null &&
          locations.any((l) => l.id == poi.locationId)) {
        poisByLocation.putIfAbsent(poi.locationId!, () => []).add(poi);
      } else {
        orphanedPois.add(poi);
      }
    }

    for (final list in poisByLocation.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }
    orphanedPois.sort((a, b) => a.number.compareTo(b.number));

    final creatures = ref.watch(creaturesProvider(widget.adventureId));
    final facts = ref.watch(factsProvider(widget.adventureId));
    final randomEvents = ref.watch(randomEventsProvider(widget.adventureId));

    final legends = ref.watch(legendsProvider(widget.adventureId));

    final filteredCreatures = creatures.where((c) {
      if (c.type != CreatureType.npc) return false;
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredMonsters = creatures.where((c) {
      if (c.type != CreatureType.monster) return false;
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Merge Facts and Legends for visibility
    final mergedFacts =
        [
          ...facts.map(
            (f) => {'type': 'fact', 'content': f.content, 'source': 'Fato'},
          ),
          ...legends.map(
            (l) => {'type': 'legend', 'content': l.text, 'source': 'Rumor'},
          ),
        ].where((item) {
          if (_searchQuery.isEmpty) return true;
          return item['content']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

    final filteredEvents = randomEvents.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.impact.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Locais'),
              Tab(text: 'NPCs'),
              Tab(text: 'Criaturas'),
              Tab(text: 'Rumores'),
              Tab(text: 'Eventos'),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // LOCATIONS TAB
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...locations.map((location) {
                      final locationPois = poisByLocation[location.id] ?? [];
                      if (_searchQuery.isNotEmpty && locationPois.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final hasActivePoi = locationPois.any(
                        (p) => p.id == activeState.currentLocationId,
                      );

                      return ExpansionTile(
                        key: PageStorageKey('zone-${location.id}'),
                        initiallyExpanded:
                            hasActivePoi || _searchQuery.isNotEmpty,
                        leading: const Icon(Icons.map, size: 20),
                        title: Text(
                          location.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: locationPois.isEmpty
                            ? const Text("Vazio")
                            : null,
                        children: locationPois
                            .map((poi) => _buildPoiTile(poi, activeState))
                            .toList(),
                      );
                    }),
                    if (orphanedPois.isNotEmpty) ...[
                      if (locations.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Divider(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Outros Locais',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ],
                      ...orphanedPois.map(
                        (poi) => _buildPoiTile(poi, activeState),
                      ),
                    ],
                  ],
                ),

                // NPCS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredCreatures.length,
                  itemBuilder: (context, index) {
                    final creature = filteredCreatures[index];
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.purple),
                      title: Text(creature.name),
                      subtitle: Text(
                        creature.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _showCreatureDetails(context, ref, creature);
                      },
                    );
                  },
                ),

                // CREATURES TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredMonsters.length,
                  itemBuilder: (context, index) {
                    final creature = filteredMonsters[index];
                    return ListTile(
                      leading: const Icon(Icons.pets, color: AppTheme.accent),
                      title: Text(creature.name),
                      subtitle: Text(
                        creature.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _showCreatureDetails(context, ref, creature);
                      },
                    );
                  },
                ),

                // FACTS & RUMORS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: mergedFacts.length,
                  itemBuilder: (context, index) {
                    final item = mergedFacts[index];
                    final isFact = item['type'] == 'fact';
                    return ListTile(
                      leading: Icon(
                        isFact ? Icons.lightbulb : Icons.chat_bubble_outline,
                        color: isFact ? AppTheme.secondary : AppTheme.primary,
                      ),
                      title: Text(item['content']!),
                      subtitle: Text(
                        item['source']!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),

                // EVENTS TAB
                Column(
                  children: [
                    if (randomEvents.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.casino),
                            label: const Text('Rolar Evento'),
                            onPressed: () => _rollEvent(context, randomEvents),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppTheme.warning.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                event.diceRange,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ),
                            title: Text(event.description),
                            subtitle: Text(
                              event.impact,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              _showEventDetails(context, event);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatureDetails(
    BuildContext context,
    WidgetRef ref,
    Creature creature,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              creature.type == CreatureType.npc ? Icons.person : Icons.pets,
              color: creature.type == CreatureType.npc
                  ? Colors.purple
                  : AppTheme.accent,
            ),
            const SizedBox(width: 8),
            Text(creature.name),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (creature.description.isNotEmpty) ...[
                Text(
                  creature.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
              ],
              DetailRow('Motivação', creature.motivation),
              const SizedBox(height: 8),
              DetailRow('Ao Perder', creature.losingBehavior),
              if (creature.stats.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Ficha',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.black12,
                  child: Text(
                    creature.stats,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(BuildContext context, RandomEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('Evento: ${event.eventType.displayName}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DetailRow('Rolagem', event.diceRange),
              const SizedBox(height: 8),
              DetailRow('Descrição', event.description),
              const SizedBox(height: 8),
              DetailRow('Impacto', event.impact),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _rollEvent(BuildContext context, List<RandomEvent> events) {
    if (events.isEmpty) return;

    final d1 = Random().nextInt(6) + 1;
    final d2 = Random().nextInt(6) + 1;
    final resultScore = int.parse('$d1$d2');

    // Find event that matches result
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('Resultado: $resultScore'),
          ],
        ),
        content: found != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    found.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Impacto: ${found.impact}'),
                ],
              )
            : const Text(
                'Nenhum evento correspondente encontrado para este resultado.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPoiTile(PointOfInterest poi, ActiveAdventureState activeState) {
    final isSelected = activeState.currentLocationId == poi.id;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${poi.number}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
      title: Text(
        poi.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        poi.purpose.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
      trailing: IconButton(
        icon: Icon(
          poi.isVisited ? Icons.check_circle : Icons.circle_outlined,
          color: poi.isVisited
              ? AppTheme.primary
              : AppTheme.textMuted.withValues(alpha: 0.5),
        ),
        onPressed: () async {
          final updatedPoi = poi.copyWith(isVisited: !poi.isVisited);
          await ref.read(hiveDatabaseProvider).savePointOfInterest(updatedPoi);
          ref.read(unsyncedChangesProvider.notifier).state = true;
        },
      ),
      onTap: () {
        ref.read(activeAdventureProvider.notifier).setLocation(poi.id);
      },
    );
  }
}
