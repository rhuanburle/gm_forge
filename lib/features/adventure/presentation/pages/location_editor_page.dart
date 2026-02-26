import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/ai_prompts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../core/history/history_service.dart';
import '../../application/adventure_providers.dart';
import '../../application/link_service.dart';
import '../../domain/domain.dart';
import '../widgets/smart_text_field.dart';
import 'adventure_editor/widgets/section_header.dart';

class LocationEditorPage extends ConsumerStatefulWidget {
  final String adventureId;
  final String locationId;

  const LocationEditorPage({
    super.key,
    required this.adventureId,
    required this.locationId,
  });

  @override
  ConsumerState<LocationEditorPage> createState() => _LocationEditorPageState();
}

class _LocationEditorPageState extends ConsumerState<LocationEditorPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  String? _loadedLocationId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _imageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationsProvider(widget.adventureId));
    final pois = ref.watch(pointsOfInterestProvider(widget.adventureId));

    // Find the location safely
    final locationIndex = locations.indexWhere(
      (l) => l.id == widget.locationId,
    );
    if (locationIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Local não encontrado')),
        body: const Center(child: Text('Este local não existe mais.')),
      );
    }
    final location = locations[locationIndex];

    // Sync controllers on first load or when location data changes externally
    if (_loadedLocationId != location.id) {
      _loadedLocationId = location.id;
      _nameController.text = location.name;
      _descController.text = location.description;
      _imageController.text = location.imagePath ?? '';
    }

    // Filter POIs for this location
    final locationPois = pois
        .where((p) => p.locationId == widget.locationId)
        .toList();
    locationPois.sort((a, b) => a.number.compareTo(b.number));

    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveLocation(location),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.info,
              title: 'Informações Básicas',
              subtitle: 'Defina o ambiente geral',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Local',
                hintText: 'ex: O Salão Principal',
              ),
              onChanged: (_) => _markUnsynced(),
            ),
            const SizedBox(height: 16),
            SmartTextField(
              controller: _descController,
              adventureId: widget.adventureId,
              label: 'Descrição do Ambiente',
              hint: 'Iluminação, cheiros, sons...',
              maxLines: 3,
              onChanged: (value, _) => _markUnsynced(),
              aiFieldType: AiFieldType.locationDescription,
              aiContext: {'locationName': _nameController.text},
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'URL da Imagem (Opcional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image),
              ),
              onChanged: (_) => _markUnsynced(),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(
                  icon: Icons.place,
                  title: 'Pontos de Interesse (POIs)',
                  subtitle: 'Salas, enigmas e perigos',
                ),
                IconButton(
                  onPressed: () => _showPoiDialog(context, null),
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                  tooltip: 'Adicionar POI',
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (locationPois.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum ponto de interesse neste local.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => _showPoiDialog(context, null),
                      child: const Text('Criar o Primeiro POI'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: locationPois.length,
                itemBuilder: (context, index) {
                  final poi = locationPois[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPoiColor(
                          poi.purpose,
                        ).withValues(alpha: 0.2),
                        child: Text(
                          '${poi.number}',
                          style: TextStyle(
                            color: _getPoiColor(poi.purpose),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(poi.name),
                      subtitle: Text(poi.purpose.displayName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showPoiDialog(context, poi),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            onPressed: () => _deletePoi(poi),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                'Primeira Impressão',
                                poi.firstImpression,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow('O Óbvio', poi.obvious),
                              const SizedBox(height: 8),
                              _InfoRow('Detalhes/Segredos', poi.detail),
                              if (poi.treasure.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _InfoRow('Tesouro', poi.treasure),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _saveLocation(location),
        child: const Icon(Icons.save),
      ),
    );
  }

  Color _getPoiColor(RoomPurpose purpose) {
    switch (purpose) {
      case RoomPurpose.danger:
        return AppTheme.error;
      case RoomPurpose.rest:
        return AppTheme.success;
      case RoomPurpose.puzzle:
        return AppTheme.accent;
      case RoomPurpose.narrative:
        return AppTheme.primary;
    }
  }

  void _markUnsynced() {
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  Future<void> _saveLocation(Location location) async {
    final updatedLocation = location.copyWith(
      name: _nameController.text,
      description: _descController.text,
      imagePath: _imageController.text,
    );

    final db = ref.read(hiveDatabaseProvider);
    await db.saveLocation(updatedLocation);

    ref
        .read(historyProvider.notifier)
        .recordAction(
          HistoryAction(
            description: 'Local atualizado',
            onUndo: () async {
              await db.saveLocation(location);
              ref.invalidate(locationsProvider(widget.adventureId));
            },
            onRedo: () async {
              await db.saveLocation(updatedLocation);
              ref.invalidate(locationsProvider(widget.adventureId));
            },
          ),
        );

    ref.invalidate(locationsProvider(widget.adventureId));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Local salvo com sucesso!')));
    }
  }

  Future<void> _deletePoi(PointOfInterest poi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover POI?'),
        content: const Text(
          'Isso removerá permanentemente este ponto de interesse.',
        ),
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
      await db.deletePointOfInterest(poi.id);

      ref
          .read(historyProvider.notifier)
          .recordAction(
            HistoryAction(
              description: 'PDI removido',
              onUndo: () async {
                await db.savePointOfInterest(poi);
                ref.invalidate(pointsOfInterestProvider(widget.adventureId));
              },
              onRedo: () async {
                await db.deletePointOfInterest(poi.id);
                ref.invalidate(pointsOfInterestProvider(widget.adventureId));
              },
            ),
          );

      ref.invalidate(pointsOfInterestProvider(widget.adventureId));
      _markUnsynced();
    }
  }

  void _showPoiDialog(BuildContext context, PointOfInterest? poiToEdit) {
    final isEditing = poiToEdit != null;
    final numberCtrl = TextEditingController(
      text: isEditing ? poiToEdit.number.toString() : '',
    );
    final nameCtrl = TextEditingController(text: poiToEdit?.name);
    final firstImpressionCtrl = TextEditingController(
      text: poiToEdit?.firstImpression,
    );
    final obviousCtrl = TextEditingController(text: poiToEdit?.obvious);
    final detailCtrl = TextEditingController(text: poiToEdit?.detail);
    final treasureCtrl = TextEditingController(text: poiToEdit?.treasure);

    // Auto-increment number if new
    if (!isEditing) {
      final pois = ref.read(pointsOfInterestProvider(widget.adventureId));
      int maxNum = 0;
      for (var p in pois) {
        if (p.number > maxNum) maxNum = p.number;
      }
      numberCtrl.text = (maxNum + 1).toString();
    }

    RoomPurpose selectedPurpose = poiToEdit?.purpose ?? RoomPurpose.narrative;

    // Creature multi-select
    final allCreatures = ref.read(creaturesProvider(widget.adventureId));
    final selectedCreatureIds = Set<String>.from(poiToEdit?.creatureIds ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar POI' : 'Novo Ponto de Interesse'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: numberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nº'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoomPurpose>(
                  initialValue: selectedPurpose,
                  decoration: const InputDecoration(labelText: 'Tipo de Sala'),
                  items: RoomPurpose.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedPurpose = val);
                  },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: firstImpressionCtrl,
                  adventureId: widget.adventureId,
                  label: 'Primeira Impressão (Sentidos)',
                  hint: 'O que eles veem/sentem ao chegar?',
                  maxLines: 2,
                  aiFieldType: AiFieldType.poiFirstImpression,
                  aiContext: {
                    'locationName': _nameController.text,
                    'poiName': nameCtrl.text,
                    'poiPurpose': selectedPurpose.displayName,
                  },
                  aiExtraContext: {'poiPurpose': selectedPurpose.displayName},
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: obviousCtrl,
                  adventureId: widget.adventureId,
                  label: 'O Óbvio',
                  hint: 'O que está claramente na sala?',
                  maxLines: 2,
                  aiFieldType: AiFieldType.poiObvious,
                  aiContext: {
                    'locationName': _nameController.text,
                    'poiName': nameCtrl.text,
                    'poiPurpose': selectedPurpose.displayName,
                  },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: detailCtrl,
                  adventureId: widget.adventureId,
                  label: 'Detalhes/Segredos',
                  hint: 'O que descobrem ao investigar?',
                  maxLines: 3,
                  aiFieldType: AiFieldType.poiDetail,
                  aiContext: {
                    'locationName': _nameController.text,
                    'poiName': nameCtrl.text,
                    'poiPurpose': selectedPurpose.displayName,
                  },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: treasureCtrl,
                  adventureId: widget.adventureId,
                  label: 'Tesouro (Opcional)',
                  hint: 'O que encontram de valor?',
                  maxLines: 1,
                  aiFieldType: AiFieldType.poiTreasure,
                  aiContext: {
                    'locationName': _nameController.text,
                    'poiName': nameCtrl.text,
                    'poiPurpose': selectedPurpose.displayName,
                  },
                ),
                if (allCreatures.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.pets, size: 16, color: AppTheme.accent),
                        const SizedBox(width: 6),
                        const Text(
                          'Criaturas neste POI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: allCreatures.map((creature) {
                      final isSelected = selectedCreatureIds.contains(
                        creature.id,
                      );
                      return FilterChip(
                        avatar: Icon(
                          creature.type == CreatureType.npc
                              ? Icons.person
                              : Icons.pets,
                          size: 14,
                        ),
                        label: Text(
                          creature.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              selectedCreatureIds.add(creature.id);
                            } else {
                              selectedCreatureIds.remove(creature.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
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
                if (nameCtrl.text.isNotEmpty && numberCtrl.text.isNotEmpty) {
                  final number = int.tryParse(numberCtrl.text) ?? 0;
                  final db = ref.read(hiveDatabaseProvider);
                  final linkService = ref.read(linkServiceProvider);

                  if (isEditing) {
                    // Determine added/removed creatures
                    final oldCreatureIds = Set<String>.from(
                      poiToEdit.creatureIds,
                    );
                    final added = selectedCreatureIds.difference(
                      oldCreatureIds,
                    );
                    final removed = oldCreatureIds.difference(
                      selectedCreatureIds,
                    );

                    final updatedPoi = poiToEdit.copyWith(
                      number: number,
                      name: nameCtrl.text,
                      purpose: selectedPurpose,
                      firstImpression: firstImpressionCtrl.text,
                      obvious: obviousCtrl.text,
                      detail: detailCtrl.text,
                      treasure: treasureCtrl.text,
                      creatureIds: selectedCreatureIds.toList(),
                    );
                    await db.savePointOfInterest(updatedPoi);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'PDI atualizado',
                            onUndo: () async {
                              await db.savePointOfInterest(poiToEdit);
                              ref.invalidate(
                                pointsOfInterestProvider(widget.adventureId),
                              );
                            },
                            onRedo: () async {
                              await db.savePointOfInterest(updatedPoi);
                              ref.invalidate(
                                pointsOfInterestProvider(widget.adventureId),
                              );
                            },
                          ),
                        );

                    // Sync bidirectional links
                    for (final id in added) {
                      await linkService.linkCreatureToPoi(
                        id,
                        updatedPoi.id,
                        widget.adventureId,
                      );
                    }
                    for (final id in removed) {
                      await linkService.unlinkCreatureFromPoi(
                        id,
                        updatedPoi.id,
                        widget.adventureId,
                      );
                    }
                  } else {
                    final newPoi = PointOfInterest.create(
                      adventureId: widget.adventureId,
                      locationId: widget.locationId,
                      number: number,
                      name: nameCtrl.text,
                      purpose: selectedPurpose,
                      firstImpression: firstImpressionCtrl.text,
                      obvious: obviousCtrl.text,
                      detail: detailCtrl.text,
                      treasure: treasureCtrl.text,
                      creatureIds: selectedCreatureIds.toList(),
                    );
                    await db.savePointOfInterest(newPoi);

                    ref
                        .read(historyProvider.notifier)
                        .recordAction(
                          HistoryAction(
                            description: 'PDI criado',
                            onUndo: () async {
                              await db.deletePointOfInterest(newPoi.id);
                              ref.invalidate(
                                pointsOfInterestProvider(widget.adventureId),
                              );
                            },
                            onRedo: () async {
                              await db.savePointOfInterest(newPoi);
                              ref.invalidate(
                                pointsOfInterestProvider(widget.adventureId),
                              );
                            },
                          ),
                        );

                    // Sync bidirectional links for new POI
                    for (final id in selectedCreatureIds) {
                      await linkService.linkCreatureToPoi(
                        id,
                        newPoi.id,
                        widget.adventureId,
                      );
                    }
                  }

                  ref.invalidate(pointsOfInterestProvider(widget.adventureId));
                  ref.invalidate(creaturesProvider(widget.adventureId));
                  _markUnsynced();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
