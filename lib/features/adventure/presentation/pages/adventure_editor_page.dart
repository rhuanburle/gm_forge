import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sync_button.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';
import '../../../../core/utils/debouncer.dart';
import '../../presentation/widgets/smart_text_field.dart';
import '../../presentation/widgets/smart_text_renderer.dart';

/// Adventure Editor - Full adventure editing page with all sections
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
        toolbarHeight: 140, // Increased for even larger logo
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_quest_script.png',
              height: 120, // Increased from 100
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
          _SummaryTab(
            adventureId: widget.adventureId,
            onTabChange: (index) => _tabController.animateTo(index),
          ),
          _ConceptTab(adventure: adventure),
          _LegendsTab(adventureId: widget.adventureId),
          _LocationsTab(adventureId: widget.adventureId),
          _EventsTab(adventureId: widget.adventureId),
          _CreaturesTab(adventureId: widget.adventureId),
        ],
      ),
    );
  }
}

// === Concept Tab ===

class _ConceptTab extends ConsumerStatefulWidget {
  final Adventure adventure;

  const _ConceptTab({required this.adventure});

  @override
  ConsumerState<_ConceptTab> createState() => _ConceptTabState();
}

class _ConceptTabState extends ConsumerState<_ConceptTab> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _whatController;
  late TextEditingController _conflictController;
  late TextEditingController _nextHintController;
  late TextEditingController _tagsController;
  late TextEditingController _dungeonMapController;
  String? _selectedCampaignId;

  final _debouncer = Debouncer(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adventure.name);
    _descController = TextEditingController(text: widget.adventure.description);
    _whatController = TextEditingController(text: widget.adventure.conceptWhat);
    _conflictController = TextEditingController(
      text: widget.adventure.conceptConflict,
    );
    _nextHintController = TextEditingController(
      text: widget.adventure.nextAdventureHint,
    );
    _tagsController = TextEditingController(
      text: widget.adventure.tags.join(', '),
    );
    _dungeonMapController = TextEditingController(
      text: widget.adventure.dungeonMapPath,
    );
    _selectedCampaignId = widget.adventure.campaignId;

    // Attach listeners for auto-save
    _nameController.addListener(_onFieldChanged);
    _descController.addListener(_onFieldChanged);
    _whatController.addListener(_onFieldChanged);
    _conflictController.addListener(_onFieldChanged);
    _nextHintController.addListener(_onFieldChanged);
    _tagsController.addListener(_onFieldChanged);
    _dungeonMapController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _nameController.dispose();
    _descController.dispose();
    _whatController.dispose();
    _conflictController.dispose();
    _nextHintController.dispose();
    _tagsController.dispose();
    _dungeonMapController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debouncer.run(() => _save(silent: true));
  }

  Future<void> _save({bool silent = false}) async {
    widget.adventure.name = _nameController.text;
    widget.adventure.description = _descController.text;
    widget.adventure.conceptWhat = _whatController.text;
    widget.adventure.conceptConflict = _conflictController.text;
    widget.adventure.nextAdventureHint = _nextHintController.text;
    widget.adventure.dungeonMapPath = _dungeonMapController.text.isEmpty
        ? null
        : _dungeonMapController.text;
    widget.adventure.campaignId = _selectedCampaignId;

    // Parse tags
    widget.adventure.tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await ref.read(hiveDatabaseProvider).saveAdventure(widget.adventure);
    ref.read(adventureListProvider.notifier).refresh();

    // Auto-sync after save if logged in
    // Mark as dirty
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null && !user.isAnonymous) {
      ref.read(unsyncedChangesProvider.notifier).state = true;
    }

    if (mounted && !silent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Salvo!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Seed Section
          _SectionHeader(
            icon: Icons.lightbulb,
            title: 'A Semente (Conceito Central)',
            subtitle: 'Defina o coração do seu Local de Aventura',
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Aventura',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              prefixIcon: Icon(Icons.description),
              hintText: 'Uma breve visão geral para sua referência...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Campaign Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedCampaignId,
            decoration: const InputDecoration(
              labelText: 'Campanha',
              prefixIcon: Icon(Icons.bookmark),
              hintText: 'Vincular a uma campanha (opcional)',
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Nenhuma (Independente)'),
              ),
              ...campaigns.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCampaignId = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Tags
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              prefixIcon: Icon(Icons.label),
              hintText: 'tags, separadas, por, vírgula',
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qual é o local?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'ex: Um templo submerso, uma estação espacial abandonada, uma mansão assombrada',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: _whatController,
                  adventureId: widget.adventure.id,
                  label: 'Descrição do Local',
                  hint: 'Descreva o local...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qual conflito está acontecendo lá agora?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  "ex: Duas facções lutam por um artefato, uma maldição desperta, a natureza retoma as ruínas",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: _conflictController,
                  adventureId: widget.adventure.id,
                  label: 'Conflito',
                  hint: 'Descreva o conflito...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Next Adventure Hint
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gancho Narrativo (A "Ponta Solta")',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  "Uma dica ou pista apontando para a próxima aventura na campanha.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: _nextHintController,
                  adventureId: widget.adventure.id,
                  label: 'Gancho Narrativo',
                  hint:
                      'ex: Um mapa encontrado no corpo do capitão aponta para...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dungeon Map Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapa da Masmorra',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Imagem do mapa completo (onde cada Local individual é uma sala).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dungeonMapController,
                  decoration: const InputDecoration(
                    labelText: 'URL ou Caminho da Imagem',
                    hintText: 'https://exemplo.com/mapa-masmorra.png',
                    prefixIcon: Icon(Icons.map),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_dungeonMapController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartNetworkImage(
                      imageUrl: _dungeonMapController.text,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Conceito'),
            ),
          ),
        ],
      ),
    );
  }
}

