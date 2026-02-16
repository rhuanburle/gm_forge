import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/auth/auth_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard/account_menu.dart';
import '../widgets/dashboard/adventure_list.dart';
import '../widgets/dashboard/campaign_list.dart';

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
      length: 2,
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
                        Tab(text: 'Aventuras'),
                        Tab(text: 'Campanhas'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(children: [AdventureList(), CampaignList()]),
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
