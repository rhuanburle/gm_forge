import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:uuid/uuid.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../../../core/widgets/import_json_dialog.dart';
import '../../../../application/adventure_providers.dart';
import "../../../../domain/domain.dart";
import '../../../../../../core/widgets/animated_list_item.dart';
import "../widgets/section_header.dart";

class ItemsTab extends ConsumerWidget {
  final String adventureId;

  const ItemsTab({super.key, required this.adventureId});

  Color _rarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return AppTheme.textMuted;
      case ItemRarity.uncommon:
        return AppTheme.quest;
      case ItemRarity.rare:
        return AppTheme.narrative;
      case ItemRarity.veryRare:
        return AppTheme.npc;
      case ItemRarity.legendary:
        return AppTheme.dubious;
    }
  }

  IconData _typeIcon(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return Icons.gavel;
      case ItemType.armor:
        return Icons.shield;
      case ItemType.potion:
        return Icons.science;
      case ItemType.scroll:
        return Icons.description;
      case ItemType.artifact:
        return Icons.auto_awesome;
      case ItemType.misc:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(adventureId));

    void importJson() => showImportJsonDialog(
      context: context,
      title: 'Importar Item / Tesouro',
      exampleJson: '''{
  "name": "Espada Longa +1",
  "description": "Espada com runas antigas gravadas",
  "type": 0,
  "rarity": 1,
  "mechanics": "+1 para ataques e dano",
  "tags": ["mágico", "arma"]
}''',
      legend: 'type: 0=Arma  1=Armadura  2=Poção  3=Pergaminho  4=Artefato  5=Misc\n'
          'rarity: 0=Comum  1=Incomum  2=Raro  3=Muito Raro  4=Lendário',
      onImport: (json) async {
        final db = ref.read(hiveDatabaseProvider);
        final adv = db.getAdventure(adventureId);
        final campaignId = adv?.campaignId ?? adventureId;
        json['id'] = const Uuid().v4();
        json['campaignId'] = campaignId;
        json['adventureId'] = adventureId;
        try {
          final item = Item.fromJson(json);
          await db.saveItem(item);
          ref.invalidate(itemsProvider(adventureId));
          ref.read(unsyncedChangesProvider.notifier).state = true;
          if (context.mounted) AppSnackBar.success(context, '"${item.name}" importado!');
        } catch (e) {
          if (context.mounted) AppSnackBar.error(context, 'Erro ao importar: $e');
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.inventory,
            title: "Itens & Tesouros",
            subtitle: "O que pode ser encontrado ou conquistado?",
            trailing: IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: 'Importar via JSON',
              color: AppTheme.textMuted,
              onPressed: importJson,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhum item registrado. Adicione tesouros e equipamentos.",
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AnimatedListItem(
                        index: index,
                        child: Dismissible(
                          key: Key(item.id),
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
                                title: const Text('Remover Item?'),
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
                            final db = ref.read(hiveDatabaseProvider);
                            await db.deleteItem(item.id);

                            ref
                                .read(historyProvider.notifier)
                                .recordAction(
                                  HistoryAction(
                                    description: 'Item removido',
                                    onUndo: () async {
                                      await db.saveItem(item);
                                      ref.invalidate(itemsProvider(adventureId));
                                    },
                                    onRedo: () async {
                                      await db.deleteItem(item.id);
                                      ref.invalidate(itemsProvider(adventureId));
                                    },
                                  ),
                                );

                            ref.invalidate(itemsProvider(adventureId));
                            ref.read(unsyncedChangesProvider.notifier).state = true;

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${item.name}" removido'),
                                  action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () async {
                                      await db.saveItem(item);
                                      ref.invalidate(itemsProvider(adventureId));
                                      ref.read(unsyncedChangesProvider.notifier).state = true;
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          child: _ItemListItem(
                            item: item,
                            ref: ref,
                            adventureId: adventureId,
                            rarityColor: _rarityColor(item.rarity),
                            typeIcon: _typeIcon(item.type),
                            onEdit: () => _showItemDialog(
                              context,
                              ref,
                              itemToEdit: item,
                            ),
                            onDelete: () =>
                                _deleteItem(context, ref, item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showItemDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Item"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.deleteItem(item.id);

    ref
        .read(historyProvider.notifier)
        .recordAction(
          HistoryAction(
            description: 'Item removido',
            onUndo: () async {
              await db.saveItem(item);
              ref.invalidate(itemsProvider(adventureId));
            },
            onRedo: () async {
              await db.deleteItem(item.id);
              ref.invalidate(itemsProvider(adventureId));
            },
          ),
        );

    ref.invalidate(itemsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.name}" removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await db.saveItem(item);
              ref.invalidate(itemsProvider(adventureId));
              ref.read(unsyncedChangesProvider.notifier).state = true;
            },
          ),
        ),
      );
    }
  }

  void _showItemDialog(
    BuildContext context,
    WidgetRef ref, {
    Item? itemToEdit,
  }) {
    final isEditing = itemToEdit != null;
    final nameController =
        TextEditingController(text: itemToEdit?.name);
    final descController =
        TextEditingController(text: itemToEdit?.description);
    final mechanicsController =
        TextEditingController(text: itemToEdit?.mechanics);

    ItemType selectedType = itemToEdit?.type ?? ItemType.misc;
    ItemRarity selectedRarity = itemToEdit?.rarity ?? ItemRarity.common;
    String? adventureIdForCreation = itemToEdit?.adventureId ?? adventureId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? "Editar Item" : "Adicionar Item"),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome",
                        hintText: "ex: Espada Flamejante, Poção de Cura",
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Descrição",
                      hintText: "Aparência, história, detalhes...",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ItemType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Tipo",
                    ),
                    items: ItemType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ItemRarity>(
                    initialValue: selectedRarity,
                    decoration: const InputDecoration(
                      labelText: "Raridade",
                    ),
                    items: ItemRarity.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _rarityColor(r),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(r.displayName),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRarity = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: mechanicsController,
                    decoration: const InputDecoration(
                      labelText: "Mecânicas",
                      hintText: "+1 em ataques, 2d6 de dano de fogo...",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Disponível em toda a Campanha?"),
                    subtitle: const Text("Itens globais aparecem em todas as aventuras."),
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
                    final updatedItem = itemToEdit.copyWith(
                      name: nameController.text,
                      description: descController.text,
                      type: selectedType,
                      rarity: selectedRarity,
                      mechanics: mechanicsController.text,
                      adventureId: adventureIdForCreation,
                      clearAdventureId: adventureIdForCreation == null,
                    );
                    await db.saveItem(updatedItem);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Item atualizado',
                            onUndo: () async {
                              await db.saveItem(itemToEdit);
                              ref.invalidate(
                                  itemsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveItem(updatedItem);
                              ref.invalidate(
                                  itemsProvider(adventureId));
                            },
                          ),
                        );
                  } else {
                    final adv = db.getAdventure(adventureId);
                    final campaignId = adv?.campaignId ?? adventureId;

                    final item = Item.create(
                      campaignId: campaignId,
                      adventureId: adventureIdForCreation,
                      name: nameController.text,
                      description: descController.text,
                      type: selectedType,
                      rarity: selectedRarity,
                      mechanics: mechanicsController.text,
                    );
                    await db.saveItem(item);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Item adicionado',
                            onUndo: () async {
                              await db.deleteItem(item.id);
                              ref.invalidate(
                                  itemsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveItem(item);
                              ref.invalidate(
                                  itemsProvider(adventureId));
                            },
                          ),
                        );
                  }
                  ref.invalidate(itemsProvider(adventureId));
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

