import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/sync_button.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';
import '../widgets/campaign/pc_card.dart';
import '../widgets/campaign/faction_card.dart';
import '../widgets/campaign/lore_card.dart';
import '../widgets/campaign/region_card.dart';

class CampaignHubPage extends ConsumerStatefulWidget {
  final String campaignId;

  const CampaignHubPage({super.key, required this.campaignId});

  @override
  ConsumerState<CampaignHubPage> createState() => _CampaignHubPageState();
}

class _CampaignHubPageState extends ConsumerState<CampaignHubPage> {
  String get campaignId => widget.campaignId;

  // ---------------------------------------------------------------------------
  // CRUD helpers
  // ---------------------------------------------------------------------------

  void _markUnsynced() {
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(campaign.name),
        actions: const [CloudSyncButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(
              context,
              adventureCount: adventures.length,
              pcCount: pcs.length,
              factionCount: factions.length,
              loreCount: loreEntries.length,
            ),
            const SizedBox(height: 24),

            // Aventuras
            _buildAdventuresSection(context, adventures),
            const SizedBox(height: 24),

            // Personagens (PCs)
            _buildPcsSection(context, pcs),
            const SizedBox(height: 24),

            // Faccoes
            _buildFactionsSection(context, factions),
            const SizedBox(height: 24),

            // Lore
            _buildLoreSection(context, loreEntries),
            const SizedBox(height: 24),

            // Regioes
            _buildRegionsSection(context, regions),
            const SizedBox(height: 24),

            // Notas
            _buildNotesSection(context, notes),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Stats Row
  // ---------------------------------------------------------------------------

  Widget _buildQuickStats(
    BuildContext context, {
    required int adventureCount,
    required int pcCount,
    required int factionCount,
    required int loreCount,
  }) {
    final isCompact = screenSizeOf(context) == ScreenSize.compact;
    final cards = [
      _statCard(context, Icons.map, 'Aventuras', adventureCount,
          AppTheme.primary),
      _statCard(context, Icons.person, 'PCs', pcCount,
          AppTheme.secondary),
      _statCard(context, Icons.groups, 'Faccoes', factionCount,
          AppTheme.accent),
      _statCard(context, Icons.auto_stories, 'Lore', loreCount,
          AppTheme.info),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cards,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String label,
    int count,
    Color color,
  ) {
    final isCompact = screenSizeOf(context) == ScreenSize.compact;
    final width = isCompact
        ? (MediaQuery.sizeOf(context).width - 48) / 2
        : null;

    return SizedBox(
      width: isCompact ? width : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Aventuras
  // ---------------------------------------------------------------------------

  Widget _buildAdventuresSection(
      BuildContext context, List<Adventure> adventures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.map,
          title: 'Aventuras',
          onAdd: () {
            // Navigate to adventure creation – for now just push to root
            context.push('/');
          },
        ),
        if (adventures.isEmpty)
          _emptyState(context, 'Nenhuma aventura vinculada a esta campanha.')
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: adventures.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final adventure = adventures[index];
                return SizedBox(
                  width: 220,
                  child: _adventureMiniCard(context, adventure),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _adventureMiniCard(BuildContext context, Adventure adventure) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/adventure/play/${adventure.id}'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface,
                AppTheme.primaryDark.withValues(alpha: 0.4),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.map, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  if (adventure.isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRONTA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                adventure.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                adventure.conceptWhat.isNotEmpty
                    ? adventure.conceptWhat
                    : adventure.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Personagens (PCs)
  // ---------------------------------------------------------------------------

  Widget _buildPcsSection(BuildContext context, List<PlayerCharacter> pcs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.person,
          title: 'Personagens (PCs)',
          onAdd: () => _showAddPcDialog(context),
        ),
        if (pcs.isEmpty)
          _emptyState(context, 'Nenhum personagem adicionado.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsiveColumns(context),
              childAspectRatio: 1.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: pcs.length,
            itemBuilder: (context, index) {
              final pc = pcs[index];
              return PcCard(
                pc: pc,
                onEdit: () => _showEditPcDialog(context, pc),
                onDelete: () => _confirmDelete(
                  context,
                  title: 'Excluir Personagem',
                  message:
                      'Tem certeza que deseja excluir "${pc.name}"?',
                  onConfirm: () async {
                    await ref
                        .read(hiveDatabaseProvider)
                        .deletePlayerCharacter(pc.id);
                    ref.invalidate(playerCharactersProvider(campaignId));
                    _markUnsynced();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Faccoes
  // ---------------------------------------------------------------------------

  Widget _buildFactionsSection(
      BuildContext context, List<Faction> factions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.groups,
          title: 'Faccoes',
          onAdd: () => _showAddFactionDialog(context),
        ),
        if (factions.isEmpty)
          _emptyState(context, 'Nenhuma faccao adicionada.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsiveColumns(context),
              childAspectRatio: 2.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: factions.length,
            itemBuilder: (context, index) {
              final faction = factions[index];
              return FactionCard(
                faction: faction,
                onEdit: () => _showEditFactionDialog(context, faction),
                onDelete: () => _confirmDelete(
                  context,
                  title: 'Excluir Faccao',
                  message:
                      'Tem certeza que deseja excluir "${faction.name}"?',
                  onConfirm: () async {
                    await ref
                        .read(hiveDatabaseProvider)
                        .deleteFaction(faction.id);
                    ref.invalidate(campaignFactionsProvider(campaignId));
                    _markUnsynced();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Lore
  // ---------------------------------------------------------------------------

  Widget _buildLoreSection(BuildContext context, List<LoreEntry> entries) {
    // Group by category
    final grouped = <LoreCategory, List<LoreEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.auto_stories,
          title: 'Lore',
          onAdd: () => _showAddLoreDialog(context),
        ),
        if (entries.isEmpty)
          _emptyState(context, 'Nenhuma entrada de lore adicionada.')
        else
          ...grouped.entries.map((group) {
            return ExpansionTile(
              leading: Icon(
                _loreCategoryIcon(group.key),
                color: AppTheme.secondary,
                size: 20,
              ),
              title: Text(
                '${group.key.displayName} (${group.value.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              initiallyExpanded: true,
              children: group.value
                  .map((lore) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: LoreCard(
                          lore: lore,
                          onEdit: () =>
                              _showEditLoreDialog(context, lore),
                          onDelete: () => _confirmDelete(
                            context,
                            title: 'Excluir Lore',
                            message:
                                'Tem certeza que deseja excluir "${lore.title}"?',
                            onConfirm: () async {
                              await ref
                                  .read(hiveDatabaseProvider)
                                  .deleteLoreEntry(lore.id);
                              ref.invalidate(
                                  loreEntriesProvider(campaignId));
                              _markUnsynced();
                            },
                          ),
                        ),
                      ))
                  .toList(),
            );
          }),
      ],
    );
  }

  IconData _loreCategoryIcon(LoreCategory category) {
    switch (category) {
      case LoreCategory.deity:
        return Icons.auto_awesome;
      case LoreCategory.myth:
        return Icons.menu_book;
      case LoreCategory.history:
        return Icons.history_edu;
      case LoreCategory.geography:
        return Icons.public;
      case LoreCategory.custom:
        return Icons.article;
    }
  }

  // ---------------------------------------------------------------------------
  // Regioes
  // ---------------------------------------------------------------------------

  Widget _buildRegionsSection(BuildContext context, List<Region> regions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.hexagon_outlined,
          title: 'Regioes',
          onAdd: () => _showAddRegionDialog(context),
        ),
        if (regions.isEmpty)
          _emptyState(context, 'Nenhuma regiao adicionada.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsiveColumns(context),
              childAspectRatio: 2.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: regions.length,
            itemBuilder: (context, index) {
              final region = regions[index];
              return RegionCard(
                region: region,
                onEdit: () => _showEditRegionDialog(context, region),
                onDelete: () => _confirmDelete(
                  context,
                  title: 'Excluir Regiao',
                  message:
                      'Tem certeza que deseja excluir "${region.name}"?',
                  onConfirm: () async {
                    await ref
                        .read(hiveDatabaseProvider)
                        .deleteRegion(region.id);
                    ref.invalidate(regionsProvider(campaignId));
                    _markUnsynced();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Notas
  // ---------------------------------------------------------------------------

  Widget _buildNotesSection(BuildContext context, List<Note> notes) {
    // Sort: pinned first, then by updatedAt descending
    final sorted = List<Note>.from(notes)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    // Group by category
    final grouped = <NoteCategory, List<Note>>{};
    for (final note in sorted) {
      grouped.putIfAbsent(note.category, () => []).add(note);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.note_alt,
          title: 'Notas',
          onAdd: () => _showAddNoteDialog(context),
        ),
        if (notes.isEmpty)
          _emptyState(context, 'Nenhuma nota adicionada.')
        else
          ...grouped.entries.map((group) {
            return ExpansionTile(
              leading: Icon(
                Icons.folder_outlined,
                color: AppTheme.secondary,
                size: 20,
              ),
              title: Text(
                '${group.key.displayName} (${group.value.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              initiallyExpanded: true,
              children: group.value
                  .map((note) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: _noteCard(context, note),
                      ))
                  .toList(),
            );
          }),
      ],
    );
  }

  Widget _noteCard(BuildContext context, Note note) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: note.isPinned
            ? const Icon(Icons.push_pin, color: AppTheme.warning, size: 18)
            : const Icon(Icons.note, color: AppTheme.textMuted, size: 18),
        title: Text(
          note.title,
          style: Theme.of(context).textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          iconSize: 20,
          onSelected: (value) {
            if (value == 'edit') {
              _showEditNoteDialog(context, note);
            } else if (value == 'pin') {
              _togglePinNote(note);
            } else if (value == 'delete') {
              _confirmDelete(
                context,
                title: 'Excluir Nota',
                message:
                    'Tem certeza que deseja excluir "${note.title}"?',
                onConfirm: () async {
                  await ref.read(hiveDatabaseProvider).deleteNote(note.id);
                  ref.invalidate(notesProvider(campaignId));
                  _markUnsynced();
                },
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(note.isPinned ? 'Desafixar' : 'Fixar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.secondary, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.error, size: 18),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePinNote(Note note) async {
    final updated = note.copyWith(isPinned: !note.isPinned);
    await ref.read(hiveDatabaseProvider).saveNote(updated);
    ref.invalidate(notesProvider(campaignId));
    _markUnsynced();
  }

  // ---------------------------------------------------------------------------
  // Empty state widget
  // ---------------------------------------------------------------------------

  Widget _emptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm delete
  // ---------------------------------------------------------------------------

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD / EDIT DIALOGS
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // PC Dialog
  // ---------------------------------------------------------------------------

  void _showAddPcDialog(BuildContext context) {
    _showPcFormDialog(context, null);
  }

  void _showEditPcDialog(BuildContext context, PlayerCharacter pc) {
    _showPcFormDialog(context, pc);
  }

  void _showPcFormDialog(BuildContext context, PlayerCharacter? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final playerNameCtrl =
        TextEditingController(text: existing?.playerName ?? '');
    final speciesCtrl =
        TextEditingController(text: existing?.species ?? '');
    final classCtrl =
        TextEditingController(text: existing?.characterClass ?? '');
    final originCtrl =
        TextEditingController(text: existing?.origin ?? '');
    final backstoryCtrl =
        TextEditingController(text: existing?.backstory ?? '');
    final criticalCtrl =
        TextEditingController(text: existing?.criticalData ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final levelCtrl =
        TextEditingController(text: (existing?.level ?? 1).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null
            ? 'Novo Personagem'
            : 'Editar Personagem'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: playerNameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nome do Jogador'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: speciesCtrl,
                decoration: const InputDecoration(labelText: 'Especie'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: classCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Classe'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: levelCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nivel'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: originCtrl,
                decoration: const InputDecoration(labelText: 'Origem'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: backstoryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Historia'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: criticalCtrl,
                decoration:
                    const InputDecoration(labelText: 'Dados Criticos'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final level = int.tryParse(levelCtrl.text.trim()) ?? 1;
              final db = ref.read(hiveDatabaseProvider);

              if (existing != null) {
                final updated = existing.copyWith(
                  name: name,
                  playerName: playerNameCtrl.text.trim(),
                  species: speciesCtrl.text.trim(),
                  characterClass: classCtrl.text.trim(),
                  origin: originCtrl.text.trim(),
                  backstory: backstoryCtrl.text.trim(),
                  criticalData: criticalCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                  level: level,
                );
                await db.savePlayerCharacter(updated);
              } else {
                final pc = PlayerCharacter.create(
                  campaignId: campaignId,
                  name: name,
                  playerName: playerNameCtrl.text.trim(),
                  species: speciesCtrl.text.trim(),
                  characterClass: classCtrl.text.trim(),
                  origin: originCtrl.text.trim(),
                  backstory: backstoryCtrl.text.trim(),
                  criticalData: criticalCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                  level: level,
                );
                await db.savePlayerCharacter(pc);
              }

              ref.invalidate(playerCharactersProvider(campaignId));
              _markUnsynced();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Faction Dialog
  // ---------------------------------------------------------------------------

  void _showAddFactionDialog(BuildContext context) {
    _showFactionFormDialog(context, null);
  }

  void _showEditFactionDialog(BuildContext context, Faction faction) {
    _showFactionFormDialog(context, faction);
  }

  void _showFactionFormDialog(BuildContext context, Faction? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final stakesCtrl =
        TextEditingController(text: existing?.stakes ?? '');
    FactionType selectedType = existing?.type ?? FactionType.faction;
    FactionPower selectedPower =
        existing?.powerLevel ?? FactionPower.moderate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              existing == null ? 'Nova Faccao' : 'Editar Faccao'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nome *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FactionType>(
                  initialValue: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Tipo'),
                  items: FactionType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedType = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FactionPower>(
                  initialValue: selectedPower,
                  decoration: const InputDecoration(
                      labelText: 'Nivel de Poder'),
                  items: FactionPower.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedPower = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stakesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Apostas/Stakes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final db = ref.read(hiveDatabaseProvider);

                if (existing != null) {
                  final updated = existing.copyWith(
                    name: name,
                    description: descCtrl.text.trim(),
                    type: selectedType,
                    powerLevel: selectedPower,
                    stakes: stakesCtrl.text.trim(),
                  );
                  await db.saveFaction(updated);
                } else {
                  final faction = Faction.create(
                    campaignId: campaignId,
                    name: name,
                    description: descCtrl.text.trim(),
                    type: selectedType,
                    powerLevel: selectedPower,
                    stakes: stakesCtrl.text.trim(),
                  );
                  await db.saveFaction(faction);
                }

                ref.invalidate(campaignFactionsProvider(campaignId));
                _markUnsynced();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lore Dialog
  // ---------------------------------------------------------------------------

  void _showAddLoreDialog(BuildContext context) {
    _showLoreFormDialog(context, null);
  }

  void _showEditLoreDialog(BuildContext context, LoreEntry lore) {
    _showLoreFormDialog(context, lore);
  }

  void _showLoreFormDialog(BuildContext context, LoreEntry? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl =
        TextEditingController(text: existing?.content ?? '');
    final tagsCtrl =
        TextEditingController(text: existing?.tags.join(', ') ?? '');
    LoreCategory selectedCategory =
        existing?.category ?? LoreCategory.custom;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? 'Nova Entrada de Lore'
              : 'Editar Lore'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Titulo *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LoreCategory>(
                  initialValue: selectedCategory,
                  decoration:
                      const InputDecoration(labelText: 'Categoria'),
                  items: LoreCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Conteudo'),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (separadas por virgula)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final tags = tagsCtrl.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                final db = ref.read(hiveDatabaseProvider);

                if (existing != null) {
                  final updated = existing.copyWith(
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                  );
                  await db.saveLoreEntry(updated);
                } else {
                  final lore = LoreEntry.create(
                    campaignId: campaignId,
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                  );
                  await db.saveLoreEntry(lore);
                }

                ref.invalidate(loreEntriesProvider(campaignId));
                _markUnsynced();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Region Dialog
  // ---------------------------------------------------------------------------

  void _showAddRegionDialog(BuildContext context) {
    _showRegionFormDialog(context, null);
  }

  void _showEditRegionDialog(BuildContext context, Region region) {
    _showRegionFormDialog(context, region);
  }

  void _showRegionFormDialog(BuildContext context, Region? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final hexCtrl =
        TextEditingController(text: existing?.hexCode ?? '');
    final terrainCtrl =
        TextEditingController(text: existing?.terrain ?? '');
    int dangerLevel = existing?.dangerLevel ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? 'Nova Regiao'
              : 'Editar Regiao'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nome *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: hexCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Codigo Hex'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: terrainCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Terreno'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Nivel de Perigo: $dangerLevel',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Slider(
                  value: dangerLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: dangerLevel.toString(),
                  activeColor: AppTheme.error,
                  onChanged: (v) {
                    setDialogState(
                        () => dangerLevel = v.round());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final db = ref.read(hiveDatabaseProvider);

                if (existing != null) {
                  final updated = existing.copyWith(
                    name: name,
                    hexCode: hexCtrl.text.trim(),
                    terrain: terrainCtrl.text.trim(),
                    dangerLevel: dangerLevel,
                  );
                  await db.saveRegion(updated);
                } else {
                  final region = Region.create(
                    campaignId: campaignId,
                    name: name,
                    hexCode: hexCtrl.text.trim(),
                    terrain: terrainCtrl.text.trim(),
                    dangerLevel: dangerLevel,
                  );
                  await db.saveRegion(region);
                }

                ref.invalidate(regionsProvider(campaignId));
                _markUnsynced();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Note Dialog
  // ---------------------------------------------------------------------------

  void _showAddNoteDialog(BuildContext context) {
    _showNoteFormDialog(context, null);
  }

  void _showEditNoteDialog(BuildContext context, Note note) {
    _showNoteFormDialog(context, note);
  }

  void _showNoteFormDialog(BuildContext context, Note? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl =
        TextEditingController(text: existing?.content ?? '');
    final tagsCtrl =
        TextEditingController(text: existing?.tags.join(', ') ?? '');
    NoteCategory selectedCategory =
        existing?.category ?? NoteCategory.misc;
    bool isPinned = existing?.isPinned ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
              Text(existing == null ? 'Nova Nota' : 'Editar Nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Titulo *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<NoteCategory>(
                  initialValue: selectedCategory,
                  decoration:
                      const InputDecoration(labelText: 'Categoria'),
                  items: NoteCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Conteudo'),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (separadas por virgula)',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Fixar nota'),
                  value: isPinned,
                  activeThumbColor: AppTheme.warning,
                  onChanged: (v) {
                    setDialogState(() => isPinned = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final tags = tagsCtrl.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                final db = ref.read(hiveDatabaseProvider);

                if (existing != null) {
                  final updated = existing.copyWith(
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                    isPinned: isPinned,
                  );
                  await db.saveNote(updated);
                } else {
                  final note = Note.create(
                    campaignId: campaignId,
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                    isPinned: isPinned,
                  );
                  await db.saveNote(note);
                }

                ref.invalidate(notesProvider(campaignId));
                _markUnsynced();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
