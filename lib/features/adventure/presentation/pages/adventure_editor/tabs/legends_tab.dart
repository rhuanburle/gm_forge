import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../core/ai/ai_prompts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../../../core/widgets/import_json_dialog.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/smart_text_field.dart';
import '../widgets/section_header.dart';

class LegendsTab extends ConsumerWidget {
  final String adventureId;

  const LegendsTab({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legends = ref.watch(legendsProvider(adventureId));

    void importJson() => showImportJsonDialog(
      context: context,
      title: 'Importar Rumor / Lenda',
      exampleJson: '''{
  "text": "Dizem que o prefeito tem conexões com a guilda dos ladrões",
  "isTrue": false,
  "source": "Taberneiro bêbado",
  "diceResult": ""
}''',
      legend: 'isTrue: true=verdadeiro  false=falso/exagerado\n'
          'diceResult: rótulo opcional (texto livre, pode ficar vazio)',
      onImport: (json) async {
        final db = ref.read(hiveDatabaseProvider);
        final adv = db.getAdventure(adventureId);
        final campaignId = adv?.campaignId ?? adventureId;
        json['id'] = const Uuid().v4();
        json['campaignId'] = campaignId;
        json['adventureId'] = adventureId;
        try {
          final legend = Legend.fromJson(json);
          await db.saveLegend(legend);
          ref.invalidate(legendsProvider(adventureId));
          ref.read(unsyncedChangesProvider.notifier).state = true;
          if (context.mounted) AppSnackBar.success(context, 'Rumor importado!');
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
            icon: Icons.campaign,
            title: 'Tabela de Rumores (d${legends.isNotEmpty ? legends.length : "N"})',
            subtitle:
                '70% de dicas verdadeiras, 30% de rumores falsos/exagerados',
            trailing: IconButton(
              icon: const Icon(Icons.upload_file, size: 20),
              tooltip: 'Importar via JSON',
              color: AppTheme.textMuted,
              onPressed: importJson,
            ),
          ),
          const SizedBox(height: 16),
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
                        legends.isEmpty
                            ? 'Adicione rumores para habilitar a rolagem automática.'
                            : 'Rola d${legends.length} e seleciona automaticamente um dos ${legends.length} rumores cadastrados.',
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
                    label: Text('Rolar Rumor (d${legends.isNotEmpty ? legends.length : "N"})'),
                    onPressed: legends.isEmpty
                        ? null
                        : () {
                            final result = Random().nextInt(legends.length) + 1;
                            final selected = legends[result - 1];
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(Icons.casino, color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Text('d${legends.length} → $result'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (selected.isTrue ? AppTheme.success : AppTheme.error)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        selected.isTrue ? 'VERDADEIRO' : 'FALSO/EXAGERADO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: selected.isTrue ? AppTheme.success : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      selected.text,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                    if ((selected.source ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Fonte: ${selected.source}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
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
                        index: index,
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
    String? selectedLocationId = legendToEdit?.relatedLocationId;
    String? adventureIdForCreation = legendToEdit?.adventureId ?? adventureId;
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
                    labelText: 'Referência (opcional)',
                    hintText: 'ex: categoria, contexto...',
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
                  initialValue: selectedLocationId,
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
                  onChanged: (v) => setState(() => selectedLocationId = v),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: textController,
                  adventureId: adventureId,
                  label: 'Texto do Rumor',
                  hint: "O que os jogadores ouvirão...",
                  maxLines: 3,
                  aiFieldType: AiFieldType.legendText,
                  aiContext: {},
                  aiExtraContext: {'isTrue': isTrue.toString()},
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
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile(
                  title: const Text("Disponível em toda a Campanha?"),
                  subtitle: const Text("Rumores globais aparecem em todas as aventuras."),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final db = ref.read(hiveDatabaseProvider);

                  if (isEditing) {
                    final updatedLegend = legendToEdit.copyWith(
                      text: textController.text,
                      isTrue: isTrue,
                      source: sourceController.text.isEmpty
                          ? null
                          : sourceController.text,
                      diceResult: diceController.text,
                      relatedCreatureId: selectedCreatureId,
                      relatedLocationId: selectedLocationId,
                    );
                    await db.saveLegend(updatedLegend);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Rumor atualizado',
                            onUndo: () async {
                              await db.saveLegend(legendToEdit);
                              ref.invalidate(legendsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveLegend(updatedLegend);
                              ref.invalidate(legendsProvider(adventureId));
                            },
                          ),
                        );
                  } else {
                    final adv = db.getAdventure(adventureId);
                    final campaignId = adv?.campaignId ?? adventureId;

                    final legend = Legend.create(
                      campaignId: campaignId,
                      adventureId: adventureId,
                      text: textController.text,
                      isTrue: isTrue,
                      source: sourceController.text.isEmpty
                          ? null
                          : sourceController.text,
                      diceResult: diceController.text,
                      relatedCreatureId: selectedCreatureId,
                      relatedLocationId: selectedLocationId,
                    );
                    await db.saveLegend(legend);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'Rumor adicionado',
                            onUndo: () async {
                              await db.deleteLegend(legend.id);
                              ref.invalidate(legendsProvider(adventureId));
                            },
                            onRedo: () async {
                              await db.saveLegend(legend);
                              ref.invalidate(legendsProvider(adventureId));
                            },
                          ),
                        );
                  }
                  ref.invalidate(legendsProvider(adventureId));
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
  final int index;

  const _LegendCard({
    required this.legend,
    required this.adventureId,
    required this.onEdit,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: legend.isTrue ? AppTheme.success : AppTheme.error,
              width: 2,
            ),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          legend.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: legend.isTrue
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                legend.isTrue ? 'VERDADEIRO' : 'FALSO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: legend.isTrue ? AppTheme.success : AppTheme.error,
                ),
              ),
            ),
            if (legend.adventureId == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CAMPANHA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            if (legend.source != null && legend.source!.isNotEmpty)
              Text(
                'Fonte: ${legend.source}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (legend.adventureId != null)
              IconButton(
                icon: const Icon(Icons.drive_file_move_outlined),
                tooltip: "Promover para Campanha",
                onPressed: () async {
                  final db = ref.read(hiveDatabaseProvider);
                  final promoted = legend.copyWith(clearAdventureId: true);
                  await db.saveLegend(promoted);

                  ref.read(historyProvider.notifier).recordAction(
                    HistoryAction(
                      description: "Rumor promovido para Campanha",
                      onUndo: () async {
                        await db.saveLegend(legend);
                        ref.invalidate(legendsProvider(adventureId));
                      },
                      onRedo: () async {
                        await db.saveLegend(promoted);
                        ref.invalidate(legendsProvider(adventureId));
                      },
                    ),
                  );

                  ref.invalidate(legendsProvider(adventureId));
                  ref.read(unsyncedChangesProvider.notifier).state = true;
                },
              ),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remover Rumor?'),
                    content: const Text('Essa ação não pode ser desfeita.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Remover',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final db = ref.read(hiveDatabaseProvider);
                  await db.deleteLegend(legend.id);

                  ref
                      .read(historyProvider.notifier)
                      .recordAction(
                        HistoryAction(
                          description: 'Rumor removido',
                          onUndo: () async {
                            await db.saveLegend(legend);
                            ref.invalidate(legendsProvider(adventureId));
                          },
                          onRedo: () async {
                            await db.deleteLegend(legend.id);
                            ref.invalidate(legendsProvider(adventureId));
                          },
                        ),
                      );

                  ref.invalidate(legendsProvider(adventureId));
                  ref.read(unsyncedChangesProvider.notifier).state = true;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
