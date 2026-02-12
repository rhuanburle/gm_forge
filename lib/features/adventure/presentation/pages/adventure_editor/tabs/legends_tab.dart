import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.campaign,
            title: 'Tabela de Rumores (2d6)',
            subtitle:
                '70% de dicas verdadeiras, 30% de rumores falsos/exagerados',
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
                        'Resultados 2d6: 2-3 (raro), 4-5 (incomum), 6-8 (comum), 9-10 (incomum), 11-12 (raro)',
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
                    label: const Text('Rolar Rumor (2d6)'),
                    onPressed: () {
                      final result =
                          Random().nextInt(6) + 1 + Random().nextInt(6) + 1;
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.casino, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Resultado do Dado'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$result',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                () {
                                  if (result <= 3 || result >= 11) {
                                    return 'Raro!';
                                  } else if (result >= 6 && result <= 8) {
                                    return 'Comum';
                                  } else {
                                    return 'Incomum';
                                  }
                                }(),
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
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
                    labelText: 'Resultado 2d6',
                    hintText: 'ex: 7 ou 6-8',
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
                  initialValue: legendToEdit?.relatedLocationId,
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
                  onChanged: (v) =>
                      setState(() => legendToEdit?.relatedLocationId = v),
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: textController,
                  adventureId: adventureId,
                  label: 'Texto do Rumor',
                  hint: "O que os jogadores ouvirão...",
                  maxLines: 3,
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
                if (textController.text.isNotEmpty &&
                    diceController.text.isNotEmpty) {
                  if (isEditing) {
                    final updatedLegend = legendToEdit.copyWith(
                      text: textController.text,
                      isTrue: isTrue,
                      source: sourceController.text.isEmpty
                          ? null
                          : sourceController.text,
                      diceResult: diceController.text,
                      relatedCreatureId: selectedCreatureId,
                    );
                    await ref
                        .read(hiveDatabaseProvider)
                        .saveLegend(updatedLegend);
                  } else {
                    final legend = Legend(
                      adventureId: adventureId,
                      text: textController.text,
                      isTrue: isTrue,
                      source: sourceController.text.isEmpty
                          ? null
                          : sourceController.text,
                      diceResult: diceController.text,
                      relatedCreatureId: selectedCreatureId,
                    );
                    await ref.read(hiveDatabaseProvider).saveLegend(legend);
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

  const _LegendCard({
    required this.legend,
    required this.adventureId,
    required this.onEdit,
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
            legend.diceResult,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(legend.text),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (legend.source != null)
              Text(
                'Fonte: ${legend.source}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  await ref.read(hiveDatabaseProvider).deleteLegend(legend.id);
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
