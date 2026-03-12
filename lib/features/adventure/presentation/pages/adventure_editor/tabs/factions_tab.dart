import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../application/adventure_providers.dart';
import "../../../../domain/domain.dart";
import '../../../../../../core/widgets/animated_list_item.dart';
import "../widgets/section_header.dart";

class FactionsTab extends ConsumerWidget {
  final String adventureId;

  const FactionsTab({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factions = ref.watch(factionsProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.groups,
            title: "Facções & Frentes",
            subtitle: "Quem move os fios do destino?",
          ),
          const SizedBox(height: 16),
          Expanded(
            child: factions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhuma facção ou frente registrada. Adicione as forças em jogo.",
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: factions.length,
                    itemBuilder: (context, index) {
                      final faction = factions[index];
                      return AnimatedListItem(
                        index: index,
                        child: Dismissible(
                          key: Key(faction.id),
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
                            await db.deleteFaction(faction.id);

                            ref
                                .read(historyProvider.notifier)
                                .recordAction(
                                  HistoryAction(
                                    description: 'Facção removida',
                                    onUndo: () async {
                                      await db.saveFaction(faction);
                                      ref.invalidate(factionsProvider(adventureId));
                                    },
                                    onRedo: () async {
                                      await db.deleteFaction(faction.id);
                                      ref.invalidate(factionsProvider(adventureId));
                                    },
                                  ),
                                );

                            ref.invalidate(factionsProvider(adventureId));
                            ref.read(unsyncedChangesProvider.notifier).state = true;

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${faction.name}" removido'),
                                  action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () async {
                                      await db.saveFaction(faction);
                                      ref.invalidate(factionsProvider(adventureId));
                                      ref.read(unsyncedChangesProvider.notifier).state = true;
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: _FactionListItem(
                            faction: faction,
                            onEdit: () => _showFactionDialog(
                              context,
                              ref,
                              factionToEdit: faction,
                            ),
                            onDelete: () =>
                                _deleteFaction(context, ref, faction),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showFactionDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Facção/Frente"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFaction(
    BuildContext context,
    WidgetRef ref,
    Faction faction,
  ) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.deleteFaction(faction.id);

    ref
        .read(historyProvider.notifier)
        .recordAction(
          HistoryAction(
            description: 'Facção removida',
            onUndo: () async {
              await db.saveFaction(faction);
              ref.invalidate(factionsProvider(adventureId));
            },
            onRedo: () async {
              await db.deleteFaction(faction.id);
              ref.invalidate(factionsProvider(adventureId));
            },
          ),
        );

    ref.invalidate(factionsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${faction.name}" removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await db.saveFaction(faction);
              ref.invalidate(factionsProvider(adventureId));
              ref.read(unsyncedChangesProvider.notifier).state = true;
            },
          ),
        ),
      );
    }
  }

  void _showFactionDialog(
    BuildContext context,
    WidgetRef ref, {
    Faction? factionToEdit,
  }) {
    final isEditing = factionToEdit != null;
    final nameController =
        TextEditingController(text: factionToEdit?.name);
    final descController =
        TextEditingController(text: factionToEdit?.description);
    final stakesController =
        TextEditingController(text: factionToEdit?.stakes);

    FactionType selectedType =
        factionToEdit?.type ?? FactionType.faction;
    FactionPower selectedPower =
        factionToEdit?.powerLevel ?? FactionPower.moderate;
    int memberCount = factionToEdit?.memberCount ?? 0;
    final memberCountController =
        TextEditingController(text: memberCount.toString());

    List<FactionObjective> objectives =
        List.from(factionToEdit?.objectives ?? []);
    List<FactionDanger> dangers =
        List.from(factionToEdit?.dangers ?? []);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? "Editar Facção" : "Adicionar Facção"),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<FactionType>(
                    segments: const [
                      ButtonSegment(
                        value: FactionType.faction,
                        label: Text("Facção"),
                        icon: Icon(Icons.groups),
                      ),
                      ButtonSegment(
                        value: FactionType.front,
                        label: Text("Frente"),
                        icon: Icon(Icons.warning),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<FactionType> newSelection) {
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
                      hintText: "ex: Guilda dos Mercadores, Culto da Serpente",
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Descrição",
                      hintText: "Histórico, motivações, aparência...",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: memberCountController,
                    decoration: const InputDecoration(
                      labelText: "Número de Membros",
                      hintText: "ex: 50",
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      memberCount = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<FactionPower>(
                    initialValue: selectedPower,
                    decoration: const InputDecoration(
                      labelText: "Nível de Poder",
                    ),
                    items: FactionPower.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPower = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stakesController,
                    decoration: const InputDecoration(
                      labelText: "O que está em jogo",
                      hintText: "O que acontece se essa facção vencer?",
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
                              const FactionObjective(text: ''),
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
                    final triggerCtrl =
                        TextEditingController(text: obj.trigger);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: textCtrl,
                                    decoration: const InputDecoration(
                                      labelText: "Objetivo",
                                      isDense: true,
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text("Progresso: ",
                                    style: TextStyle(fontSize: 12)),
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: obj.currentProgress > 0
                                      ? () {
                                          setState(() {
                                            objectives[i] = obj.copyWith(
                                              currentProgress:
                                                  obj.currentProgress - 1,
                                            );
                                          });
                                        }
                                      : null,
                                ),
                                Text(
                                  "${obj.currentProgress}/${obj.maxProgress}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: obj.currentProgress <
                                          obj.maxProgress
                                      ? () {
                                          setState(() {
                                            objectives[i] = obj.copyWith(
                                              currentProgress:
                                                  obj.currentProgress + 1,
                                            );
                                          });
                                        }
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text("Máx: ",
                                    style: TextStyle(fontSize: 12)),
                                SizedBox(
                                  width: 40,
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: obj.maxProgress.toString(),
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      final max =
                                          int.tryParse(val) ?? obj.maxProgress;
                                      setState(() {
                                        objectives[i] = obj.copyWith(
                                          maxProgress: max,
                                          currentProgress:
                                              obj.currentProgress > max
                                                  ? max
                                                  : null,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            TextField(
                              controller: triggerCtrl,
                              decoration: const InputDecoration(
                                labelText: "Gatilho",
                                hintText: "O que avança este objetivo?",
                                isDense: true,
                              ),
                              onChanged: (val) {
                                objectives[i] =
                                    obj.copyWith(trigger: val);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Dangers section (only for fronts)
                  if (selectedType == FactionType.front) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Perigos",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: "Adicionar perigo",
                          onPressed: () {
                            setState(() {
                              dangers.add(
                                const FactionDanger(name: ''),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    ...dangers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final danger = entry.value;
                      final dangerNameCtrl =
                          TextEditingController(text: danger.name);
                      final driveCtrl =
                          TextEditingController(text: danger.drive);
                      final disasterCtrl = TextEditingController(
                        text: danger.imminentDisaster,
                      );
                      List<String> omens = List.from(danger.omens);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: dangerNameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: "Nome do Perigo",
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        dangers[i] =
                                            danger.copyWith(name: val);
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
                                        dangers.removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: driveCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Impulso",
                                  hintText: "O que move este perigo?",
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  dangers[i] =
                                      danger.copyWith(drive: val);
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: disasterCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Desastre Iminente",
                                  hintText:
                                      "O que acontece se não for detido?",
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  dangers[i] = danger.copyWith(
                                    imminentDisaster: val,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Presságios",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        omens.add('');
                                        dangers[i] = danger.copyWith(
                                          omens: omens,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                              ...omens.asMap().entries.map((omenEntry) {
                                final oi = omenEntry.key;
                                final omenCtrl = TextEditingController(
                                  text: omenEntry.value,
                                );
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Text("  \u2022 ",
                                          style: TextStyle(fontSize: 12)),
                                      Expanded(
                                        child: TextField(
                                          controller: omenCtrl,
                                          decoration:
                                              const InputDecoration(
                                            isDense: true,
                                            hintText: "Presságio...",
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                          ),
                                          style: const TextStyle(
                                              fontSize: 13),
                                          onChanged: (val) {
                                            omens[oi] = val;
                                            dangers[i] =
                                                danger.copyWith(
                                              omens: List.from(omens),
                                            );
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: AppTheme.error,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            omens.removeAt(oi);
                                            dangers[i] =
                                                danger.copyWith(
                                              omens: List.from(omens),
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
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
                  final campaignId = ref
                          .read(adventureProvider(adventureId))
                          ?.campaignId ??
                      '';

                  if (isEditing) {
                    final updatedFaction = factionToEdit.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      type: selectedType,
                      memberCount: memberCount,
                      powerLevel: selectedPower,
                      stakes: stakesController.text,
                      objectives: objectives,
                      dangers: dangers,
                    );
                    await db.saveFaction(updatedFaction);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Facção atualizada',
                            onUndo: () async {
                              await db.saveFaction(factionToEdit);
                              ref.invalidate(
                                  factionsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveFaction(updatedFaction);
                              ref.invalidate(
                                  factionsProvider(adventureId));
                            },
                          ),
                        );
                  } else {
                    final faction = Faction.create(
                      campaignId: campaignId,
                      adventureId: adventureId,
                      name: nameController.text,
                      description: descController.text,
                      type: selectedType,
                      memberCount: memberCount,
                      powerLevel: selectedPower,
                      stakes: stakesController.text,
                      objectives: objectives,
                      dangers: dangers,
                    );
                    await db.saveFaction(faction);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Facção adicionada',
                            onUndo: () async {
                              await db.deleteFaction(faction.id);
                              ref.invalidate(
                                  factionsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveFaction(faction);
                              ref.invalidate(
                                  factionsProvider(adventureId));
                            },
                          ),
                        );
                  }
                  ref.invalidate(factionsProvider(adventureId));
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

class _FactionListItem extends StatelessWidget {
  final Faction faction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FactionListItem({
    required this.faction,
    required this.onEdit,
    required this.onDelete,
  });

  Color _powerColor(FactionPower power) {
    switch (power) {
      case FactionPower.weak:
        return AppTheme.textMuted;
      case FactionPower.moderate:
        return AppTheme.faction;
      case FactionPower.strong:
        return AppTheme.dubious;
      case FactionPower.dominant:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      faction.type == FactionType.front
                          ? AppTheme.combat.withValues(alpha: 0.2)
                          : AppTheme.faction.withValues(alpha: 0.2),
                  child: Icon(
                    faction.type == FactionType.front
                        ? Icons.warning
                        : Icons.groups,
                    color: faction.type == FactionType.front
                        ? AppTheme.combat
                        : AppTheme.faction,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faction.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (faction.description.isNotEmpty)
                        Text(
                          faction.description,
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    faction.type.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor:
                      faction.type == FactionType.front
                          ? AppTheme.combat.withValues(alpha: 0.15)
                          : AppTheme.faction.withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    faction.powerLevel.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor:
                      _powerColor(faction.powerLevel)
                          .withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                if (faction.memberCount > 0)
                  Chip(
                    avatar: const Icon(Icons.people, size: 14),
                    label: Text(
                      "${faction.memberCount} membros",
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),

            // Objectives with progress bars
            if (faction.objectives.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "Objetivos",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              ...faction.objectives.map(
                (obj) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        obj.text,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: obj.maxProgress > 0
                                  ? obj.currentProgress /
                                      obj.maxProgress
                                  : 0,
                              backgroundColor:
                                  AppTheme.textMuted.withValues(alpha: 0.3),
                              color: obj.currentProgress >=
                                      obj.maxProgress
                                  ? AppTheme.success
                                  : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${obj.currentProgress}/${obj.maxProgress}",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Dangers section (for fronts)
            if (faction.type == FactionType.front &&
                faction.dangers.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  "Perigos (${faction.dangers.length})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                children: faction.dangers
                    .map(
                      (danger) => Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          bottom: 8,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              danger.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (danger.drive.isNotEmpty)
                              Text(
                                "Impulso: ${danger.drive}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            if (danger.imminentDisaster.isNotEmpty)
                              Text(
                                "Desastre: ${danger.imminentDisaster}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.error,
                                ),
                              ),
                            if (danger.omens.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              const Text(
                                "Presságios:",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ...danger.omens.map(
                                (omen) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                  ),
                                  child: Text(
                                    "\u2022 $omen",
                                    style: const TextStyle(
                                        fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
