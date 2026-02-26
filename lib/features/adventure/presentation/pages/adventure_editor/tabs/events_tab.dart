import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/ai/ai_prompts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/history/history_service.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/smart_text_field.dart';
import '../widgets/section_header.dart';

class EventsTab extends ConsumerWidget {
  final String adventureId;

  const EventsTab({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(randomEventsProvider(adventureId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.casino,
            title: 'Tabela de Eventos (d66)',
            subtitle: 'Encontros aleatórios para apimentar a exploração',
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
                        'Role 2d6 (dezena e unidade) para obter resultados de 11 a 66.',
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
                    label: const Text('Rolar Evento (d66)'),
                    onPressed: () {
                      final d1 = Random().nextInt(6) + 1;
                      final d2 = Random().nextInt(6) + 1;
                      final result = int.parse('$d1$d2');

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.casino, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Resultado d66'),
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
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.casino_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum evento criado. Crie tabelas de encontros aleatórios.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              event.diceRange,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          title: Text(event.description),
                          subtitle: Text(
                            'Impacto: ${event.impact}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEventDialog(
                                  context,
                                  ref,
                                  eventToEdit: event,
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
                                      title: const Text('Remover Evento?'),
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
                                    final db = ref.read(hiveDatabaseProvider);
                                    await db.deleteRandomEvent(event.id);

                                    ref
                                        .read(historyProvider.notifier)
                                        .recordAction(
                                          HistoryAction(
                                            description: 'Evento removido',
                                            onUndo: () async {
                                              await db.saveRandomEvent(event);
                                              ref.invalidate(
                                                randomEventsProvider(
                                                  adventureId,
                                                ),
                                              );
                                            },
                                            onRedo: () async {
                                              await db.deleteRandomEvent(
                                                event.id,
                                              );
                                              ref.invalidate(
                                                randomEventsProvider(
                                                  adventureId,
                                                ),
                                              );
                                            },
                                          ),
                                        );

                                    ref.invalidate(
                                      randomEventsProvider(adventureId),
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
              onPressed: () => _showEventDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Evento'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDialog(
    BuildContext context,
    WidgetRef ref, {
    RandomEvent? eventToEdit,
  }) {
    final isEditing = eventToEdit != null;
    final descController = TextEditingController(
      text: eventToEdit?.description,
    );
    final diceController = TextEditingController(text: eventToEdit?.diceRange);
    final impactController = TextEditingController(text: eventToEdit?.impact);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Evento' : 'Adicionar Evento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diceController,
                decoration: const InputDecoration(
                  labelText: 'Resultado (d66)',
                  hintText: 'ex: 11-16 ou 23',
                ),
              ),
              const SizedBox(height: 16),
              SmartTextField(
                controller: descController,
                adventureId: adventureId,
                label: 'Descrição do Evento',
                hint: "O que acontece?",
                maxLines: 3,
                aiFieldType: AiFieldType.eventDescription,
                aiContext: {},
                aiExtraContext: {
                  'eventType': eventToEdit?.eventType.displayName ?? '',
                },
              ),
              const SizedBox(height: 16),
              SmartTextField(
                controller: impactController,
                adventureId: adventureId,
                label: 'Impacto Mecânico/Narrativo',
                hint: 'ex: PJ perde 1d4 PV, -1 no próximo teste',
                maxLines: 2,
                aiFieldType: AiFieldType.eventImpact,
                aiContext: {},
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
              if (descController.text.isNotEmpty &&
                  diceController.text.isNotEmpty) {
                final db = ref.read(hiveDatabaseProvider);

                if (isEditing) {
                  final updatedEvent = eventToEdit.copyWith(
                    description: descController.text,
                    diceRange: diceController.text,
                    impact: impactController.text,
                  );
                  await db.saveRandomEvent(updatedEvent);

                  ref
                      .read(historyProvider.notifier)
                      .recordAction(
                        HistoryAction(
                          description: 'Evento atualizado',
                          onUndo: () async {
                            await db.saveRandomEvent(eventToEdit);
                            ref.invalidate(randomEventsProvider(adventureId));
                          },
                          onRedo: () async {
                            await db.saveRandomEvent(updatedEvent);
                            ref.invalidate(randomEventsProvider(adventureId));
                          },
                        ),
                      );
                } else {
                  final event = RandomEvent.create(
                    adventureId: adventureId,
                    description: descController.text,
                    diceRange: diceController.text,
                    impact: impactController.text,
                  );
                  await db.saveRandomEvent(event);

                  ref
                      .read(historyProvider.notifier)
                      .recordAction(
                        HistoryAction(
                          description: 'Evento adicionado',
                          onUndo: () async {
                            await db.deleteRandomEvent(event.id);
                            ref.invalidate(randomEventsProvider(adventureId));
                          },
                          onRedo: () async {
                            await db.saveRandomEvent(event);
                            ref.invalidate(randomEventsProvider(adventureId));
                          },
                        ),
                      );
                }
                ref.invalidate(randomEventsProvider(adventureId));
                ref.read(unsyncedChangesProvider.notifier).state = true;
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Adicionar'),
          ),
        ],
      ),
    );
  }
}
