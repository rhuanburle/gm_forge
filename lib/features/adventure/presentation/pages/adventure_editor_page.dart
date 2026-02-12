import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_button.dart';
import '../../application/adventure_providers.dart';
import 'adventure_editor/tabs/concept_tab.dart';
import 'adventure_editor/tabs/creatures_tab.dart';
import 'adventure_editor/tabs/events_tab.dart';
import 'adventure_editor/tabs/legends_tab.dart';
import 'adventure_editor/tabs/locations_tab.dart';
import 'adventure_editor/tabs/summary_tab.dart';

class AdventureEditorPage extends ConsumerStatefulWidget {
  final String adventureId;

  const AdventureEditorPage({super.key, required this.adventureId});

  @override
  ConsumerState<AdventureEditorPage> createState() =>
      _AdventureEditorPageState();
}

class _AdventureEditorPageState extends ConsumerState<AdventureEditorPage>
    with SingleTickerProviderStateMixin {
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
    final adventure = ref.watch(adventureProvider(widget.adventureId));

    if (adventure == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(child: Text('Aventura não encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 140,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Row(
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
                    adventure.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Editor de Aventura',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CloudSyncButton(),
          IconButton(
            icon: Icon(
              adventure.isComplete
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: adventure.isComplete
                  ? AppTheme.success
                  : AppTheme.textMuted,
            ),
            tooltip: adventure.isComplete
                ? 'Marcar como incompleta'
                : 'Marcar como completa',
            onPressed: () async {
              adventure.isComplete = !adventure.isComplete;
              await ref.read(hiveDatabaseProvider).saveAdventure(adventure);
              ref.read(adventureListProvider.notifier).refresh();
              ref.invalidate(adventureProvider(widget.adventureId));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumo'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Conceito'),
            Tab(icon: Icon(Icons.campaign), text: 'Rumores'),
            Tab(icon: Icon(Icons.map), text: 'Locais'),
            Tab(icon: Icon(Icons.casino), text: 'Eventos'),
            Tab(icon: Icon(Icons.pets), text: 'Criaturas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SummaryTab(
            adventureId: widget.adventureId,
            onTabChange: (index) => _tabController.animateTo(index),
          ),
          ConceptTab(adventure: adventure),
          LegendsTab(adventureId: widget.adventureId),
          LocationsTab(adventureId: widget.adventureId),
          EventsTab(adventureId: widget.adventureId),
          CreaturesTab(adventureId: widget.adventureId),
        ],
      ),
    );
  }
}
