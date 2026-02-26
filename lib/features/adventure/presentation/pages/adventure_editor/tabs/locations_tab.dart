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
                          title: Text(location.name),
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
                          trailing: IconButton(
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
                                ref
                                        .read(unsyncedChangesProvider.notifier)
                                        .state =
                                    true;
                              }
                            },
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
                final newLocation = Location.create(
                  adventureId: adventureId,
                  name: 'Novo Local',
                  description: '',
                );

                final db = ref.read(hiveDatabaseProvider);
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