// === Legends Tab ===

class _LegendsTab extends ConsumerWidget {
  final String adventureId;

  const _LegendsTab({required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legends = ref.watch(legendsProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.campaign,
            title: 'Tabela de Rumores (2d6)',
            subtitle:
                '70% de dicas verdadeiras, 30% de rumores falsos/exagerados',
          ),
          const SizedBox(height: 16),

          // Dice roll guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Resultados 2d6: 2-3 (raro), 4-5 (incomum), 6-8 (comum), 9-10 (incomum), 11-12 (raro)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.casino),
                    label: const Text('Rolar Rumor (2d6)'),
                    onPressed: () {
                      final result =
                          Random().nextInt(6) + 1 + Random().nextInt(6) + 1;
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.casino, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Resultado do Dado'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$result',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                () {
                                  if (result <= 3 || result >= 11) {
                                    return 'Raro!';
                                  } else if (result >= 6 && result <= 8) {
                                    return 'Comum';
                                  } else {
                                    return 'Incomum';
                                  }
                                }(),
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fechar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: legends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum rumor ainda. Adicione rumores que os jogadores possam ouvir.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: legends.length,
                    itemBuilder: (context, index) {
                      final legend = legends[index];
                      return _LegendCard(
                        legend: legend,
                        adventureId: adventureId,
                        onEdit: () => _showLegendDialog(
                          context,
                          ref,
                          legendToEdit: legend,
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showLegendDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Rumor'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegendDialog(
    BuildContext context,
    WidgetRef ref, {
    Legend? legendToEdit,
  }) {
    final isEditing = legendToEdit != null;
    final textController = TextEditingController(text: legendToEdit?.text);
    final sourceController = TextEditingController(text: legendToEdit?.source);
    final diceController = TextEditingController(
      text: legendToEdit?.diceResult,
    );
    bool isTrue = legendToEdit?.isTrue ?? true;
    String? selectedCreatureId = legendToEdit?.relatedCreatureId;
    final creatures = ref.read(creaturesProvider(adventureId));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Rumor' : 'Adicionar Rumor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: diceController,
                  decoration: const InputDecoration(
                    labelText: 'Resultado 2d6',
                    hintText: 'ex: 7 ou 6-8',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selectedCreatureId,
                  decoration: const InputDecoration(
                    labelText: 'Relacionado a (Opcional)',
                    hintText: 'Selecione uma criatura/NPC...',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Ninguém específico'),
                    ),
                    ...creatures.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedCreatureId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: legendToEdit?.relatedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Relacionado a Local (Opcional)',
                    hintText: 'Selecione um local...',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nenhum local específico'),
                    ),
                    ...ref
                        .read(pointsOfInterestProvider(adventureId))
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('#${p.number} ${p.name}'),
                          ),
                        ),
                  ],
                  onChanged: (v) =>
                      setState(() => legendToEdit?.relatedLocationId = v),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: textController,
                  adventureId: adventureId,
                  label: 'Texto do Rumor',
                  hint: "O que os jogadores ouvirão...",
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Fonte (opcional)',
                    hintText: 'ex: Velho taverneiro, mapa empoeirado',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(isTrue ? 'Rumor Verdadeiro' : 'Falso/Exagerado'),
                  subtitle: Text(
                    isTrue
                        ? 'Dica real sobre perigos ou tesouros'
                        : 'Cria tensão e surpresa',
                  ),
                  value: isTrue,
                  onChanged: (value) => setState(() => isTrue = value),
                  activeThumbColor: AppTheme.success,
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
                if (textController.text.isNotEmpty &&
                    diceController.text.isNotEmpty) {
                  if (isEditing) {
                    final updatedLegend = legendToEdit.copyWith(
                      text: textController.text,
                      isTrue: isTrue,
                      source: sourceController.text.isEmpty
                          ? null
                          : sourceController.text,
                      diceResult: diceController.text,
                      relatedCreatureId: selectedCreatureId,
                    );
                    await ref
                        .read(hiveDatabaseProvider)
                        .saveLegend(updatedLegend);
                  } else {
                    final legend = Legend(
                      adventureId: adventureId,
                      text: textController.text,
                      isTrue: isTrue,
                      source: sourceController.text.isEmpty
                          ? null
                          : sourceController.text,
                      diceResult: diceController.text,
                      relatedCreatureId: selectedCreatureId,
                    );
                    await ref.read(hiveDatabaseProvider).saveLegend(legend);
                  }
                  ref.invalidate(legendsProvider(adventureId));

                  // Mark as dirty
                  ref.read(unsyncedChangesProvider.notifier).state = true;

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendCard extends ConsumerWidget {
  final Legend legend;
  final String adventureId;
  final VoidCallback onEdit;

  const _LegendCard({
    required this.legend,
    required this.adventureId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: legend.isTrue
              ? AppTheme.success.withValues(alpha: 0.2)
              : AppTheme.error.withValues(alpha: 0.2),
          child: Text(
            legend.diceResult,
            style: TextStyle(
              color: legend.isTrue ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: SmartTextRenderer(
          text: legend.text,
          adventureId: adventureId,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: legend.source != null
            ? Text('Fonte: ${legend.source}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(legend.isTrue ? 'Verdade' : 'Falso'),
              backgroundColor: legend.isTrue
                  ? AppTheme.success.withValues(alpha: 0.2)
                  : AppTheme.error.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: legend.isTrue ? AppTheme.success : AppTheme.error,
                fontSize: 12,
              ),
            ),
            if (legend.relatedCreatureId != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Relacionado a uma criatura/NPC',
                child: Icon(
                  Icons.link,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Editar Rumor',
              constraints: const BoxConstraints(),
              color: AppTheme.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                await ref.read(hiveDatabaseProvider).deleteLegend(legend.id);
                ref.invalidate(legendsProvider(adventureId));

                // Mark as dirty
                ref.read(unsyncedChangesProvider.notifier).state = true;
              },
              constraints: const BoxConstraints(),
              color: AppTheme.error.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// === Locations Tab ===

class _LocationsTab extends ConsumerWidget {
  final String adventureId;

  const _LocationsTab({required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsProvider(adventureId));
    final pois = ref.watch(pointsOfInterestProvider(adventureId));

    // Group POIs by locationId
    final poisByLocation = <String, List<PointOfInterest>>{};
    final orphanedPois = <PointOfInterest>[];

    for (final poi in pois) {
      if (poi.locationId != null &&
          locations.any((l) => l.id == poi.locationId)) {
        poisByLocation.putIfAbsent(poi.locationId!, () => []).add(poi);
      } else {
        orphanedPois.add(poi);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.map,
            title: 'Zonas e Locais',
            subtitle: 'Organize sua aventura em áreas e pontos de interesse.',
          ),
          const SizedBox(height: 16),

          // Purpose guide
          Wrap(
            spacing: 8,
            children: RoomPurpose.values
                .map(
                  (p) => Chip(
                    avatar: Icon(_purposeIcon(p), size: 16),
                    label: Text(p.displayName),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          if (locations.isEmpty && orphanedPois.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nenhuma zona ou local criado ainda.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showZoneDialog(context, ref),
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Criar Primeira Zona'),
                  ),
                ],
              ),
            )
          else ...[
            // List Zones
            ...locations.map((location) {
              return _ZoneCard(
                location: location,
                pois: poisByLocation[location.id] ?? [],
                adventureId: adventureId,
                onEditZone: () =>
                    _showZoneDialog(context, ref, locationToEdit: location),
                onAddPoi: () => _showPoiDialog(
                  context,
                  ref,
                  preselectedLocationId: location.id,
                ),
                onEditPoi: (poi) =>
                    _showPoiDialog(context, ref, poiToEdit: poi),
              );
            }),

            // List Orphaned POIs
            if (orphanedPois.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Locais Sem Zona',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              ...orphanedPois.map(
                (poi) => _PoiCard(
                  poi: poi,
                  adventureId: adventureId,
                  onEdit: () => _showPoiDialog(context, ref, poiToEdit: poi),
                ),
              ),
            ],
          ],

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showZoneDialog(context, ref),
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Nova Zona'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showPoiDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Novo Local'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _purposeIcon(RoomPurpose purpose) {
    return switch (purpose) {
      RoomPurpose.rest => Icons.bed,
      RoomPurpose.danger => Icons.warning,
      RoomPurpose.puzzle => Icons.psychology,
      RoomPurpose.narrative => Icons.menu_book,
    };
  }

  void _showZoneDialog(
    BuildContext context,
    WidgetRef ref, {
    Location? locationToEdit,
  }) {
    final isEditing = locationToEdit != null;
    final nameController = TextEditingController(text: locationToEdit?.name);
    final descController = TextEditingController(
      text: locationToEdit?.description,
    );
    final imageController = TextEditingController(
      text: locationToEdit?.imagePath,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Zona' : 'Nova Zona'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Zona',
                  hintText: 'ex: Primeiro Andar, Vila, Floresta',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Breve descrição do ambiente geral...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'Imagem de Fundo (URL)',
                  prefixIcon: Icon(Icons.image),
                ),
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
                  final updatedLocation = locationToEdit.copyWith(
                    name: nameController.text,
                    description: descController.text,
                    imagePath: imageController.text.isEmpty
                        ? null
                        : imageController.text,
                  );
                  await ref
                      .read(hiveDatabaseProvider)
                      .saveLocation(updatedLocation);
                } else {
                  final location = Location(
                    adventureId: adventureId,
                    name: nameController.text,
                    description: descController.text,
                    imagePath: imageController.text.isEmpty
                        ? null
                        : imageController.text,
                  );
                  await ref.read(hiveDatabaseProvider).saveLocation(location);
                }
                ref.invalidate(locationsProvider(adventureId));
                ref.read(unsyncedChangesProvider.notifier).state = true;
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  void _showPoiDialog(
    BuildContext context,
    WidgetRef ref, {
    PointOfInterest? poiToEdit,
    String? preselectedLocationId,
  }) {
    final isEditing = poiToEdit != null;
    final nameController = TextEditingController(text: poiToEdit?.name);
    final impressionController = TextEditingController(
      text: poiToEdit?.firstImpression,
    );
    final obviousController = TextEditingController(text: poiToEdit?.obvious);
    final detailController = TextEditingController(text: poiToEdit?.detail);
    final treasureController = TextEditingController(text: poiToEdit?.treasure);
    final imagePathController = TextEditingController(
      text: poiToEdit?.imagePath,
    );

    // Calculate next number
    int nextNumber = poiToEdit?.number ?? 1;
    final allPois = ref.read(pointsOfInterestProvider(adventureId));

    if (!isEditing && allPois.isNotEmpty) {
      nextNumber =
          allPois.map((p) => p.number).reduce((a, b) => a > b ? a : b) + 1;
    }

    RoomPurpose selectedPurpose = poiToEdit?.purpose ?? RoomPurpose.narrative;
    final Set<int> selectedConnections = poiToEdit?.connections.toSet() ?? {};
    final Set<String> selectedCreatureIds =
        poiToEdit?.creatureIds.toSet() ?? {};
    String? selectedLocationId = poiToEdit?.locationId ?? preselectedLocationId;

    final creatures = ref.read(creaturesProvider(adventureId));
    final locations = ref.read(locationsProvider(adventureId));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing
                ? 'Editar Local #$nextNumber'
                : 'Adicionar Local #$nextNumber',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String?>(
                  value: selectedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Zona / Área',
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sem Zona (Raiz)'),
                    ),
                    ...locations.map(
                      (l) => DropdownMenuItem(value: l.id, child: Text(l.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedLocationId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Local',
                    hintText: 'ex: Antecâmara Inundada',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoomPurpose>(
                  initialValue: selectedPurpose,
                  decoration: const InputDecoration(labelText: 'Propósito'),
                  items: RoomPurpose.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedPurpose = v!),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: impressionController,
                  adventureId: adventureId,
                  label: 'Primeira Impressão',
                  hint: 'O ar está úmido e cheira a enxofre...',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: obviousController,
                  adventureId: adventureId,
                  label: 'O Óbvio',
                  hint: 'Um enorme altar de pedra domina o centro...',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: detailController,
                  adventureId: adventureId,
                  label: 'O Detalhe',
                  hint: 'Atrás do altar, uma alavanca escondida...',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: treasureController,
                  adventureId: adventureId,
                  label: 'Tesouro/Itens',
                  hint: 'Baú com 50po, Espada Mágica...',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Imagem (URL)',
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Conexões', style: Theme.of(context).textTheme.titleSmall),
                // [Omitted for brevity - same logic as before, just kept filtering]
                // For simplicity in this replacement, I'll re-implement the connection chips
                if (allPois.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allPois.where((p) => p.number != nextNumber).map((
                      p,
                    ) {
                      final isSelected = selectedConnections.contains(p.number);
                      return FilterChip(
                        label: Text('#${p.number}'),
                        tooltip: p.name,
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedConnections.add(p.number);
                            } else {
                              selectedConnections.remove(p.number);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Creature Linking
                Text(
                  'Criaturas/NPCs Presentes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (creatures.isEmpty)
                  const Text(
                    'Nenhuma criatura disponível.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: creatures.map((c) {
                      final isSelected = selectedCreatureIds.contains(c.id);
                      return FilterChip(
                        label: Text(c.name),
                        avatar: CircleAvatar(
                          backgroundColor: c.type == CreatureType.npc
                              ? Colors.purple.withValues(alpha: 0.2)
                              : AppTheme.accent.withValues(alpha: 0.2),
                          child: Icon(
                            c.type == CreatureType.npc
                                ? Icons.person
                                : Icons.pets,
                            size: 12,
                            color: c.type == CreatureType.npc
                                ? Colors.purple
                                : AppTheme.accent,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedCreatureIds.add(c.id);
                            } else {
                              selectedCreatureIds.remove(c.id);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                  final poi = isEditing
                      ? poiToEdit.copyWith(
                          name: nameController.text,
                          locationId: selectedLocationId,
                          purpose: selectedPurpose,
                          firstImpression: impressionController.text,
                          obvious: obviousController.text,
                          detail: detailController.text,
                          treasure: treasureController.text,
                          connections: selectedConnections.toList()..sort(),
                          creatureIds: selectedCreatureIds.toList(),
                          imagePath: imagePathController.text.isEmpty
                              ? null
                              : imagePathController.text,
                        )
                      : PointOfInterest(
                          adventureId: adventureId,
                          number: nextNumber,
                          name: nameController.text,
                          locationId: selectedLocationId,
                          purpose: selectedPurpose,
                          firstImpression: impressionController.text,
                          obvious: obviousController.text,
                          detail: detailController.text,
                          treasure: treasureController.text,
                          connections: selectedConnections.toList()..sort(),
                          creatureIds: selectedCreatureIds.toList(),
                          imagePath: imagePathController.text.isEmpty
                              ? null
                              : imagePathController.text,
                        );

                  await ref.read(hiveDatabaseProvider).savePointOfInterest(poi);
                  ref.invalidate(pointsOfInterestProvider(adventureId));
                  ref.read(unsyncedChangesProvider.notifier).state = true;
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Location location;
  final List<PointOfInterest> pois;
  final String adventureId;
  final VoidCallback onEditZone;
  final VoidCallback onAddPoi;
  final Function(PointOfInterest) onEditPoi;

  const _ZoneCard({
    required this.location,
    required this.pois,
    required this.adventureId,
    required this.onEditZone,
    required this.onAddPoi,
    required this.onEditPoi,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      child: Column(
        children: [
          // Zone Header
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              location.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: location.description.isNotEmpty
                ? Text(location.description)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEditZone,
                  tooltip: 'Editar Zona',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                  ), // Add delete functionality later
                  onPressed: null, // Disabled for safety for now
                ),
              ],
            ),
            leading: const Icon(Icons.map, size: 32),
          ),

          if (location.imagePath != null)
            SizedBox(
              height: 120,
              width: double.infinity,
              child: SmartNetworkImage(
                imageUrl: location.imagePath!,
                fit: BoxFit.cover,
              ),
            ),

          const Divider(height: 1),

          // POIs List
          if (pois.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Esta zona está vazia.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onAddPoi,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Local Aqui'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pois.length + 1, // +1 for Add Button
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == pois.length) {
                  return TextButton.icon(
                    onPressed: onAddPoi,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Local nesta Zona'),
                  );
                }
                final poi = pois[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${poi.number}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(poi.name),
                  subtitle: Text(poi.purpose.displayName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onEditPoi(poi),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PoiCard extends ConsumerWidget {
  final PointOfInterest poi;
  final String adventureId;
  final VoidCallback onEdit;

  const _PoiCard({
    required this.poi,
    required this.adventureId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          child: Text('${poi.number}'),
        ),
        title: Text(poi.name),
        subtitle: Text(poi.purpose.displayName),
        trailing: const Icon(Icons.edit),
        onTap: onEdit,
      ),
    );
  }
}

class _DescriptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final String? adventureId; // Added to support smart links

  const _DescriptionRow({
    required this.icon,
    required this.label,
    required this.text,
    this.adventureId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (text.isEmpty)
                const Text('(não definido)')
              else if (adventureId != null)
                SmartTextRenderer(text: text, adventureId: adventureId!)
              else
                Text(text),
            ],
          ),
        ),
      ],
    );
  }
}

// === Events Tab ===

class _EventsTab extends ConsumerWidget {
  final String adventureId;

  const _EventsTab({required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(randomEventsProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.casino,
            title: 'Eventos Aleatórios (1d6)',
            subtitle: 'Role a cada X turnos para manter o local vivo',
          ),
          const SizedBox(height: 16),

          // Default table guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribuição sugerida:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text('1: Patrulha • 2: Ambiente • 3: Som • 4-6: Calma'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.casino_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum evento ainda. O local parece estático!',
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: events
                        .map(
                          (e) => _EventCard(
                            event: e,
                            adventureId: adventureId,
                            onEdit: () =>
                                _showEventDialog(context, ref, eventToEdit: e),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showEventDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Evento'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDialog(
    BuildContext context,
    WidgetRef ref, {
    RandomEvent? eventToEdit,
  }) {
    final isEditing = eventToEdit != null;
    final diceController = TextEditingController(text: eventToEdit?.diceRange);
    final descController = TextEditingController(
      text: eventToEdit?.description,
    );
    final impactController = TextEditingController(text: eventToEdit?.impact);
    EventType selectedType = eventToEdit?.eventType ?? EventType.calm;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing
                ? 'Editar Evento Aleatório'
                : 'Adicionar Evento Aleatório',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: diceController,
                  decoration: const InputDecoration(
                    labelText: 'Faixa 1d6',
                    hintText: 'ex: 1, 2, 4-6',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EventType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Evento',
                  ),
                  items: EventType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: descController,
                  adventureId: adventureId,
                  label: 'Descrição',
                  hint: 'O que acontece?',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: impactController,
                  adventureId: adventureId,
                  label: 'Impacto',
                  hint: 'Consequências mecânicas ou narrativas',
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
                if (diceController.text.isNotEmpty) {
                  if (isEditing) {
                    final updatedEvent = eventToEdit.copyWith(
                      diceRange: diceController.text,
                      eventType: selectedType,
                      description: descController.text,
                      impact: impactController.text,
                    );
                    await ref
                        .read(hiveDatabaseProvider)
                        .saveRandomEvent(updatedEvent);
                  } else {
                    final event = RandomEvent(
                      adventureId: adventureId,
                      diceRange: diceController.text,
                      eventType: selectedType,
                      description: descController.text,
                      impact: impactController.text,
                    );
                    await ref.read(hiveDatabaseProvider).saveRandomEvent(event);
                  }
                  ref.invalidate(randomEventsProvider(adventureId));

                  // Mark as dirty
                  ref.read(unsyncedChangesProvider.notifier).state = true;

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final RandomEvent event;
  final String adventureId;
  final VoidCallback onEdit;

  const _EventCard({
    required this.event,
    required this.adventureId,
    required this.onEdit,
  });

  Color _typeColor(EventType type) {
    return switch (type) {
      EventType.patrol => AppTheme.error,
      EventType.environment => AppTheme.warning,
      EventType.sound => AppTheme.info,
      EventType.calm => AppTheme.success,
    };
  }

  IconData _typeIcon(EventType type) {
    return switch (type) {
      EventType.patrol => Icons.directions_walk,
      EventType.environment => Icons.warning_amber,
      EventType.sound => Icons.volume_up,
      EventType.calm => Icons.self_improvement,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _typeColor(event.eventType).withValues(alpha: 0.2),
          child: Text(
            event.diceRange,
            style: TextStyle(
              color: _typeColor(event.eventType),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(
              _typeIcon(event.eventType),
              size: 16,
              color: _typeColor(event.eventType),
            ),
            const SizedBox(width: 8),
            Text(event.eventType.displayName),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref
                    .read(hiveDatabaseProvider)
                    .deleteRandomEvent(event.id);
                ref.invalidate(randomEventsProvider(adventureId));

                // Mark as dirty
                ref.read(unsyncedChangesProvider.notifier).state = true;
              },
            ),
          ],
        ),
        isThreeLine: event.impact.isNotEmpty,
      ),
    );
  }
}

// === Creatures Tab ===

class _CreaturesTab extends ConsumerWidget {
  final String adventureId;

  const _CreaturesTab({required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatures = ref.watch(creaturesProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.pets,
            title: 'Criaturas e NPCs',
            subtitle: 'Defina motivações e comportamentos reativos',
          ),
          const SizedBox(height: 16),

          Expanded(
            child: creatures.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma criatura ainda. Quem habita este local?',
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: creatures
                        .map(
                          (c) => _CreatureCard(
                            creature: c,
                            adventureId: adventureId,
                            onEdit: () => _showCreatureDialog(
                              context,
                              ref,
                              creatureToEdit: c,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showCreatureDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Criatura/NPC'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatureDialog(
    BuildContext context,
    WidgetRef ref, {
    Creature? creatureToEdit,
  }) {
    final isEditing = creatureToEdit != null;
    CreatureType selectedType = creatureToEdit?.type ?? CreatureType.monster;
    final nameController = TextEditingController(text: creatureToEdit?.name);
    final descController = TextEditingController(
      text: creatureToEdit?.description,
    );
    final motivationController = TextEditingController(
      text: creatureToEdit?.motivation,
    );
    final behaviorController = TextEditingController(
      text: creatureToEdit?.losingBehavior,
    );
    final locationController = TextEditingController(
      text: creatureToEdit?.location,
    );
    final statsController = TextEditingController(text: creatureToEdit?.stats);
    final imagePathController = TextEditingController(
      text: creatureToEdit?.imagePath,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? 'Editar Criatura/NPC' : 'Adicionar Criatura/NPC',
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CreatureType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: CreatureType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'ex: Rei Goblin',
                  ),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: descController,
                  adventureId: adventureId,
                  label: 'Descrição',
                  hint: 'Aparência e comportamento...',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: motivationController,
                  adventureId: adventureId,
                  label: 'O que eles querem?',
                  hint: 'Motivação principal...',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: behaviorController,
                  decoration: const InputDecoration(
                    labelText: 'O que eles fazem se estiverem perdendo?',
                    hintText: 'Fugir, negociar, chamar reforços...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Localização (opcional)',
                    hintText: 'Onde eles podem ser encontrados?',
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                TextField(
                  controller: statsController,
                  decoration: const InputDecoration(
                    labelText: 'Ficha/Estatísticas (qualquer sistema)',
                    hintText: 'PV: 10, CA: 12, Ataque: +3 Espada (1d6+2)...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Imagem (URL ou caminho)',
                    hintText: 'https://exemplo.com/imagem.png',
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
              ],
            ),
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
                  final updatedCreature = creatureToEdit.copyWith(
                    name: nameController.text,
                    type: selectedType,
                    description: descController.text,
                    motivation: motivationController.text,
                    losingBehavior: behaviorController.text,
                    location: locationController.text.isEmpty
                        ? null
                        : locationController.text,
                    stats: statsController.text,
                    imagePath: imagePathController.text.isEmpty
                        ? null
                        : imagePathController.text,
                  );
                  await ref
                      .read(hiveDatabaseProvider)
                      .saveCreature(updatedCreature);
                } else {
                  final creature = Creature(
                    adventureId: adventureId,
                    name: nameController.text,
                    type: selectedType,
                    description: descController.text,
                    motivation: motivationController.text,
                    losingBehavior: behaviorController.text,
                    location: locationController.text.isEmpty
                        ? null
                        : locationController.text,
                    stats: statsController.text,
                    imagePath: imagePathController.text.isEmpty
                        ? null
                        : imagePathController.text,
                  );
                  await ref.read(hiveDatabaseProvider).saveCreature(creature);
                }
                ref.invalidate(creaturesProvider(adventureId));

                // Mark as dirty
                ref.read(unsyncedChangesProvider.notifier).state = true;

                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Adicionar'),
          ),
        ],
      ),
    );
  }
}

class _CreatureCard extends ConsumerWidget {
  final Creature creature;
  final String adventureId;
  final VoidCallback onEdit;

  const _CreatureCard({
    required this.creature,
    required this.adventureId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: creature.type == CreatureType.npc
              ? Colors.purple.withValues(alpha: 0.2)
              : AppTheme.accent.withValues(alpha: 0.2),
          child: creature.imagePath != null
              ? ClipOval(
                  child: SmartNetworkImage(
                    imageUrl: creature.imagePath!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: Icon(
                      creature.type == CreatureType.npc
                          ? Icons.person
                          : Icons.pets,
                      color: creature.type == CreatureType.npc
                          ? Colors.purple
                          : AppTheme.accent,
                    ),
                  ),
                )
              : Icon(
                  creature.type == CreatureType.npc ? Icons.person : Icons.pets,
                  color: creature.type == CreatureType.npc
                      ? Colors.purple
                      : AppTheme.accent,
                ),
        ),
        title: Row(
          children: [
            Text(creature.name),
            if (creature.type == CreatureType.npc) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'NPC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: creature.location != null
            ? Text('Localização: ${creature.location}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref
                    .read(hiveDatabaseProvider)
                    .deleteCreature(creature.id);
                ref.invalidate(creaturesProvider(adventureId));

                // Mark as dirty
                ref.read(unsyncedChangesProvider.notifier).state = true;
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (creature.description.isNotEmpty) ...[
                  Text(creature.description),
                  const SizedBox(height: 12),
                ],
                _DescriptionRow(
                  icon: Icons.favorite,
                  label: 'Motivação',
                  text: creature.motivation,
                  adventureId: adventureId,
                ),
                const SizedBox(height: 12),
                _DescriptionRow(
                  icon: Icons.trending_down,
                  label: 'Ao Perder',
                  text: creature.losingBehavior,
                  adventureId: adventureId,
                ),
                if (creature.stats.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ficha / Estatísticas',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          creature.stats,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === Shared Components ===

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.secondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  final String adventureId;
  final Function(int) onTabChange;

  const _SummaryTab({required this.adventureId, required this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final creatures = ref.watch(creaturesProvider(adventureId));
    final legends = ref.watch(legendsProvider(adventureId));
    final events = ref.watch(randomEventsProvider(adventureId));

    final npcs = creatures.where((c) => c.type == CreatureType.npc).toList();
    final monsters = creatures
        .where((c) => c.type == CreatureType.monster)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.dashboard,
            title: 'Resumo da Aventura',
            subtitle: 'Visão geral e acesso rápido',
          ),
          const SizedBox(height: 24),
          _SummaryCard(
            title: 'Locais',
            icon: Icons.map,
            color: AppTheme.primary,
            count: pois.length,
            items: pois.map((p) => '#${p.number} ${p.name}').toList(),
            onTap: () => onTabChange(3), // Switch to Locais tab
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'NPCs',
                  icon: Icons.person,
                  color: Colors.purple,
                  count: npcs.length,
                  items: npcs.map((c) => c.name).toList(),
                  onTap: () => onTabChange(5), // Switch to Criaturas tab
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Monstros',
                  icon: Icons.pets,
                  color: AppTheme.accent,
                  count: monsters.length,
                  items: monsters.map((c) => c.name).toList(),
                  onTap: () => onTabChange(5), // Switch to Criaturas tab
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            title: 'Rumores',
            icon: Icons.auto_stories,
            color: Colors.orange,
            count: legends.length,
            items: legends.map((l) => l.text).toList(),
            onTap: () => onTabChange(2), // Switch to Rumores tab
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            title: 'Eventos',
            icon: Icons.casino,
            color: Colors.teal,
            count: events.length,
            items: events
                .map((e) => '${e.diceRange}: ${e.eventType.displayName}')
                .toList(),
            onTap: () => onTabChange(4), // Switch to Eventos tab
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final List<String> items;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (items.isNotEmpty) ...[
                const Divider(height: 24),
                ...items
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: color.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${items.length - 3} outros...',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Nenhum item criado',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
