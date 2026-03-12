import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/sync_service.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/adventure.dart';
import '../../controllers/dashboard_controller.dart';
import '../../../../../core/widgets/animated_list_item.dart';
import 'adventure_card.dart';

class AdventureList extends ConsumerWidget {
  const AdventureList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventures = ref.watch(adventureListProvider);

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
                color: AppTheme.textMuted.withValues(alpha: 0.3),
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
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: sortedAdventures.length,
        itemBuilder: (context, index) => AnimatedListItem(
          index: index,
          child: AdventureCard(
            adventure: sortedAdventures[index],
            onEdit: () => DashboardController.showAdventureDialog(
              context,
              ref,
              adventureToEdit: sortedAdventures[index],
            ),
          ),
        ),
      ),
    );
  }
}
