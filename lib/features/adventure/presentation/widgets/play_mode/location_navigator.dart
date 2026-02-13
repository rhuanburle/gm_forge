import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';

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

    return Column(
      children: [
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

        Expanded(
          child: ListView(
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
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
