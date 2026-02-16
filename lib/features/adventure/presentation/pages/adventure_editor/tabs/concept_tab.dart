import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/debouncer.dart';
import '../../../../../../core/auth/auth_service.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/widgets/smart_network_image.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/smart_text_field.dart';
import '../widgets/section_header.dart';

class ConceptTab extends ConsumerStatefulWidget {
  final Adventure adventure;

  const ConceptTab({super.key, required this.adventure});

  @override
  ConsumerState<ConceptTab> createState() => _ConceptTabState();
}

class _ConceptTabState extends ConsumerState<ConceptTab> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _whatController;
  late TextEditingController _conflictController;
  late TextEditingController _nextHintController;
  late TextEditingController _tagsController;
  late TextEditingController _dungeonMapController;
  String? _selectedCampaignId;

  // Controllers for secondary conflicts
  final List<TextEditingController> _secondaryConflictControllers = [];

  final _debouncer = Debouncer(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adventure.name);
    _descController = TextEditingController(text: widget.adventure.description);
    _whatController = TextEditingController(text: widget.adventure.conceptWhat);
    _conflictController = TextEditingController(
      text: widget.adventure.conceptConflict,
    );
    _nextHintController = TextEditingController(
      text: widget.adventure.nextAdventureHint,
    );
    _tagsController = TextEditingController(
      text: widget.adventure.tags.join(', '),
    );
    _dungeonMapController = TextEditingController(
      text: widget.adventure.dungeonMapPath,
    );
    _selectedCampaignId = widget.adventure.campaignId;

    // Initialize secondary conflicts
    for (final conflict in widget.adventure.conceptSecondaryConflicts) {
      final ctrl = TextEditingController(text: conflict);
      ctrl.addListener(_onFieldChanged);
      _secondaryConflictControllers.add(ctrl);
    }

    _nameController.addListener(_onFieldChanged);
    _descController.addListener(_onFieldChanged);
    _whatController.addListener(_onFieldChanged);
    _conflictController.addListener(_onFieldChanged);
    _nextHintController.addListener(_onFieldChanged);
    _tagsController.addListener(_onFieldChanged);
    _dungeonMapController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _nameController.dispose();
    _descController.dispose();
    _whatController.dispose();
    _conflictController.dispose();
    _nextHintController.dispose();
    _tagsController.dispose();
    _dungeonMapController.dispose();
    for (final ctrl in _secondaryConflictControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    _debouncer.run(() => _save(silent: true));
  }

  void _addSecondaryConflict() {
    final ctrl = TextEditingController();
    ctrl.addListener(_onFieldChanged);
    setState(() {
      _secondaryConflictControllers.add(ctrl);
    });
    // Mark unsynced immediately or wait for text input?
    // Better wait for text input, but adding a field technically changes nothing in the model until saved.
    // However, if we save the list of strings, an empty string might be added.
  }

  void _removeSecondaryConflict(int index) {
    setState(() {
      final ctrl = _secondaryConflictControllers.removeAt(index);
      ctrl.dispose();
    });
    _onFieldChanged();
  }

  Future<void> _save({bool silent = false}) async {
    final updatedAdventure = widget.adventure.copyWith(
      name: _nameController.text,
      description: _descController.text,
      conceptWhat: _whatController.text,
      conceptConflict: _conflictController.text,
      nextAdventureHint: _nextHintController.text,
      dungeonMapPath: _dungeonMapController.text.isEmpty
          ? null
          : _dungeonMapController.text,
      campaignId: _selectedCampaignId,
      clearCampaignId: _selectedCampaignId == null,
      tags: _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      conceptSecondaryConflicts: _secondaryConflictControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList(),
    );

    await ref.read(hiveDatabaseProvider).saveAdventure(updatedAdventure);
    ref.read(adventureListProvider.notifier).refresh();

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null && !user.isAnonymous) {
      ref.read(unsyncedChangesProvider.notifier).state = true;
    }

    if (mounted && !silent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Salvo!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.lightbulb,
            title: 'A Semente (Conceito Central)',
            subtitle: 'Defina o coração do seu Local de Aventura',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Aventura',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              prefixIcon: Icon(Icons.description),
              hintText: 'Uma breve visão geral para sua referência...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCampaignId,
            decoration: const InputDecoration(
              labelText: 'Campanha',
              prefixIcon: Icon(Icons.bookmark),
              hintText: 'Vincular a uma campanha (opcional)',
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Nenhuma (Independente)'),
              ),
              ...campaigns.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCampaignId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              prefixIcon: Icon(Icons.label),
              hintText: 'tags, separadas, por, vírgula',
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qual é o local?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'ex: Um templo submerso, uma estação espacial abandonada, uma mansão assombrada',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: _whatController,
                  adventureId: widget.adventure.id,
                  label: 'Descrição do Local',
                  hint: 'Descreva o local...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conflitos',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.secondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "O conflito principal e outros secundários.",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _addSecondaryConflict,
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.primary,
                      ),
                      tooltip: 'Adicionar Conflito Secundário',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: _conflictController,
                  adventureId: widget.adventure.id,
                  label: 'Conflito Principal',
                  hint:
                      'ex: Duas facções lutam por um artefato, uma maldição desperta...',
                  maxLines: 3,
                ),
                if (_secondaryConflictControllers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Conflitos Secundários',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_secondaryConflictControllers.length, (
                    index,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SmartTextField(
                              controller: _secondaryConflictControllers[index],
                              adventureId: widget.adventure.id,
                              label: 'Conflito Secundário #${index + 1}',
                              hint: 'Outro problema acontecendo...',
                              maxLines: 2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            onPressed: () => _removeSecondaryConflict(index),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gancho Narrativo (A "Ponta Solta")',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  "Uma dica ou pista apontando para a próxima aventura na campanha.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: _nextHintController,
                  adventureId: widget.adventure.id,
                  label: 'Gancho Narrativo',
                  hint:
                      'ex: Um mapa encontrado no corpo do capitão aponta para...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.parchmentDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapa da Masmorra',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Imagem do mapa completo (onde cada Local individual é uma sala).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dungeonMapController,
                  decoration: const InputDecoration(
                    labelText: 'URL ou Caminho da Imagem',
                    hintText: 'https://exemplo.com/mapa-masmorra.png',
                    prefixIcon: Icon(Icons.map),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_dungeonMapController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartNetworkImage(
                      imageUrl: _dungeonMapController.text,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Conceito'),
            ),
          ),
        ],
      ),
    );
  }
}
