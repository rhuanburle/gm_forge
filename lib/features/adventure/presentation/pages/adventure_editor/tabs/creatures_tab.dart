import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/smart_text_field.dart';
import '../widgets/section_header.dart';

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
            title: 'Bestiário & NPCs',
            subtitle: 'Quem habita este lugar?',
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
                          'Nenhuma criatura ou NPC registrado. Adicione os habitantes.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: creatures.length,
                    itemBuilder: (context, index) {
                      final creature = creatures[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
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
                          title: Text(creature.name),
                          subtitle: Text(
                            creature.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showCreatureDialog(
                                  context,
                                  ref,
                                  creatureToEdit: creature,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppTheme.error,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remover Criatura?'),
                                      content: const Text(
                                        'Essa ação não pode ser desfeita.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Remover',
                                            style: TextStyle(
                                              color: AppTheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await ref
                                        .read(hiveDatabaseProvider)
                                        .deleteCreature(creature.id);
                                    ref.invalidate(
                                      creaturesProvider(adventureId),
                                    );
                                    ref
                                            .read(
                                              unsyncedChangesProvider.notifier,
                                            )
                                            .state =
                                        true;
                                  }
                                },
                              ),
                            ],
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
          title: Text(isEditing ? 'Editar Criatura' : 'Adicionar Criatura'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<CreatureType>(
                  segments: const [
                    ButtonSegment(
                      value: CreatureType.monster,
                      label: Text('Monstro'),
                      icon: Icon(Icons.pets),
                    ),
                    ButtonSegment(
                      value: CreatureType.npc,
                      label: Text('NPC'),
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
                    labelText: 'Nome',
                    hintText: 'ex: Goblin, Guarda Real',
                  ),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: descController,
                  adventureId: adventureId,
                  label: 'Descrição / Comportamento',
                  hint: "Aparência, táticas, personalidade...",
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: motivationController,
                  decoration: const InputDecoration(
                    labelText: 'Motivação',
                    hintText: 'O que ele quer? (ex: Proteger o ninho)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: losingBehaviorController,
                  decoration: const InputDecoration(
                    labelText: 'Comportamento ao Perder',
                    hintText: 'ex: Foge, negocia, luta até a morte',
                  ),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: statsController,
                  adventureId: adventureId,
                  label: 'Estatísticas Resumidas',
                  hint: 'PV 10, CA 12, Ataque +3 (1d6)',
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
                if (nameController.text.isNotEmpty) {
                  if (isEditing) {
                    final updatedCreature = creatureToEdit.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      stats: statsController.text,
                      type: selectedType,
                      motivation: motivationController.text,
                      losingBehavior: losingBehaviorController.text,
                    );
                    await ref
                        .read(hiveDatabaseProvider)
                        .saveCreature(updatedCreature);
                  } else {
                    final creature = Creature(
                      adventureId: adventureId,
                      name: nameController.text,
                      description: descController.text,
                      stats: statsController.text,
                      type: selectedType,
                      motivation: motivationController.text,
                      losingBehavior: losingBehaviorController.text,
                    );
                    await ref.read(hiveDatabaseProvider).saveCreature(creature);
                  }
                  ref.invalidate(creaturesProvider(adventureId));
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
