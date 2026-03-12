import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard/account_menu.dart';
import '../widgets/dashboard/adventure_list.dart';
import '../widgets/dashboard/campaign_list.dart';
import '../widgets/dashboard/campaign_overview_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
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
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (previous == null && next != null && !next.isAnonymous) {
        _performSync();
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                ),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modo Protótipo',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppTheme.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.warning),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'Este aplicativo é um protótipo. Lembre-se de salvar suas alterações manualmente clicando no ícone de nuvem ',
                                      ),
                                      const WidgetSpan(
                                        child: Icon(
                                          Icons.cloud_upload,
                                          size: 18,
                                          color: AppTheme.warning,
                                        ),
                                      ),
                                      const TextSpan(
                                        text:
                                            ' no canto superior direito. O salvamento automático não está ativo.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo_quest_script.png',
                          height: 120,
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
                        const AccountMenu(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Visao Geral'),
                        Tab(text: 'Aventuras'),
                        Tab(text: 'Campanhas'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(children: [_OverviewTab(), AdventureList(), CampaignList()]),
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            return FloatingActionButton(
              onPressed: () =>
                  DashboardController.showCreateOptions(context, ref),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignListProvider);
    final adventures = ref.watch(adventureListProvider);

    // Recent activity: last 5 modified adventures sorted by updatedAt
    final recentAdventures = List<Adventure>.from(adventures)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final last5 = recentAdventures.take(5).toList();

    return RefreshIndicator(
      color: AppTheme.secondary,
      onRefresh: () => _onRefresh(ref),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick stats row
          Row(
            children: [
              _StatCard(
                icon: Icons.bookmark,
                label: 'Campanhas',
                value: '${campaigns.length}',
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.explore,
                label: 'Aventuras',
                value: '${adventures.length}',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Campaign overview cards
          if (campaigns.isNotEmpty) ...[
            Text(
              'Campanhas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ...campaigns.map((campaign) {
              final campaignAdventures = adventures
                  .where((a) => campaign.adventureIds.contains(a.id))
                  .toList();
              final pcs = ref.watch(playerCharactersProvider(campaign.id));
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CampaignOverviewCard(
                  campaign: campaign,
                  playerCharacters: pcs,
                  adventureCount: campaignAdventures.length,
                  onTap: () => context.push('/campaign/${campaign.id}'),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Recent activity
          if (last5.isNotEmpty) ...[
            Text(
              'Atividade Recente',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ...last5.map((adventure) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: AppTheme.secondary),
                    title: Text(adventure.name),
                    subtitle: Text(
                      'Atualizada em ${_formatDate(adventure.updatedAt)}',
                    ),
                    onTap: () => context.push('/adventure/${adventure.id}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    try {
      await ref.read(syncServiceProvider).fullSync();
      ref.read(unsyncedChangesProvider.notifier).state = false;
      ref.read(adventureListProvider.notifier).refresh();
      ref.read(campaignListProvider.notifier).refresh();
    } catch (_) {}
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
