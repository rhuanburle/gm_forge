import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../application/adventure_providers.dart';
import "../../../../domain/domain.dart";
import '../../../../../../core/widgets/animated_list_item.dart';
import "../widgets/section_header.dart";

class QuestsTab extends ConsumerWidget {
  final String adventureId;

  const QuestsTab({super.key, required this.adventureId});

  Color _statusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return AppTheme.textMuted;
      case QuestStatus.inProgress:
        return AppTheme.narrative;
      case QuestStatus.completed:
        return AppTheme.quest;
      case QuestStatus.failed:
        return AppTheme.combat;
    }
  }

  IconData _statusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return Icons.hourglass_empty;
      case QuestStatus.inProgress:
        return Icons.play_arrow;
      case QuestStatus.completed:
        return Icons.check_circle;
      case QuestStatus.failed:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.assignment,
            title: "Missões & Quests",
            subtitle: "Quais desafios aguardam os aventureiros?",
          ),
          const SizedBox(height: 16),
          Expanded(
            child: quests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhuma missão registrada. Adicione quests e objetivos.",
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      final quest = quests[index];
                      return AnimatedListItem(
                        index: index,
                        child: Dismissible(
                          key: Key(quest.id),
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
                            return true;
                          },
                          onDismissed: (direction) async {
                            final db = ref.read(hiveDatabaseProvider);
                            await db.deleteQuest(quest.id);

                            ref
                                .read(historyProvider.notifier)
                                .recordAction(
                                  HistoryAction(
                                    description: 'Missão removida',
                                    onUndo: () async {
                                      await db.saveQuest(quest);
                                      ref.invalidate(questsProvider(adventureId));
                                    },
                                    onRedo: () async {
                                      await db.deleteQuest(quest.id);
                                      ref.invalidate(questsProvider(adventureId));
                                    },
                                  ),
                                );

                            ref.invalidate(questsProvider(adventureId));
                            ref.read(unsyncedChangesProvider.notifier).state = true;

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${quest.name}" removido'),
                                  action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () async {
                                      await db.saveQuest(quest);
                                      ref.invalidate(questsProvider(adventureId));
                                      ref.read(unsyncedChangesProvider.notifier).state = true;
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: _QuestListItem(
                            quest: quest,
                            adventureId: adventureId,
                            ref: ref,
                            statusColor: _statusColor(quest.status),
                            statusIcon: _statusIcon(quest.status),
                            onEdit: () => _showQuestDialog(
                              context,
                              ref,
                              questToEdit: quest,
                            ),
                            onDelete: () =>
                                _deleteQuest(context, ref, quest),
                            onStatusChanged: (newStatus) =>
                                _updateQuestStatus(ref, quest, newStatus),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showQuestDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Missão"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuestStatus(
    WidgetRef ref,
    Quest quest,
    QuestStatus newStatus,
  ) async {
    final db = ref.read(hiveDatabaseProvider);
    final updatedQuest = quest.copyWith(status: newStatus);
    await db.saveQuest(updatedQuest);

    ref
        .read(historyProvider.notifier)
        .recordAction(
          HistoryAction(
            description: 'Status da missão alterado',
            onUndo: () async {
              await db.saveQuest(quest);
              ref.invalidate(questsProvider(adventureId));
            },
            onRedo: () async {
              await db.saveQuest(updatedQuest);
              ref.invalidate(questsProvider(adventureId));
            },
          ),
        );

    ref.invalidate(questsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  Future<void> _deleteQuest(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
  ) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.deleteQuest(quest.id);

    ref
        .read(historyProvider.notifier)
        .recordAction(
          HistoryAction(
            description: 'Missão removida',
            onUndo: () async {
              await db.saveQuest(quest);
              ref.invalidate(questsProvider(adventureId));
            },
            onRedo: () async {
              await db.deleteQuest(quest.id);
              ref.invalidate(questsProvider(adventureId));
            },
          ),
        );

    ref.invalidate(questsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${quest.name}" removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await db.saveQuest(quest);
              ref.invalidate(questsProvider(adventureId));
              ref.read(unsyncedChangesProvider.notifier).state = true;
            },
          ),
        ),
      );
    }
  }

  void _showQuestDialog(
    BuildContext context,
    WidgetRef ref, {
    Quest? questToEdit,
  }) {
    final isEditing = questToEdit != null;
    final nameController =
        TextEditingController(text: questToEdit?.name);
    final descController =
        TextEditingController(text: questToEdit?.description);
    final rewardController =
        TextEditingController(text: questToEdit?.rewardDescription);

    QuestStatus selectedStatus =
        questToEdit?.status ?? QuestStatus.notStarted;
    String? adventureIdForCreation = questToEdit?.adventureId ?? adventureId;
    List<QuestObjective> objectives =
        List.from(questToEdit?.objectives ?? []);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? "Editar Missão" : "Adicionar Missão"),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome",
                        hintText: "ex: Resgatar o Prisioneiro, Derrotar o Dragão",
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Descrição",
                      hintText: "Contexto, motivação, detalhes da missão...",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<QuestStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Status",
                    ),
                    items: QuestStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _statusColor(s),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(s.displayName),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: rewardController,
                    decoration: const InputDecoration(
                      labelText: "Recompensa",
                      hintText: "Ouro, itens, aliados, informação...",
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Objectives section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Objetivos",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: "Adicionar objetivo",
                        onPressed: () {
                          setState(() {
                            objectives.add(
                              const QuestObjective(text: ''),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  ...objectives.asMap().entries.map((entry) {
                    final i = entry.key;
                    final obj = entry.value;
                    final textCtrl =
                        TextEditingController(text: obj.text);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: obj.isComplete,
                            onChanged: (val) {
                              setState(() {
                                objectives[i] = obj.copyWith(
                                  isComplete: val ?? false,
                                );
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: textCtrl,
                              decoration: InputDecoration(
                                hintText: "Descreva o objetivo...",
                                isDense: true,
                                labelText: "Objetivo ${i + 1}",
                              ),
                              onChanged: (val) {
                                objectives[i] =
                                    obj.copyWith(text: val);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                objectives.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Disponível em toda a Campanha?"),
                    subtitle: const Text("Missões globais aparecem em todas as aventuras."),
                    value: adventureIdForCreation == null,
                    onChanged: (bool value) {
                      setState(() {
                        adventureIdForCreation = value ? null : adventureId;
                      });
                    },
                    secondary: Icon(
                      adventureIdForCreation == null ? Icons.public : Icons.push_pin,
                      color: adventureIdForCreation == null ? AppTheme.primary : AppTheme.textMuted,
                    ),
                  ),
                  ],
                ),
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
                    final updatedQuest = questToEdit.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      status: selectedStatus,
                      rewardDescription: rewardController.text,
                      objectives: objectives,
                      adventureId: adventureIdForCreation,
                      clearAdventureId: adventureIdForCreation == null,
                    );
                    await db.saveQuest(updatedQuest);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Missão atualizada',
                            onUndo: () async {
                              await db.saveQuest(questToEdit);
                              ref.invalidate(
                                  questsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveQuest(updatedQuest);
                              ref.invalidate(
                                  questsProvider(adventureId));
                            },
                          ),
                        );
                  } else {
                    final adv = db.getAdventure(adventureId);
                    final campaignId = adv?.campaignId ?? adventureId;

                    final quest = Quest.create(
                      campaignId: campaignId,
                      adventureId: adventureIdForCreation,
                      name: nameController.text,
                      description: descController.text,
                      status: selectedStatus,
                      rewardDescription: rewardController.text,
                      objectives: objectives,
                    );
                    await db.saveQuest(quest);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Missão adicionada',
                            onUndo: () async {
                              await db.deleteQuest(quest.id);
                              ref.invalidate(
                                  questsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveQuest(quest);
                              ref.invalidate(
                                  questsProvider(adventureId));
                            },
                          ),
                        );
                  }
                  ref.invalidate(questsProvider(adventureId));
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

class _QuestListItem extends StatelessWidget {
  final Quest quest;
  final String adventureId;
  final WidgetRef ref;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<QuestStatus> onStatusChanged;

  const _QuestListItem({
    required this.quest,
    required this.adventureId,
    required this.ref,
    required this.statusColor,
    required this.statusIcon,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  Color _statusColorFor(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return AppTheme.textMuted;
      case QuestStatus.inProgress:
        return AppTheme.narrative;
      case QuestStatus.completed:
        return AppTheme.quest;
      case QuestStatus.failed:
        return AppTheme.combat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        quest.objectives.where((o) => o.isComplete).length;
    final totalCount = quest.objectives.length;

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
                  backgroundColor:
                      statusColor.withValues(alpha: 0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            quest.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (quest.adventureId == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                "CAMPANHA",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.textMuted.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "LOCAL",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (quest.description.isNotEmpty)
                        Text(
                          quest.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (quest.adventureId != null)
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_outlined),
                    tooltip: "Promover para Campanha",
                    onPressed: () async {
                      final db = ref.read(hiveDatabaseProvider);
                      final promoted = quest.copyWith(clearAdventureId: true);
                      await db.saveQuest(promoted);

                      ref.read(historyProvider.notifier).recordAction(
                        HistoryAction(
                          description: "Missão promovida para Campanha",
                          onUndo: () async {
                            await db.saveQuest(quest);
                            ref.invalidate(questsProvider(adventureId));
                          },
                          onRedo: () async {
                            await db.saveQuest(promoted);
                            ref.invalidate(questsProvider(adventureId));
                          },
                        ),
                      );

                      ref.invalidate(questsProvider(adventureId));
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Status badge
                Chip(
                  label: Text(
                    quest.status.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      statusColor.withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                // Quick status dropdown
                PopupMenuButton<QuestStatus>(
                  tooltip: "Alterar status",
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  onSelected: onStatusChanged,
                  itemBuilder: (context) => QuestStatus.values
                      .map(
                        (s) => PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _statusColorFor(s),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(s.displayName),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                if (totalCount > 0)
                  Text(
                    "$completedCount/$totalCount objetivos",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),

            // Objectives as checkboxes
            if (quest.objectives.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...quest.objectives.map(
                (obj) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(
                        obj.isComplete
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: obj.isComplete
                            ? AppTheme.quest
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          obj.text,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: obj.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                            color: obj.isComplete
                                ? AppTheme.textMuted
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Reward description
            if (quest.rewardDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        quest.rewardDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
