import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/smart_network_image.dart';
import '../../../../../core/sync/sync_service.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/adventure_clone_service.dart';
import '../../../domain/adventure.dart';

class AdventureCard extends ConsumerWidget {
  final Adventure adventure;
  final VoidCallback onEdit;

  const AdventureCard({
    super.key,
    required this.adventure,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage =
        adventure.dungeonMapPath != null &&
        adventure.dungeonMapPath!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryDark.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/adventure/play/${adventure.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.5, 0.95],
                  ).createShader(rect);
                },
                blendMode: BlendMode.darken,
                child: Hero(
                  tag: 'adventure_image_${adventure.id}',
                  child: SmartNetworkImage(
                    imageUrl: adventure.dungeonMapPath!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surface,
                      AppTheme.primaryDark.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.map,
                    size: 64,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),

            if (!hasImage)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (adventure.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'PRONTA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white70,
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'editor') {
                            context.push('/adventure/${adventure.id}');
                          } else if (value == 'delete') {
                            await ref
                                .read(adventureListProvider.notifier)
                                .delete(adventure.id);
                            ref
                                .read(syncServiceProvider)
                                .deleteAdventure(adventure.id);
                          } else if (value == 'duplicate') {
                            await ref
                                .read(adventureCloneServiceProvider)
                                .cloneAdventure(adventure);
                            ref.read(adventureListProvider.notifier).refresh();
                            ref.read(unsyncedChangesProvider.notifier).state =
                                true;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  color: AppTheme.secondary,
                                ),
                                SizedBox(width: 8),
                                Text('Editar Metadados'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'editor',
                            child: Row(
                              children: [
                                Icon(Icons.build, color: AppTheme.primary),
                                SizedBox(width: 8),
                                Text('Abrir Editor'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, color: AppTheme.secondary),
                                SizedBox(width: 8),
                                Text('Duplicar'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppTheme.error),
                                SizedBox(width: 8),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Hero(
                    tag: 'adventure_title_${adventure.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        adventure.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    adventure.conceptWhat.isNotEmpty
                        ? adventure.conceptWhat
                        : 'Local desconhecido',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('ESCUDO DO MESTRE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: AppTheme.background,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          context.push('/adventure/play/${adventure.id}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
