import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/adventure_providers.dart';
import '../../application/active_adventure_state.dart';
import '../../domain/domain.dart';
import '../widgets/smart_text_renderer.dart';
import '../../../../core/widgets/smart_network_image.dart';

// Placeholder widgets for panels
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

    // Filter logic
    final filteredPois = pois.where((poi) {
      if (_searchQuery.isEmpty) return true;
      return poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.number.toString().contains(_searchQuery);
    }).toList();

    // Group by Location
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

    // Sort POIs within groups
    for (final list in poisByLocation.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }
    orphanedPois.sort((a, b) => a.number.compareTo(b.number));

    return Column(
      children: [
        // Search Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar locais...',
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

        // List
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 1. Locations (Zones)
              ...locations.map((location) {
                final locationPois = poisByLocation[location.id] ?? [];
                // If searching and no matches in this zone, hide it
                if (_searchQuery.isNotEmpty && locationPois.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Check if any POI in this location is active to auto-expand
                final hasActivePoi = locationPois.any(
                  (p) => p.id == activeState.currentLocationId,
                );

                return ExpansionTile(
                  key: PageStorageKey('zone-${location.id}'),
                  initiallyExpanded: hasActivePoi || _searchQuery.isNotEmpty,
                  leading: const Icon(Icons.map, size: 20),
                  title: Text(
                    location.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: locationPois.isEmpty ? const Text("Vazio") : null,
                  children: locationPois
                      .map((poi) => _buildPoiTile(poi, activeState))
                      .toList(),
                );
              }),

              // 2. Orphaned POIs (if any)
              if (orphanedPois.isNotEmpty) ...[
                if (locations.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Outros Locais',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                ...orphanedPois.map((poi) => _buildPoiTile(poi, activeState)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoiTile(PointOfInterest poi, ActiveAdventureState activeState) {
    final isSelected = activeState.currentLocationId == poi.id;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.only(
        left: 16,
        right: 16,
      ), // Indent items in ExpansionTile
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: isSelected ? AppTheme.primary : Colors.grey.shade300,
        child: Text(
          '${poi.number}',
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.black87,
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

class SceneViewer extends ConsumerWidget {
  final String adventureId;
  const SceneViewer({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeAdventureProvider);
    final pois = ref.watch(pointsOfInterestProvider(adventureId));

    if (activeState.currentLocationId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.black12),
            const SizedBox(height: 16),
            Text(
              'Selecione um local para iniciar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.black45),
            ),
          ],
        ),
      );
    }

    final location = pois.firstWhere(
      (p) => p.id == activeState.currentLocationId,
      orElse: () => PointOfInterest(
        adventureId: adventureId,
        number: 0,
        name: 'Local Desconhecido',
        firstImpression: '',
        obvious: '',
        detail: '',
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '#${location.number}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  location.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Chip(label: Text(location.purpose.displayName)),
            ],
          ),
          const Divider(height: 32),

          // Image if exists
          if (location.imagePath != null && location.imagePath!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SmartNetworkImage(
                imageUrl: location.imagePath!,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Impressions
          _SectionTitle(icon: Icons.visibility, title: 'Primeira Impressão'),
          SmartTextRenderer(
            text: location.firstImpression,
            adventureId: adventureId,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),

          // Obvious
          _SectionTitle(icon: Icons.center_focus_strong, title: 'O Óbvio'),
          SmartTextRenderer(
            text: location.obvious,
            adventureId: adventureId,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Details (Spoiler / Investigation)
          ExpansionTile(
            title: const Text('Detalhes & Segredos'),
            leading: const Icon(Icons.search),
            childrenPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.black.withOpacity(0.02),
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: SmartTextRenderer(
                  text: location.detail,
                  adventureId: adventureId,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              if (location.treasure.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.diamond, size: 16, color: AppTheme.accent),
                    SizedBox(width: 8),
                    Text(
                      'Tesouro / Itens',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.topLeft,
                  child: SmartTextRenderer(
                    text: location.treasure,
                    adventureId: adventureId,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),

          // Creatures Section
          if (location.creatureIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(icon: Icons.pets, title: 'Criaturas & NPCs'),
            _CreatureList(
              adventureId: adventureId,
              creatureIds: location.creatureIds,
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatureList extends ConsumerWidget {
  final String adventureId;
  final List<String> creatureIds;

  const _CreatureList({required this.adventureId, required this.creatureIds});

  int _parseMaxHp(String stats) {
    // Try to find HP or PV in stats string (e.g. "HP: 10", "PV 20")
    final regex = RegExp(r'(?:HP|PV|Vida)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 10;
    }
    return 10; // Default
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCreatures = ref.watch(creaturesProvider(adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    // Filter creatures directly referenced by ID
    final creatures = allCreatures
        .where((c) => creatureIds.contains(c.id))
        .toList();

    if (creatures.isEmpty) {
      return const Text('Nenhuma criatura encontrada (IDs inválidos?)');
    }

    return Column(
      children: creatures.map((creature) {
        final maxHp = _parseMaxHp(creature.stats);
        final currentHp = activeState.monsterHp[creature.id] ?? maxHp;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creature.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            creature.type == CreatureType.monster
                                ? 'Monstro'
                                : 'NPC',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // HP Tracker
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            ref
                                .read(activeAdventureProvider.notifier)
                                .updateMonsterHp(creature.id, currentHp - 1);
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          iconSize: 24,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$currentHp',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            ref
                                .read(activeAdventureProvider.notifier)
                                .updateMonsterHp(creature.id, currentHp + 1);
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ],
                ),
                if (creature.stats.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    creature.stats,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (creature.motivation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Quer: ${creature.motivation}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AdventurePlayPage extends ConsumerStatefulWidget {
  final String adventureId;

  const AdventurePlayPage({super.key, required this.adventureId});

  @override
  ConsumerState<AdventurePlayPage> createState() => _AdventurePlayPageState();
}

class _AdventurePlayPageState extends ConsumerState<AdventurePlayPage> {
  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'adventure_title_${widget.adventureId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              adventure?.name ?? 'Aventura ...',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Voltar para Editor',
            onPressed: () {
              context.push('/adventure/edit/${widget.adventureId}');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Location Navigator (25%)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: LocationNavigator(adventureId: widget.adventureId),
            ),
          ),

          // Center Panel: Scene Viewer (75%)
          Expanded(
            flex: 9,
            child: SceneViewer(adventureId: widget.adventureId),
          ),
        ],
      ),
    );
  }
}
