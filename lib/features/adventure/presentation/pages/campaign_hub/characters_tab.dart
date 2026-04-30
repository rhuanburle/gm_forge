import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/auth/auth_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/image_upload_service.dart';
import '../../../../../core/widgets/image_upload_field.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';
import '../../widgets/campaign/pc_card.dart';
import '../../widgets/campaign/faction_card.dart';

class CharactersTab extends ConsumerStatefulWidget {
  final String campaignId;

  const CharactersTab({super.key, required this.campaignId});

  @override
  ConsumerState<CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends ConsumerState<CharactersTab> {
  String get campaignId => widget.campaignId;

  void _markUnsynced() {
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final pcs = ref.watch(playerCharactersProvider(campaignId));
    final factions = ref.watch(campaignFactionsProvider(campaignId));
    final npcs = ref.watch(campaignCreaturesProvider(campaignId))
        .where((c) => c.type == CreatureType.npc)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildPcsSection(context, pcs),
        const SizedBox(height: 24),
        _buildFactionsSection(context, factions),
        const SizedBox(height: 24),
        _buildNpcsSection(context, npcs),
      ],
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
                    if (pc.imageUrl?.isNotEmpty == true) {
                      ImageUploadService.deleteByUrl(pc.imageUrl!);
                    }
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: factions.length,
            itemBuilder: (context, index) {
              final faction = factions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FactionCard(
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
                ),
              );
            },
          ),
      ],
    );
  }

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
    final gmNotesCtrl = TextEditingController(text: existing?.gmNotes ?? '');
    final personalArcCtrl = TextEditingController(text: existing?.personalArc ?? '');
    final backstoryHooksCtrl = TextEditingController(text: existing?.backstoryHooks ?? '');
    String? pcImageUrl = existing?.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        title: Text(existing == null
            ? 'Novo Personagem'
            : 'Editar Personagem'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: ImageUploadField(
                  isCircular: true,
                  preset: ImageCompressPreset.avatar,
                  currentImageUrl: pcImageUrl,
                  storagePath:
                      'images/${ref.read(authServiceProvider).currentUser?.uid ?? 'guest'}/characters',
                  placeholderIcon: Icons.person,
                  onChanged: (url) => setDialogState(() => pcImageUrl = url),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Notas do Mestre (privadas)',
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: personalArcCtrl,
                decoration: const InputDecoration(
                  labelText: 'Arco pessoal',
                  hintText: 'O que esse personagem quer resolver?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: backstoryHooksCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ganchos do backstory',
                  hintText: 'Elementos do passado ainda não explorados...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gmNotesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Anotações do mestre',
                  hintText: 'Segredos que o PJ não sabe, padrões de comportamento...',
                ),
                maxLines: 3,
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
                  imageUrl: pcImageUrl,
                  clearImageUrl: pcImageUrl == null,
                  gmNotes: gmNotesCtrl.text.trim(),
                  personalArc: personalArcCtrl.text.trim(),
                  backstoryHooks: backstoryHooksCtrl.text.trim(),
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
                  imageUrl: pcImageUrl,
                  gmNotes: gmNotesCtrl.text.trim(),
                  personalArc: personalArcCtrl.text.trim(),
                  backstoryHooks: backstoryHooksCtrl.text.trim(),
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
      ),  // StatefulBuilder
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
    int partyDisposition = existing?.partyDisposition ?? 0;

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
                const SizedBox(height: 12),
                Text(
                  'Disposição com o grupo',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                StatefulBuilder(
                  builder: (ctx2, setSlider) => Column(
                    children: [
                      Slider(
                        value: partyDisposition.toDouble(),
                        min: -3,
                        max: 3,
                        divisions: 6,
                        label: _dispositionLabel(partyDisposition),
                        activeColor: _dispositionColor(partyDisposition),
                        onChanged: (v) {
                          setSlider(() => partyDisposition = v.round());
                        },
                      ),
                      Text(
                        _dispositionLabel(partyDisposition),
                        style: Theme.of(ctx2).textTheme.labelSmall?.copyWith(
                          color: _dispositionColor(partyDisposition),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                    partyDisposition: partyDisposition,
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
                    partyDisposition: partyDisposition,
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
  // Helpers
  // ---------------------------------------------------------------------------

  String _dispositionLabel(int d) {
    switch (d) {
      case -3: return 'Inimigo Mortal';
      case -2: return 'Hostil';
      case -1: return 'Desconfiado';
      case 0:  return 'Neutro';
      case 1:  return 'Amigável';
      case 2:  return 'Aliado';
      case 3:  return 'Aliado Fiel';
      default: return 'Neutro';
    }
  }

  Color _dispositionColor(int d) {
    if (d <= -2) return AppTheme.error;
    if (d == -1) return AppTheme.warning;
    if (d == 0)  return AppTheme.textMuted;
    if (d == 1)  return AppTheme.info;
    return AppTheme.success;
  }

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

  // ---------------------------------------------------------------------------
  // NPCs
  // ---------------------------------------------------------------------------

  Widget _buildNpcsSection(BuildContext context, List<Creature> npcs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.person_pin,
          title: 'NPCs da Campanha',
          onAdd: () => _showNpcFormDialog(context, null),
        ),
        if (npcs.isEmpty)
          _emptyState(context, 'Nenhum NPC de campanha adicionado.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: npcs.length,
            itemBuilder: (context, index) {
              final npc = npcs[index];
              return _buildNpcCard(context, npc);
            },
          ),
      ],
    );
  }

  Widget _buildNpcCard(BuildContext context, Creature npc) {
    final dispColor = _npcDispositionColor(npc.disposition);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: dispColor.withValues(alpha: 0.15),
                  child: Icon(Icons.person, size: 20, color: dispColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        npc.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (npc.description.isNotEmpty)
                        Text(
                          npc.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: dispColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dispColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    npc.disposition.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: dispColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') _showNpcFormDialog(context, npc);
                    if (value == 'delete') {
                      _confirmDelete(
                        context,
                        title: 'Excluir NPC',
                        message: 'Tem certeza que deseja excluir "${npc.name}"?',
                        onConfirm: () async {
                          await ref.read(hiveDatabaseProvider).deleteCreature(npc.id);
                          ref.invalidate(campaignCreaturesProvider(campaignId));
                          _markUnsynced();
                        },
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 16, color: AppTheme.error), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: AppTheme.error))]),
                    ),
                  ],
                ),
              ],
            ),
            if (npc.motivation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag, size: 12, color: AppTheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      npc.motivation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (npc.roleplayNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.theater_comedy, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      npc.roleplayNotes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (npc.status != CreatureStatus.alive) ...[
              const SizedBox(height: 4),
              Text(
                npc.status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: npc.status == CreatureStatus.dead ? AppTheme.error : AppTheme.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _npcDispositionColor(CreatureDisposition d) {
    switch (d) {
      case CreatureDisposition.ally:    return AppTheme.success;
      case CreatureDisposition.neutral: return AppTheme.textMuted;
      case CreatureDisposition.hostile: return AppTheme.error;
      case CreatureDisposition.unknown: return AppTheme.secondary;
    }
  }

  void _showNpcFormDialog(BuildContext context, Creature? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final motivationCtrl = TextEditingController(text: existing?.motivation ?? '');
    final roleplayCtrl = TextEditingController(text: existing?.roleplayNotes ?? '');
    CreatureDisposition selectedDisposition =
        existing?.disposition ?? CreatureDisposition.neutral;
    CreatureStatus selectedStatus =
        existing?.status ?? CreatureStatus.alive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Novo NPC' : 'Editar NPC'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Aparência, papel na campanha...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motivationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motivação',
                      hintText: 'O que esse NPC quer?',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CreatureDisposition>(
                    initialValue: selectedDisposition,
                    decoration: const InputDecoration(labelText: 'Disposição'),
                    items: CreatureDisposition.values
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedDisposition = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CreatureStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: CreatureStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedStatus = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roleplayCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas de Interpretação',
                      hintText: 'Trejeitos, segredos, como ele reage...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
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
                    motivation: motivationCtrl.text.trim(),
                    disposition: selectedDisposition,
                    status: selectedStatus,
                    roleplayNotes: roleplayCtrl.text.trim(),
                  );
                  await db.saveCreature(updated);
                } else {
                  final npc = Creature.create(
                    campaignId: campaignId,
                    name: name,
                    type: CreatureType.npc,
                    description: descCtrl.text.trim(),
                    motivation: motivationCtrl.text.trim(),
                    losingBehavior: '',
                    disposition: selectedDisposition,
                    status: selectedStatus,
                    roleplayNotes: roleplayCtrl.text.trim(),
                  );
                  await db.saveCreature(npc);
                }
                ref.invalidate(campaignCreaturesProvider(campaignId));
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
