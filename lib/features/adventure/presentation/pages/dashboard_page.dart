import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_button.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../../domain/adventure.dart';
import '../../domain/campaign.dart';

/// Dashboard - Main landing page
///
/// Shows list of adventures with ability to create new ones.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();

  static void showAdventureDialog(
    BuildContext context,
    WidgetRef ref, {
    Adventure? adventureToEdit,
  }) {
    final isEditing = adventureToEdit != null;
    final nameController = TextEditingController(text: adventureToEdit?.name);
    final descController = TextEditingController(
      text: adventureToEdit?.description,
    );
    final whatController = TextEditingController(
      text: adventureToEdit?.conceptWhat,
    );
    final conflictController = TextEditingController(
      text: adventureToEdit?.conceptConflict,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Aventura' : 'Criar Nova Aventura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Aventura',
                  hintText: 'ex: O Templo Submerso',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Breve visão geral...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: whatController,
                decoration: const InputDecoration(
                  labelText: 'Qual é o local?',
                  hintText: 'ex: Um templo submerso sob o lago',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: conflictController,
                decoration: const InputDecoration(
                  labelText: 'Qual conflito está acontecendo?',
                  hintText: 'ex: Duas facções lutam por um artefato antigo',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                if (isEditing) {
                  final updatedAdventure = adventureToEdit.copyWith(
                    name: nameController.text,
                    description: descController.text,
                    conceptWhat: whatController.text,
                    conceptConflict: conflictController.text,
                  );
                  await ref
                      .read(adventureListProvider.notifier)
                      .update(updatedAdventure);
                  if (context.mounted) {
                    Navigator.pop(context);

                    // Mark as dirty
                    ref.read(unsyncedChangesProvider.notifier).state = true;
                  }
                } else {
                  final adventure = await ref
                      .read(adventureListProvider.notifier)
                      .create(
                        name: nameController.text,
                        description: descController.text,
                        conceptWhat: whatController.text,
                        conceptConflict: conflictController.text,
                        // campaignId: selectedCampaignId,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);

                    // Mark as dirty
                    ref.read(unsyncedChangesProvider.notifier).state = true;

                    context.go('/adventure/${adventure.id}');
                  }
                }
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  static void showCampaignDialog(
    BuildContext context,
    WidgetRef ref, {
    Campaign? campaignToEdit,
  }) {
    final isEditing = campaignToEdit != null;
    final nameController = TextEditingController(text: campaignToEdit?.name);
    final descController = TextEditingController(
      text: campaignToEdit?.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Campanha' : 'Criar Nova Campanha'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Campanha',
                  hintText: 'ex: Guerra do Anel',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'A história abrangente...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                if (isEditing) {
                  final updatedCampaign = campaignToEdit.copyWith(
                    name: nameController.text,
                    description: descController.text,
                  );
                  await ref
                      .read(campaignListProvider.notifier)
                      .update(updatedCampaign);
                } else {
                  await ref
                      .read(campaignListProvider.notifier)
                      .create(
                        name: nameController.text,
                        description: descController.text,
                      );
                }

                // Mark as dirty
                ref.read(unsyncedChangesProvider.notifier).state = true;

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to safely read providers after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSync();
    });
  }

  void _checkInitialSync() {
    if (_hasSynced) return;

    final user = ref.read(currentUserProvider);
    if (user != null && !user.isAnonymous) {
      _performSync();
    }
  }

  void _performSync() {
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    ref
        .read(syncServiceProvider)
        .fullSync()
        .then((_) {
          if (mounted) {
            ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
            ref.read(unsyncedChangesProvider.notifier).state = false;
            ref.read(adventureListProvider.notifier).refresh();
            ref.read(campaignListProvider.notifier).refresh();
            setState(() {
              _hasSynced = true;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth changes (e.g. login after logout)
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (previous == null && next != null && !next.isAnonymous) {
        _performSync();
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                ),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo/Title
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo_quest_script.png',
                          height: 120, // Increased from 80
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quest Script',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(color: AppTheme.secondary),
                              ),
                              Text(
                                'Criador de Locais de Aventura',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Account & Sync buttons
                        _AccountMenu(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Aventuras'),
                        Tab(text: 'Campanhas'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [_AdventuresList(), _CampaignsList()],
          ),
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            return FloatingActionButton(
              onPressed: () => _showCreateOptions(context, ref),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Nova Aventura'),
            subtitle: const Text('Criar um local de aventura independente'),
            onTap: () {
              Navigator.pop(context);
              DashboardPage.showAdventureDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Nova Campanha'),
            subtitle: const Text('Criar uma campanha para vincular aventuras'),
            onTap: () {
              Navigator.pop(context);
              DashboardPage.showCampaignDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

class _AdventuresList extends ConsumerWidget {
  const _AdventuresList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventures = ref.watch(adventureListProvider);

    // Sort by updated recently
    final sortedAdventures = List<Adventure>.from(adventures)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (sortedAdventures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 80,
                color: AppTheme.textMuted.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma aventura ainda',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: sortedAdventures.length,
      itemBuilder: (context, index) => _AdventureCard(
        adventure: sortedAdventures[index],
        onEdit: () => DashboardPage.showAdventureDialog(
          context,
          ref,
          adventureToEdit: sortedAdventures[index],
        ),
      ),
    );
  }
}

class _CampaignsList extends ConsumerWidget {
  const _CampaignsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignListProvider);

    if (campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 80,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma campanha ainda',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.bookmark, color: AppTheme.primary),
            title: Text(campaign.name),
            subtitle: Text(
              '${campaign.description}\n${campaign.adventureIds.length} Aventuras',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  DashboardPage.showCampaignDialog(
                    context,
                    ref,
                    campaignToEdit: campaign,
                  );
                } else if (value == 'delete') {
                  await ref
                      .read(campaignListProvider.notifier)
                      .delete(campaign.id);

                  // Auto-sync delete
                  ref.read(syncServiceProvider).deleteCampaign(campaign.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.secondary),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
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
          ),
        );
      },
    );
  }
}

class _AdventureCard extends ConsumerWidget {
  final Adventure adventure;
  final VoidCallback onEdit;

  const _AdventureCard({required this.adventure, required this.onEdit});

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
          color: AppTheme.primaryDark.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/adventure/play/${adventure.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Gradient
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
                      AppTheme.primaryDark.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.map,
                    size: 64,
                    color: AppTheme.primary.withOpacity(0.1),
                  ),
                ),
              ),

            // Dark gradient overlay for text readability (bottom)
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
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

            // Content Overlay
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Icon
                      if (adventure.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.9),
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
                      // Menu
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
                  // Title
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
                  // Description / Concept
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
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('JOGAR'),
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

/// Account menu with sync and logout options
class _AccountMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sync button
        CloudSyncButton(),

        // Account popup menu
        PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
            child: user?.photoURL != null
                ? ClipOval(
                    child: SmartNetworkImage(
                      imageUrl: user?.photoURL ?? '',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      placeholder: const Icon(
                        Icons.person,
                        size: 20,
                        color: AppTheme.secondary,
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 20, color: AppTheme.secondary),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await ref.read(authServiceProvider).signOut();
            } else if (value == 'sync') {
              ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
              try {
                await ref.read(syncServiceProvider).fullSync();
                ref.read(syncStatusProvider.notifier).state =
                    SyncStatus.success;
                ref.read(unsyncedChangesProvider.notifier).state = false;
                ref.read(adventureListProvider.notifier).refresh();
                ref.read(campaignListProvider.notifier).refresh();
              } catch (e) {
                ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Convidado',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (user?.email != null)
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (user?.isAnonymous == true)
                    Text(
                      'Dados salvos apenas localmente',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            if (user != null && !user.isAnonymous)
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Sincronizar'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.error),
                  SizedBox(width: 8),
                  Text('Sair'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
