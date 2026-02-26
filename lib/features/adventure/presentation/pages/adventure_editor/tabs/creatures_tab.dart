import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../../core/ai/ai_prompts.dart";
import "../../../../../../core/ai/ai_providers.dart";
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../application/adventure_providers.dart';
import "../../../../domain/domain.dart";
import "../../../widgets/npc_knowledge_dialog.dart";
import "../../../widgets/smart_text_field.dart";
import "../widgets/section_header.dart";

class CreaturesTab extends ConsumerWidget {
  final String adventureId;

  const CreaturesTab({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatures = ref.watch(creaturesProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.pets,
            title: "Bestiário & NPCs",
            subtitle: "Quem habita este lugar?",
          ),
          const SizedBox(height: 16),
          Expanded(
            child: creatures.isEmpty
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
                        const Text(
                          "Nenhuma criatura ou NPC registrado. Adicione os habitantes.",
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: creatures.length,
                    itemBuilder: (context, index) {
                      final creature = creatures[index];
                      return _CreatureListItem(
                        creature: creature,
                        adventureId: adventureId,
                        onEdit: () => _showCreatureDialog(
                          context,
                          ref,
                          creatureToEdit: creature,
                        ),
                        onDelete: () => _deleteCreature(context, ref, creature),
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

  Future<void> _deleteCreature(
    BuildContext context,
    WidgetRef ref,
    Creature creature,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Criatura?"),
        content: const Text("Essa ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Remover",
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
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
    }
  }

  void _showCreatureDialog(
    BuildContext context,
    WidgetRef ref, {
    Creature? creatureToEdit,
  }) {
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

    CreatureType selectedType = creatureToEdit?.type ?? CreatureType.monster;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? "Editar Criatura" : "Adicionar Criatura"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nome",
                    hintText: "ex: Goblin, Guarda Real",
                  ),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final db = ref.read(hiveDatabaseProvider);

                  if (isEditing) {
                    final updatedCreature = creatureToEdit.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      stats: statsController.text,
                      type: selectedType,
                      motivation: motivationController.text,
                      losingBehavior: losingBehaviorController.text,
                    );
                    await db.saveCreature(updatedCreature);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
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
                    final creature = Creature.create(
                      adventureId: adventureId,
                      name: nameController.text,
                      description: descController.text,
                      stats: statsController.text,
                      type: selectedType,
                      motivation: motivationController.text,
                      losingBehavior: losingBehaviorController.text,
                    );
                    await db.saveCreature(creature);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: creature.type == CreatureType.npc
                      ? Colors.purple.withValues(alpha: 0.2)
                      : AppTheme.accent.withValues(alpha: 0.2),
                  child: Icon(
                    creature.type == CreatureType.npc
                        ? Icons.person
                        : Icons.pets,
                    color: creature.type == CreatureType.npc
                        ? Colors.purple
                        : AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creature.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (creature.description.isNotEmpty)
                        Text(
                          creature.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                if (creature.type == CreatureType.npc &&
                    ref.watch(hasAiConfiguredProvider))
                  IconButton(
                    icon: const Icon(Icons.psychology, color: Colors.purple),
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
}
