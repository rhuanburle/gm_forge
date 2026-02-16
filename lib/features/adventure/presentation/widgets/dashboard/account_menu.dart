import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/auth/auth_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/sync_button.dart';
import '../../../../../core/widgets/smart_network_image.dart';
import '../../../../../core/sync/sync_service.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';

class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CloudSyncButton(),

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
