import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';
import 'detail_row.dart';

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

    final filteredCreatures = creatures.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredFacts = facts.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredEvents = randomEvents.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.impact.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DefaultTabController(
      length: 4,
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
              Tab(text: 'Fatos'),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  itemCount: filteredCreatures.length,
                  itemBuilder: (context, index) {
                    final creature = filteredCreatures[index];
                    return ListTile(
                      leading: Icon(
                        creature.type == CreatureType.npc
                            ? Icons.person
                            : Icons.pets,
                        color: creature.type == CreatureType.npc
                            ? Colors.purple
                            : AppTheme.accent,
                      ),
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

                // FACTS TAB
                ListView.builder(
                  itemCount: filteredFacts.length,
                  itemBuilder: (context, index) {
                    final fact = filteredFacts[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.lightbulb,
                        color: AppTheme.secondary,
                      ),
                      title: Text(fact.content),
                      onTap: () {
                        _showFactDetails(context, fact);
                      },
                    );
                  },
                ),

                // EVENTS TAB
                ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.casino,
                        color: AppTheme.warning,
                      ),
                      title: Text(
                        '[${event.diceRange}] ${event.eventType.displayName}',
                      ),
                      subtitle: Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _showEventDetails(context, event);
                      },
                    );
                  },
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
                  style: const TextStyle(fontStyle: FontStyle.italic),
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
                    style: const TextStyle(fontFamily: 'monospace'),
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

  void _showFactDetails(BuildContext context, Fact fact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text('Fato / Rumor'),
          ],
        ),
        content: Text(fact.content),
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

  Widget _buildPoiTile(PointOfInterest poi, ActiveAdventureState activeState) {
    final isSelected = activeState.currentLocationId == poi.id;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: isSelected
            ? AppTheme.primary
            : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300),
        child: Text(
          '${poi.number}',
          style: TextStyle(
            fontSize: 10,
            color: isSelected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87),
          ),
        ),
      ),
      title: Text(
        poi.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        poi.purpose.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10),
      ),
      onTap: () {
        ref.read(activeAdventureProvider.notifier).setLocation(poi.id);
      },
    );
  }
}
