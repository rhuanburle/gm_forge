import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_button.dart';
import '../../../public/presentation/widgets/publish_campaign_dialog.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';
import 'campaign_hub/overview_tab.dart';
import 'campaign_hub/characters_tab.dart';
import 'campaign_hub/world_tab.dart';
import 'campaign_hub/notes_tab.dart';
import 'campaign_hub/plot_threads_tab.dart';
import 'campaign_hub/timeline_tab.dart';

class CampaignHubPage extends ConsumerStatefulWidget {
  final String campaignId;

  const CampaignHubPage({super.key, required this.campaignId});

  @override
  ConsumerState<CampaignHubPage> createState() => _CampaignHubPageState();
}

class _CampaignHubPageState extends ConsumerState<CampaignHubPage>
    with SingleTickerProviderStateMixin {
  String get campaignId => widget.campaignId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = ref.watch(campaignProvider(campaignId));

    if (campaign == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(child: Text('Campanha nao encontrada.')),
      );
    }

    final adventures = campaign.adventureIds
        .map((id) => ref.watch(adventureProvider(id)))
        .whereType<Adventure>()
        .toList();
    final pcs = ref.watch(playerCharactersProvider(campaignId));
    final factions = ref.watch(campaignFactionsProvider(campaignId));
    final loreEntries = ref.watch(loreEntriesProvider(campaignId));
    final regions = ref.watch(regionsProvider(campaignId));
    final notes = ref.watch(notesProvider(campaignId));
    final quickRules = ref.watch(quickRulesProvider(campaignId));
    final plotThreads = campaign.plotThreads;
    final timelineEntries = ref.watch(timelineEntriesProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(campaign.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar com Jogadores',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => PublishCampaignDialog(campaignId: campaignId),
              );
            },
          ),
          const CloudSyncButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.secondary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.secondary,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Geral'),
                  const SizedBox(width: 4),
                  _badge(adventures.length),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.people, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Personagens'),
                  const SizedBox(width: 4),
                  _badge(pcs.length + factions.length),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.public, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mundo'),
                  const SizedBox(width: 4),
                  _badge(loreEntries.length + regions.length),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enredo'),
                  const SizedBox(width: 4),
                  _badge(plotThreads.where((t) => t.status == PlotThreadStatus.active).length),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.timeline, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Linha do Tempo'),
                  const SizedBox(width: 4),
                  _badge(timelineEntries.length),
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.note_alt, size: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notas'),
                  const SizedBox(width: 4),
                  _badge(notes.length + quickRules.length),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(campaignId: campaignId),
          CharactersTab(campaignId: campaignId),
          WorldTab(campaignId: campaignId),
          PlotThreadsTab(campaignId: campaignId),
          TimelineTab(campaignId: campaignId),
          NotesTab(campaignId: campaignId),
        ],
      ),
    );
  }

  Widget _badge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
