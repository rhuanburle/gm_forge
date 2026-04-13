import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/sync_service.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../../../core/widgets/animated_list_item.dart';
import '../../controllers/dashboard_controller.dart';

class CampaignList extends ConsumerWidget {
  const CampaignList({super.key});

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

    return RefreshIndicator(
      color: AppTheme.secondary,
      onRefresh: () async {
        try {
          await ref.read(syncServiceProvider).fullSync();
          ref.read(unsyncedChangesProvider.notifier).state = false;
          ref.read(adventureListProvider.notifier).refresh();
          ref.read(campaignListProvider.notifier).refresh();
        } catch (_) {}
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return AnimatedListItem(
            index: index,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => context.push('/campaign/${campaign.id}'),
                leading: const Icon(Icons.bookmark, color: AppTheme.primary),
                title: Text(campaign.name),
                subtitle: Text(
                  '${campaign.description}\n${campaign.adventureIds.length} Aventuras',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      DashboardController.showCampaignDialog(
                        context,
                        ref,
                        campaignToEdit: campaign,
                      );
                    } else if (value == 'delete') {
                      await ref
                          .read(campaignListProvider.notifier)
                          .delete(campaign.id);

                      await ref.read(syncServiceProvider).deleteCampaign(campaign.id);
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
            ),
          );
        },
      ),
    );
  }
}
