import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_service.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/unsynced_changes_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/adventure/application/adventure_providers.dart';

class CloudSyncButton extends ConsumerWidget {
  const CloudSyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final hasUnsyncedChanges = ref.watch(unsyncedChangesProvider);

    if (user == null || user.isAnonymous) return const SizedBox.shrink();

    return IconButton(
      icon: syncStatus == SyncStatus.syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.secondary,
              ),
            )
          : Icon(
              syncStatus == SyncStatus.success
                  ? (hasUnsyncedChanges ? Icons.cloud_upload : Icons.cloud_done)
                  : syncStatus == SyncStatus.error
                  ? Icons.cloud_off
                  : Icons.cloud_upload,
              color: syncStatus == SyncStatus.error
                  ? AppTheme.error
                  : (hasUnsyncedChanges
                        ? Colors.orange
                        : AppTheme.secondary), // Orange if dirty
            ),
      tooltip: syncStatus == SyncStatus.syncing
          ? 'Sincronizando...'
          : syncStatus == SyncStatus.error
          ? 'Erro na sincronização'
          : (hasUnsyncedChanges
                ? 'Alterações não salvas na nuvem'
                : 'Sincronizado'),
      onPressed: syncStatus == SyncStatus.syncing
          ? null
          : () async {
              ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
              try {
                await ref.read(syncServiceProvider).fullSync();
                ref.read(syncStatusProvider.notifier).state =
                    SyncStatus.success;
                ref.read(unsyncedChangesProvider.notifier).state = false;
                // Refresh relevant providers
                ref.read(adventureListProvider.notifier).refresh();
                ref.read(campaignListProvider.notifier).refresh();
              } catch (e) {
                ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
              }
            },
    );
  }
}
