import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:uuid/uuid.dart';
import "../../../../../../core/ai/ai_prompts.dart";
import "../../../../../../core/ai/ai_providers.dart";
import '../../../../../../core/auth/auth_service.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../../../core/widgets/image_upload_field.dart';
import '../../../../../../core/widgets/import_json_dialog.dart';
import '../../../../../../core/widgets/tags_editor.dart';
import '../../../../../../core/widgets/entity_filter_bar.dart';
import '../../../../application/adventure_providers.dart';
import "../../../../domain/domain.dart";
import "../../../widgets/npc_knowledge_dialog.dart";
import "../../../widgets/smart_text_field.dart";
import '../../../../../../core/widgets/animated_list_item.dart';
import '../../../../../../core/widgets/smart_network_image.dart';
import "../widgets/section_header.dart";

class CreaturesTab extends ConsumerStatefulWidget {
  final String adventureId;

  const CreaturesTab({super.key, required this.adventureId});

  @override
  ConsumerState<CreaturesTab> createState() => _CreaturesTabState();
}

class _CreaturesTabState extends ConsumerState<CreaturesTab> {
  String _searchQuery = '';
  Set<String> _selectedTags = {};
  CreatureStatus? _statusFilter;
  CreatureDisposition? _dispositionFilter;

  @override
  Widget build(BuildContext context) {
    final creatures = ref.watch(creaturesProvider(widget.adventureId));

    final availableTags = <String>{
      for (final c in creatures) ...c.tags,
    }.toList()
      ..sort();

    final filtered = creatures.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.motivation.toLowerCase().contains(q) ||
            c.tags.any((t) => t.toLowerCase().contains(q));
        if (!matches) return false;
      }
      if (_selectedTags.isNotEmpty &&
          !_selectedTags.any((t) => c.tags.contains(t))) {
        return false;
      }
      if (_statusFilter != null && c.status != _statusFilter) return false;
      if (_dispositionFilter != null && c.disposition != _dispositionFilter) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.pets,
            title: "Bestiário & NPCs",
            subtitle: "Quem habita este lugar?",
            trailing: IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: 'Importar via JSON',
              color: AppTheme.textMuted,
              onPressed: () => _showImportDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          EntityFilterBar(
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            availableTags: availableTags,
            selectedTags: _selectedTags,
            onTagsChanged: (s) => setState(() => _selectedTags = s),
            hint: 'Buscar por nome, descrição ou tag...',
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'Todos',
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                for (final s in CreatureStatus.values)
                  _StatusFilterChip(
                    label: '${s.icon} ${s.displayName}',
                    selected: _statusFilter == s,
                    onSelected: () => setState(() => _statusFilter = s),
                  ),
                const SizedBox(width: 12),
                const VerticalDivider(width: 1),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'Qualquer atitude',
                  selected: _dispositionFilter == null,
                  onSelected: () => setState(() => _dispositionFilter = null),
                ),
                for (final d in CreatureDisposition.values)
                  _StatusFilterChip(
                    label: '${d.icon} ${d.displayName}',
                    selected: _dispositionFilter == d,
                    onSelected: () => setState(() => _dispositionFilter = d),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          creatures.isEmpty
                              ? "Nenhuma criatura ou NPC registrado. Adicione os habitantes."
                              : "Nenhum resultado para o filtro atual.",
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final creature = filtered[index];
                      return AnimatedListItem(
                        index: index,
                        child: Dismissible(
                          key: Key(creature.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppTheme.r12),
                            ),
                            child: const Icon(Icons.delete_outline, color: AppTheme.error),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remover Criatura?'),
                                content: const Text('Essa ação não pode ser desfeita.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Remover', style: TextStyle(color: AppTheme.error)),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          },
                          onDismissed: (direction) async {
                            await _deleteCreature(context, ref, creature);
                          },
                          child: _CreatureListItem(
                            creature: creature,
                            adventureId: widget.adventureId,
                            onEdit: () => _showCreatureDialog(
                              context,
                              ref,
                              creatureToEdit: creature,
                            ),
                            onDelete: () =>
                                _deleteCreature(context, ref, creature),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showCreatureDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Criatura/NPC"),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showImportJsonDialog(
      context: context,
      title: 'Importar NPC / Monstro',
      exampleJson: '''{
  "name": "Goblin Líder",
  "type": 1,
  "description": "Um goblin astuto com armadura enferrujada",
  "motivation": "Controlar o território das minas",
  "losingBehavior": "Foge e negocia rendição",
  "stats": "CA 13, PV 18, ATQ +4 (1d6+2)",
  "roleplayNotes": "Fala com sotaque peculiar",
  "conversationTopics": ["A mina abandonada", "Os elfos da floresta"],
  "disposition": 1,
  "status": 0,
  "tags": ["goblin", "boss"]
}''',
      legend: 'type: 0=Monstro  1=NPC\n'
          'status: 0=Vivo  1=Morto  2=Desaparecido  3=Capturado\n'
          'disposition: 0=Aliado  1=Neutro  2=Hostil  3=Desconhecido',
      onImport: (json) async {
        final adventureId = widget.adventureId;
        final db = ref.read(hiveDatabaseProvider);
        final adv = db.getAdventure(adventureId);
        final campaignId = adv?.campaignId ?? adventureId;
        json['id'] = const Uuid().v4();
        json['campaignId'] = campaignId;
        json['adventureId'] = adventureId;
        try {
          final creature = Creature.fromJson(json);
          await db.saveCreature(creature);
          ref.invalidate(creaturesProvider(adventureId));
          ref.read(unsyncedChangesProvider.notifier).state = true;
          if (context.mounted) AppSnackBar.success(context, '"${creature.name}" importado!');
        } catch (e) {
          if (context.mounted) AppSnackBar.error(context, 'Erro ao importar: $e');
        }
      },
    );
  }

