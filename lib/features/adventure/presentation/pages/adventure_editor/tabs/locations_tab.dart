import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../../../core/widgets/entity_filter_bar.dart';
import '../../../../../../core/widgets/import_json_dialog.dart';
import '../../../../../../core/widgets/tags_editor.dart';
import '../../../../../../core/services/image_upload_service.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../widgets/section_header.dart';

class LocationsTab extends ConsumerStatefulWidget {
  final String adventureId;

  const LocationsTab({super.key, required this.adventureId});

  @override
  ConsumerState<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends ConsumerState<LocationsTab> {
  String _searchQuery = '';
  Set<String> _selectedTags = {};
  LocationStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final adventureId = widget.adventureId;
    final locations = ref.watch(locationsProvider(adventureId));

    final availableTags = <String>{
      for (final l in locations) ...l.tags,
    }.toList()
      ..sort();

    final filtered = locations.where((l) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = l.name.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q) ||
            l.tags.any((t) => t.toLowerCase().contains(q));
        if (!matches) return false;
      }
      if (_selectedTags.isNotEmpty &&
          !_selectedTags.any((t) => l.tags.contains(t))) {
        return false;
      }
      if (_statusFilter != null && l.status != _statusFilter) return false;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.map,
            title: 'Locais & Encontros',
            subtitle: 'Onde a ação acontece',
            trailing: IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: 'Importar via JSON',
              color: AppTheme.textMuted,
              onPressed: () => _showImportDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          EntityFilterBar(
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            availableTags: availableTags,
            selectedTags: _selectedTags,
            onTagsChanged: (s) => setState(() => _selectedTags = s),
            hint: 'Buscar locais...',
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('Todos',
                        style: TextStyle(fontSize: 11)),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                for (final s in LocationStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${s.icon} ${s.displayName}',
                          style: const TextStyle(fontSize: 11)),
                      selected: _statusFilter == s,
                      onSelected: (_) => setState(() => _statusFilter = s),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          locations.isEmpty
                              ? 'Nenhum local definido. Adicione salas, clareiras ou pontos de interesse.'
                              : 'Nenhum resultado para o filtro atual.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final location = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.push(
                              '/adventure/$adventureId/location/${location.id}',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary
                                      .withValues(alpha: 0.1),
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            location.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          _StatusBadge(
                                            label:
                                                '${location.status.icon} ${location.status.displayName}',
                                            color: _statusColor(
                                                location.status),
                                          ),
                                          if (location.adventureId == null)
                                            _StatusBadge(
                                              label: 'CAMPANHA',
                                              color: AppTheme.primary,
                                              icon: Icons.public,
                                            ),
                                        ],
                                      ),
                                      if (location.description.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            location.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ),
                                      if (location.tags.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        TagsDisplay(tags: location.tags),
                                      ],
                                    ],
                                  ),
                                ),
                                if (location.adventureId != null)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.drive_file_move_outlined),
                                    tooltip: "Promover para Campanha",
                                    onPressed: () =>
                                        _promoteLocation(location),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () => _deleteLocation(location),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _createLocation,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Local'),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(LocationStatus s) {
    switch (s) {
      case LocationStatus.intact:
        return AppTheme.success;
      case LocationStatus.damaged:
        return AppTheme.warning;
      case LocationStatus.destroyed:
        return AppTheme.error;
      case LocationStatus.occupied:
        return AppTheme.accent;
      case LocationStatus.liberated:
        return AppTheme.info;
      case LocationStatus.hidden:
        return AppTheme.textMuted;
    }
  }

  void _showImportDialog(BuildContext context) {
    showImportJsonDialog(
      context: context,
      title: 'Importar Local',
      exampleJson: '''{
  "name": "Caverna dos Cristais",
  "description": "Uma caverna com cristais luminescentes nas paredes",
  "status": 0,
  "scenicEncounters": [
    "Um morcego solitário observa os aventureiros",
    "Ecos distantes de água pingando"
  ],
  "tags": ["dungeon", "caverna"]
}''',
      legend: 'status: 0=Intacto  1=Danificado  2=Destruído  3=Ocupado  4=Liberado  5=Escondido',
      onImport: (json) async {
        final adventureId = widget.adventureId;
        final db = ref.read(hiveDatabaseProvider);
        final adv = db.getAdventure(adventureId);
        final campaignId = adv?.campaignId ?? adventureId;
        json['id'] = const Uuid().v4();
        json['campaignId'] = campaignId;
        json['adventureId'] = adventureId;
        try {
          final location = Location.fromJson(json);
          await db.saveLocation(location);
          ref.invalidate(locationsProvider(adventureId));
          ref.read(unsyncedChangesProvider.notifier).state = true;
          if (context.mounted) AppSnackBar.success(context, '"${location.name}" importado!');
        } catch (e) {
          if (context.mounted) AppSnackBar.error(context, 'Erro ao importar: $e');
        }
      },
    );
  }

  Future<void> _createLocation() async {
    final adventureId = widget.adventureId;
    final db = ref.read(hiveDatabaseProvider);
    final adv = db.getAdventure(adventureId);
    final campaignId = adv?.campaignId ?? adventureId;

    final newLocation = Location.create(
      campaignId: campaignId,
      adventureId: adventureId,
      name: 'Novo Local',
      description: '',
    );

    await db.saveLocation(newLocation);

    ref.read(historyProvider.notifier).recordAction(
          HistoryAction(
            description: 'Local criado',
            onUndo: () async {
              await db.deleteLocation(newLocation.id);
              ref.invalidate(locationsProvider(adventureId));
            },
            onRedo: () async {
              await db.saveLocation(newLocation);
              ref.invalidate(locationsProvider(adventureId));
            },
          ),
        );

    ref.invalidate(locationsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
    if (mounted) {
      context.push(
        '/adventure/$adventureId/location/${newLocation.id}',
      );
    }
  }

  Future<void> _promoteLocation(Location location) async {
    final adventureId = widget.adventureId;
    final db = ref.read(hiveDatabaseProvider);
    final promoted = location.copyWith(clearAdventureId: true);

    final pois = ref.read(pointsOfInterestProvider(adventureId));
    final locationPois =
        pois.where((p) => p.locationId == location.id).toList();
    final promotedPois = locationPois
        .map((p) => p.copyWith(clearAdventureId: true))
        .toList();

    await db.saveLocation(promoted);
    for (final p in promotedPois) {
      await db.savePointOfInterest(p);
    }

    ref.read(historyProvider.notifier).recordAction(
          HistoryAction(
            description: "Local promovido para Campanha",
            onUndo: () async {
              await db.saveLocation(location);
              for (final p in locationPois) {
                await db.savePointOfInterest(p);
              }
              ref.invalidate(locationsProvider(adventureId));
              ref.invalidate(pointsOfInterestProvider(adventureId));
            },
            onRedo: () async {
              await db.saveLocation(promoted);
              for (final p in promotedPois) {
                await db.savePointOfInterest(p);
              }
              ref.invalidate(locationsProvider(adventureId));
              ref.invalidate(pointsOfInterestProvider(adventureId));
            },
          ),
        );

    ref.invalidate(locationsProvider(adventureId));
    ref.invalidate(pointsOfInterestProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Local promovido para a Campanha")),
      );
    }
  }

  Future<void> _deleteLocation(Location location) async {
    final adventureId = widget.adventureId;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Local?'),
        content: const Text(
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(hiveDatabaseProvider);
      // Collect images from location + its POIs before deletion
      final imageUrls = <String>[
        if (location.imagePath?.isNotEmpty == true) location.imagePath!,
        ...db.getPointsOfInterest(widget.adventureId)
            .where((p) => p.locationId == location.id)
            .map((p) => p.imagePath ?? '')
            .where((s) => s.isNotEmpty),
      ];
      await db.deleteLocation(location.id);
      for (final url in imageUrls) ImageUploadService.deleteByUrl(url);

      ref.read(historyProvider.notifier).recordAction(
            HistoryAction(
              description: 'Local removido',
              onUndo: () async {
                await db.saveLocation(location);
                ref.invalidate(locationsProvider(adventureId));
              },
              onRedo: () async {
                await db.deleteLocation(location.id);
                ref.invalidate(locationsProvider(adventureId));
              },
            ),
          );

      ref.invalidate(locationsProvider(adventureId));
      ref.read(unsyncedChangesProvider.notifier).state = true;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