class _ItemListItem extends StatelessWidget {
  final Item item;
  final WidgetRef ref;
  final String adventureId;
  final Color rarityColor;
  final IconData typeIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemListItem({
    required this.item,
    required this.ref,
    required this.adventureId,
    required this.rarityColor,
    required this.typeIcon,
    required this.onEdit,
    required this.onDelete,
  });

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
                      rarityColor.withValues(alpha: 0.2),
                  child: Icon(typeIcon, color: rarityColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.adventureId == null)
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
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
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
                if (item.adventureId != null)
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_outlined),
                    tooltip: "Promover para Campanha",
                    onPressed: () async {
                      final db = ref.read(hiveDatabaseProvider);
                      final promoted = item.copyWith(clearAdventureId: true);
                      await db.saveItem(promoted);

                      ref.read(historyProvider.notifier).recordAction(
                        HistoryAction(
                          description: "Item promovido para Campanha",
                          onUndo: () async {
                            await db.saveItem(item);
                            ref.invalidate(itemsProvider(adventureId));
                          },
                          onRedo: () async {
                            await db.saveItem(promoted);
                            ref.invalidate(itemsProvider(adventureId));
                          },
                        ),
                      );

                      ref.invalidate(itemsProvider(adventureId));
                      ref.read(unsyncedChangesProvider.notifier).state = true;
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    item.type.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(
                    item.rarity.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: rarityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      rarityColor.withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (item.mechanics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.mechanics,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
