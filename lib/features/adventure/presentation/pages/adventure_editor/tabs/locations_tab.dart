import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../widgets/section_header.dart';

class LocationsTab extends ConsumerWidget {
  final String adventureId;

  const LocationsTab({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.map,
            title: 'Locais & Encontros',
            subtitle: 'Onde a ação acontece',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: locations.isEmpty
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
                        const Text(
                          'Nenhum local definido. Adicione salas, clareiras ou pontos de interesse.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(location.name),
                              const SizedBox(width: 8),
                              if (location.adventureId == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    "CAMPANHA",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.textMuted.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "LOCAL",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            location.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            context.push(
                              '/adventure/$adventureId/location/${location.id}',
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (location.adventureId != null)
                                IconButton(
                                  icon: const Icon(Icons.drive_file_move_outlined),
                                  tooltip: "Promover para Campanha",
                                  onPressed: () async {
                                    final db = ref.read(hiveDatabaseProvider);
                                    final promoted = location.copyWith(clearAdventureId: true);
                                    
                                    // Get POIs to cascade
                                    final pois = ref.read(pointsOfInterestProvider(adventureId));
                                    final locationPois = pois.where((p) => p.locationId == location.id).toList();
                                    final promotedPois = locationPois.map((p) => p.copyWith(clearAdventureId: true)).toList();

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
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Local promovido para a Campanha")),
                                      );
                                    }
                                  },
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppTheme.error,
                                ),
                                onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remover Local?'),
                                  content: const Text(
                                    'Essa ação não pode ser desfeita.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
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
                                await db.deleteLocation(location.id);

                                ref
                                    .read(historyProvider.notifier)
                                    .recordAction(
                                      HistoryAction(
                                        description: 'Local removido',
                                        onUndo: () async {
                                          await db.saveLocation(location);
                                          ref.invalidate(
                                            locationsProvider(adventureId),
                                          );
                                        },
                                        onRedo: () async {
                                          await db.deleteLocation(location.id);
                                          ref.invalidate(
                                            locationsProvider(adventureId),
                                          );
                                        },
                                      ),
                                    );

                                    ref.invalidate(locationsProvider(adventureId));
                                    ref.read(unsyncedChangesProvider.notifier).state = true;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
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

                ref
                    .read(historyProvider.notifier)
                    .recordAction(
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
                if (context.mounted) {
                  context.push(
                    '/adventure/$adventureId/location/${newLocation.id}',
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Local'),
            ),
          ),
        ],
      ),
    );
  }
}