  Future<void> _deleteCreature(
    BuildContext context,
    WidgetRef ref,
    Creature creature,
  ) async {
    final adventureId = widget.adventureId;
    final db = ref.read(hiveDatabaseProvider);
    await db.deleteCreature(creature.id);

    ref
        .read(historyProvider.notifier)
        .recordAction(
          HistoryAction(
            description: 'Criatura removida',
            onUndo: () async {
              await db.saveCreature(creature);
              ref.invalidate(creaturesProvider(adventureId));
              ref.invalidate(locationsProvider(adventureId));
              ref.invalidate(pointsOfInterestProvider(adventureId));
            },
            onRedo: () async {
              await db.deleteCreature(creature.id);
              ref.invalidate(creaturesProvider(adventureId));
              ref.invalidate(locationsProvider(adventureId));
              ref.invalidate(pointsOfInterestProvider(adventureId));
            },
          ),
        );

    ref.invalidate(creaturesProvider(adventureId));
    ref.invalidate(locationsProvider(adventureId));
    ref.invalidate(pointsOfInterestProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${creature.name}" removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await db.saveCreature(creature);
              ref.invalidate(creaturesProvider(adventureId));
              ref.invalidate(locationsProvider(adventureId));
              ref.invalidate(pointsOfInterestProvider(adventureId));
              ref.read(unsyncedChangesProvider.notifier).state = true;
            },
          ),
        ),
      );
    }
  }

  void _showCreatureDialog(
    BuildContext context,
    WidgetRef ref, {
    Creature? creatureToEdit,
  }) {
    final adventureId = widget.adventureId;
    final isEditing = creatureToEdit != null;
    final nameController = TextEditingController(text: creatureToEdit?.name);
    final descController = TextEditingController(
      text: creatureToEdit?.description,
    );
    final statsController = TextEditingController(text: creatureToEdit?.stats);
    final motivationController = TextEditingController(
      text: creatureToEdit?.motivation,
    );
    final losingBehaviorController = TextEditingController(
      text: creatureToEdit?.losingBehavior,
    );
    final roleplayNotesController = TextEditingController(
      text: creatureToEdit?.roleplayNotes,
    );
    List<String> conversationTopics =
        List.from(creatureToEdit?.conversationTopics ?? []);
    List<String> tags = List.from(creatureToEdit?.tags ?? []);

    CreatureType selectedType = creatureToEdit?.type ?? CreatureType.monster;
    CreatureStatus selectedStatus =
        creatureToEdit?.status ?? CreatureStatus.alive;
    CreatureDisposition selectedDisposition =
        creatureToEdit?.disposition ?? CreatureDisposition.unknown;
    String? adventureIdForCreation = creatureToEdit?.adventureId ?? adventureId;
    String? imageUrl = creatureToEdit?.imagePath;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? "Editar Criatura" : "Adicionar Criatura"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: ImageUploadField(
                      isCircular: true,
                      preset: ImageCompressPreset.avatar,
                      currentImageUrl: imageUrl,
                      storagePath:
                          'images/${ref.read(authServiceProvider).currentUser?.uid ?? 'guest'}/creatures',
                      placeholderIcon: selectedType == CreatureType.npc
                          ? Icons.person
                          : Icons.pest_control,
                      onChanged: (url) => setState(() => imageUrl = url),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<CreatureType>(
                    segments: const [
                      ButtonSegment(
                        value: CreatureType.monster,
                        label: Text("Monstro"),
                        icon: Icon(Icons.pets),
                      ),
                      ButtonSegment(
                        value: CreatureType.npc,
                        label: Text("NPC"),
                        icon: Icon(Icons.person),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<CreatureType> newSelection) {
                      setState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                      hintText: "ex: Goblin, Guarda Real",
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nome obrigatório'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Status + Disposition
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CreatureStatus>(
                          initialValue: selectedStatus,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            isDense: true,
                          ),
                          items: CreatureStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      '${s.icon} ${s.displayName}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                            () => selectedStatus = v ?? CreatureStatus.alive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<CreatureDisposition>(
                          initialValue: selectedDisposition,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Atitude',
                            isDense: true,
                          ),
                          items: CreatureDisposition.values
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      '${d.icon} ${d.displayName}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                            () => selectedDisposition =
                                v ?? CreatureDisposition.unknown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SmartTextField(
                    controller: descController,
                    adventureId: adventureId,
                    label: "Descrição / Comportamento",
                    hint: "Aparência, táticas, personalidade...",
                    maxLines: 3,
                    aiFieldType: AiFieldType.creatureDescription,
                    aiContext: {
                      "creatureName": nameController.text,
                      "creatureType": selectedType.displayName,
                    },
                    aiExtraContext: {"creatureType": selectedType.displayName},
                  ),
                  const SizedBox(height: 16),
                  SmartTextField(
                    controller: motivationController,
                    adventureId: adventureId,
                    label: "Motivação",
                    hint: "O que ele quer? (ex: Proteger o ninho)",
                    maxLines: 2,
                    aiFieldType: AiFieldType.creatureMotivation,
                    aiContext: {
                      "creatureName": nameController.text,
                      "creatureType": selectedType.displayName,
                    },
                  ),
                  const SizedBox(height: 16),
                  SmartTextField(
                    controller: losingBehaviorController,
                    adventureId: adventureId,
                    label: "Comportamento ao Perder",
                    hint: "ex: Foge, negocia, luta até a morte",
                    maxLines: 2,
                    aiFieldType: AiFieldType.creatureLosingBehavior,
                    aiContext: {
                      "creatureName": nameController.text,
                      "creatureType": selectedType.displayName,
                    },
                  ),
                  const SizedBox(height: 16),
                  SmartTextField(
                    controller: statsController,
                    adventureId: adventureId,
                    label: "Estatísticas Resumidas",
                    hint: "PV 10, CA 12, Ataque +3 (1d6)",
                    maxLines: 2,
                    aiFieldType: AiFieldType.creatureStats,
                    aiContext: {
                      "creatureName": nameController.text,
                      "creatureType": selectedType.displayName,
                    },
                  ),
                  const SizedBox(height: 16),
                  SmartTextField(
                    controller: roleplayNotesController,
                    adventureId: adventureId,
                    label: "Notas de Roleplay",
                    hint:
                        "Voz, maneirismos, atitude... (ex: Fala baixo, coça o nariz)",
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Tags
                  TagsEditor(
                    tags: tags,
                    onChanged: (t) => setState(() => tags = t),
                    hint: 'ex: nobreza, guilda, vila do porto',
                  ),
                  const SizedBox(height: 16),
                  // Conversation Topics
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble,
                              size: 16, color: AppTheme.npc),
                          SizedBox(width: 6),
                          Text(
                            "Tópicos de Conversa",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...conversationTopics.asMap().entries.map((entry) => Chip(
                                label: Text(entry.value,
                                    style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setState(() =>
                                    conversationTopics.removeAt(entry.key)),
                                deleteIconColor: AppTheme.error,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )),
                          ActionChip(
                            label: const Text('+ Tópico',
                                style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              final ctrl = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Novo Tópico'),
                                  content: TextField(
                                    controller: ctrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                        hintText:
                                            'ex: Política local, Tesouros...'),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancelar')),
                                    ElevatedButton(
                                      onPressed: () {
                                        final text = ctrl.text.trim();
                                        if (text.isNotEmpty) {
                                          setState(() =>
                                              conversationTopics.add(text));
                                        }
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Disponível em toda a Campanha?"),
                    subtitle: const Text(
                        "Itens globais aparecem em todas as aventuras."),
                    value: adventureIdForCreation == null,
                    onChanged: (bool value) {
                      setState(() {
                        adventureIdForCreation = value ? null : adventureId;
                      });
                    },
                    secondary: Icon(
                      adventureIdForCreation == null
                          ? Icons.public
                          : Icons.push_pin,
                      color: adventureIdForCreation == null
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final db = ref.read(hiveDatabaseProvider);

                  if (isEditing) {
                    final updatedCreature = creatureToEdit.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      stats: statsController.text,
                      type: selectedType,
                      motivation: motivationController.text,
                      losingBehavior: losingBehaviorController.text,
                      roleplayNotes: roleplayNotesController.text,
                      conversationTopics: conversationTopics,
                      tags: tags,
                      status: selectedStatus,
                      disposition: selectedDisposition,
                      adventureId: adventureIdForCreation,
                      clearAdventureId: adventureIdForCreation == null,
                      imagePath: imageUrl,
                      clearImagePath: imageUrl == null,
                    );
                    await db.saveCreature(updatedCreature);

                    ref.read(historyProvider.notifier).recordAction(
                          HistoryAction(
                            description: 'Criatura atualizada',
                            onUndo: () async {
                              await db.saveCreature(creatureToEdit);
                              ref.invalidate(creaturesProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveCreature(updatedCreature);
                              ref.invalidate(creaturesProvider(adventureId));
                            },
                          ),
                        );
                  } else {
                    final adv = db.getAdventure(adventureId);
                    final campaignId = adv?.campaignId ?? adventureId;

                    final creature = Creature.create(
                      campaignId: campaignId,
                      adventureId: adventureIdForCreation,
                      name: nameController.text,
                      description: descController.text,
                      stats: statsController.text,
                      type: selectedType,
                      motivation: motivationController.text,
                      losingBehavior: losingBehaviorController.text,
                      roleplayNotes: roleplayNotesController.text,
                      conversationTopics: conversationTopics,
                      tags: tags,
                      status: selectedStatus,
                      disposition: selectedDisposition,
                      imagePath: imageUrl,
                    );
                    await db.saveCreature(creature);

                    ref.read(historyProvider.notifier).recordAction(
                          HistoryAction(
                            description: 'Criatura adicionada',
                            onUndo: () async {
                              await db.deleteCreature(creature.id);
                              ref.invalidate(creaturesProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveCreature(creature);
                              ref.invalidate(creaturesProvider(adventureId));
                            },
                          ),
                        );
                  }
                  ref.invalidate(creaturesProvider(adventureId));
                  ref.read(unsyncedChangesProvider.notifier).state = true;
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? "Salvar" : "Adicionar"),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onSelected(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        selectedColor: AppTheme.secondary.withValues(alpha: 0.3),
      ),
    );
  }
}

class _CreatureListItem extends ConsumerWidget {
  final Creature creature;
  final String adventureId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CreatureListItem({
    required this.creature,
    required this.adventureId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final locations = ref.watch(locationsProvider(adventureId));

    final appearsInPois = pois
        .where((p) => p.creatureIds.contains(creature.id))
        .toList();
    final appearsInLocations = locations
        .where((l) => l.creatureIds.contains(creature.id))
        .toList();

    final isDead = creature.status == CreatureStatus.dead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Opacity(
                  opacity: isDead ? 0.5 : 1.0,
                  child: creature.imagePath != null &&
                          creature.imagePath!.isNotEmpty
                      ? ClipOval(
                          child: SmartNetworkImage(
                            imageUrl: creature.imagePath!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: creature.type == CreatureType.npc
                              ? AppTheme.npc.withValues(alpha: 0.2)
                              : AppTheme.accent.withValues(alpha: 0.2),
                          child: Icon(
                            creature.type == CreatureType.npc
                                ? Icons.person
                                : Icons.pets,
                            color: creature.type == CreatureType.npc
                                ? AppTheme.npc
                                : AppTheme.accent,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            creature.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration:
                                  isDead ? TextDecoration.lineThrough : null,
                              color: isDead ? AppTheme.textMuted : null,
                            ),
                          ),
                          _StatusBadge(
                            label:
                                '${creature.status.icon} ${creature.status.displayName}',
                            color: _statusColor(creature.status),
                          ),
                          if (creature.disposition !=
                              CreatureDisposition.unknown)
                            _StatusBadge(
                              label:
                                  '${creature.disposition.icon} ${creature.disposition.displayName}',
                              color:
                                  _dispositionColor(creature.disposition),
                            ),
                          if (creature.adventureId == null)
                            _StatusBadge(
                              label: 'CAMPANHA',
                              color: AppTheme.primary,
                              icon: Icons.public,
                            ),
                        ],
                      ),
                      if (creature.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            creature.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      if (creature.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        TagsDisplay(tags: creature.tags),
                      ],
                    ],
                  ),
                ),
                if (creature.adventureId != null)
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_outlined),
                    tooltip: "Promover para Campanha",
                    onPressed: () async {
                      final db = ref.read(hiveDatabaseProvider);
                      final promoted = creature.copyWith(clearAdventureId: true);
                      await db.saveCreature(promoted);

                      ref.read(historyProvider.notifier).recordAction(
                        HistoryAction(
                          description: "Criatura promovida para Campanha",
                          onUndo: () async {
                            await db.saveCreature(creature);
                            ref.invalidate(creaturesProvider(adventureId));
                          },
                          onRedo: () async {
                            await db.saveCreature(promoted);
                            ref.invalidate(creaturesProvider(adventureId));
                          },
                        ),
                      );

                      ref.invalidate(creaturesProvider(adventureId));
                      ref.read(unsyncedChangesProvider.notifier).state = true;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Promovido para itens da Campanha")),
                        );
                      }
                    },
                  ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                if (creature.type == CreatureType.npc &&
                    ref.watch(hasAiConfiguredProvider))
                  IconButton(
                    icon: const Icon(Icons.psychology, color: AppTheme.npc),
                    tooltip: "O que esse NPC sabe?",
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => NpcKnowledgeDialog(
                        adventureId: adventureId,
                        creature: creature,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (appearsInPois.isNotEmpty || appearsInLocations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  const Text(
                    "Aparece em:",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...appearsInLocations.map(
                    (l) => Chip(
                      avatar: const Icon(Icons.map, size: 12),
                      label: Text(l.name, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  ...appearsInPois.map(
                    (p) => Chip(
                      avatar: const Icon(Icons.place, size: 12),
                      label: Text(
                        "#${p.number} ${p.name}",
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(CreatureStatus s) {
    switch (s) {
      case CreatureStatus.alive:
        return AppTheme.success;
      case CreatureStatus.dead:
        return AppTheme.error;
      case CreatureStatus.missing:
        return AppTheme.warning;
      case CreatureStatus.captured:
        return AppTheme.info;
    }
  }

  Color _dispositionColor(CreatureDisposition d) {
    switch (d) {
      case CreatureDisposition.ally:
        return AppTheme.success;
      case CreatureDisposition.neutral:
        return AppTheme.textMuted;
      case CreatureDisposition.hostile:
        return AppTheme.error;
      case CreatureDisposition.unknown:
        return AppTheme.textMuted;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
