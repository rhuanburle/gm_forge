import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';
import '../../widgets/campaign/lore_card.dart';
import '../../widgets/campaign/region_card.dart';

class WorldTab extends ConsumerStatefulWidget {
  final String campaignId;

  const WorldTab({super.key, required this.campaignId});

  @override
  ConsumerState<WorldTab> createState() => _WorldTabState();
}

class _WorldTabState extends ConsumerState<WorldTab> {
  String get campaignId => widget.campaignId;

  void _markUnsynced() {
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final loreEntries = ref.watch(loreEntriesProvider(campaignId));
    final regions = ref.watch(regionsProvider(campaignId));
    final consequences = ref.watch(worldConsequencesProvider(campaignId));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildConsequencesSection(context, consequences),
        const SizedBox(height: 24),
        _buildLoreSection(context, loreEntries),
        const SizedBox(height: 24),
        _buildRegionsSection(context, regions),
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
  // Helpers
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
  // Consequências do Mundo
  // ---------------------------------------------------------------------------

  Widget _buildConsequencesSection(BuildContext context, List<WorldConsequence> consequences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.bolt,
          title: 'Consequências do Mundo',
          onAdd: () => _showConsequenceDialog(context, null),
        ),
        if (consequences.isEmpty)
          _emptyState(context, 'Nenhuma consequência registrada.\nRegistre como o mundo mudou pelas ações dos jogadores.')
        else
          ...consequences.map((c) => _ConsequenceCard(
                consequence: c,
                onEdit: () => _showConsequenceDialog(context, c),
                onDelete: () => _confirmDelete(
                  context,
                  title: 'Excluir Consequência',
                  message: 'Tem certeza que deseja excluir "${c.title}"?',
                  onConfirm: () async {
                    await ref.read(hiveDatabaseProvider).deleteWorldConsequence(c.id);
                    ref.invalidate(worldConsequencesProvider(campaignId));
                    _markUnsynced();
                  },
                ),
              )),
      ],
    );
  }

  void _showConsequenceDialog(BuildContext context, WorldConsequence? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final areaCtrl = TextEditingController(text: existing?.affectedArea ?? '');
    final sessionCtrl = TextEditingController(
      text: existing?.sessionNumber != null ? existing!.sessionNumber.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nova Consequência' : 'Editar Consequência'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'O que mudou? Quais foram os efeitos?',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Área afetada',
                  hintText: 'ex: Cidade de Vorn, Guilda dos Ladrões...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sessionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sessão (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final sessionNumber = int.tryParse(sessionCtrl.text.trim());
              final db = ref.read(hiveDatabaseProvider);
              if (existing == null) {
                final c = WorldConsequence.create(
                  campaignId: campaignId,
                  title: title,
                  description: descCtrl.text.trim(),
                  affectedArea: areaCtrl.text.trim(),
                  sessionNumber: sessionNumber,
                );
                await db.saveWorldConsequence(c);
              } else {
                final updated = existing.copyWith(
                  title: title,
                  description: descCtrl.text.trim(),
                  affectedArea: areaCtrl.text.trim(),
                  sessionNumber: sessionNumber,
                  clearSessionNumber: sessionNumber == null,
                );
                await db.saveWorldConsequence(updated);
              }
              ref.invalidate(worldConsequencesProvider(campaignId));
              _markUnsynced();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Salvar'),
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
}

// ---------------------------------------------------------------------------

class _ConsequenceCard extends StatelessWidget {
  final WorldConsequence consequence;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConsequenceCard({required this.consequence, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(consequence.title,
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      if (consequence.sessionNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('S${consequence.sessionNumber}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted)),
                        ),
                    ],
                  ),
                  if (consequence.affectedArea.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(consequence.affectedArea,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                  if (consequence.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(consequence.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              iconSize: 18,
              padding: EdgeInsets.zero,
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppTheme.error), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: AppTheme.error))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
