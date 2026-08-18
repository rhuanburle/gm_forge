import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../core/widgets/sync_button.dart';
import '../../../../core/history/history_service.dart';
import '../../application/adventure_providers.dart';
import 'adventure_editor/tabs/concept_tab.dart';
import 'adventure_editor/tabs/creatures_tab.dart';
import 'adventure_editor/tabs/events_tab.dart';
import 'adventure_editor/tabs/legends_tab.dart';
import 'adventure_editor/tabs/locations_tab.dart';
import 'adventure_editor/tabs/summary_tab.dart';
import 'adventure_editor/tabs/factions_tab.dart';
import 'adventure_editor/tabs/items_tab.dart';
import 'adventure_editor/tabs/quests_tab.dart';
import 'adventure_editor/tabs/structure_tab.dart';
import 'adventure_editor/widgets/editor_group_tab.dart';
import '../widgets/global_search_dialog.dart';

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
    final history = ref.watch(historyProvider);

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
          if (history.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Desfazer',
              onPressed: () => ref.read(historyProvider.notifier).undo(),
            ),
          if (history.canRedo)
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Refazer',
              onPressed: () => ref.read(historyProvider.notifier).redo(),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar na aventura',
            onPressed: () => showDialog(
              context: context,
              builder: (_) =>
                  GlobalSearchDialog(adventureId: widget.adventureId),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Sessões',
            onPressed: () =>
                context.push('/adventure/${widget.adventureId}/sessions'),
          ),
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
              final updatedAdventure = adventure.copyWith(
                isComplete: !adventure.isComplete,
              );
              await ref
                  .read(hiveDatabaseProvider)
                  .saveAdventure(updatedAdventure);
              ref.read(adventureListProvider.notifier).refresh();
              ref.invalidate(adventureProvider(widget.adventureId));
              ref.read(unsyncedChangesProvider.notifier).state = true;
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumo'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Conceito'),
            Tab(icon: Icon(Icons.map), text: 'Locais'),
            Tab(icon: Icon(Icons.groups), text: 'Elenco'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Tesouro & Missões'),
            Tab(icon: Icon(Icons.casino), text: 'Na Mesa'),
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
          LocationsTab(adventureId: widget.adventureId),
          // Elenco: quem povoa a aventura (criaturas/NPCs + facções).
          EditorGroupTab(
            tabs: [
              EditorSubTab(
                label: 'Criaturas & NPCs',
                icon: Icons.pets,
                child: CreaturesTab(adventureId: widget.adventureId),
              ),
              EditorSubTab(
                label: 'Facções',
                icon: Icons.groups,
                child: FactionsTab(adventureId: widget.adventureId),
              ),
            ],
          ),
          // Tesouro & Missões: recompensas e objetivos.
          EditorGroupTab(
            tabs: [
              EditorSubTab(
                label: 'Itens & Tesouros',
                icon: Icons.inventory_2,
                child: ItemsTab(adventureId: widget.adventureId),
              ),
              EditorSubTab(
                label: 'Missões',
                icon: Icons.flag,
                child: QuestsTab(adventureId: widget.adventureId),
              ),
            ],
          ),
          // Na Mesa: tudo que dispara durante o jogo.
          EditorGroupTab(
            tabs: [
              EditorSubTab(
                label: 'Rumores',
                icon: Icons.campaign,
                child: LegendsTab(adventureId: widget.adventureId),
              ),
              EditorSubTab(
                label: 'Eventos',
                icon: Icons.casino,
                child: EventsTab(adventureId: widget.adventureId),
              ),
              EditorSubTab(
                label: 'Timers & Handouts',
                icon: Icons.timer,
                child: StructureTab(adventureId: widget.adventureId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
