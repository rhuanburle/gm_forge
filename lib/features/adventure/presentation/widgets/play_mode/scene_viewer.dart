import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';
import 'editable_smart_text.dart';
import 'creature_detail_dialog.dart';
import '../../../../../core/widgets/smart_network_image.dart';

class SceneViewer extends ConsumerWidget {
  final String adventureId;
  const SceneViewer({super.key, required this.adventureId});

  Future<void> _updatePoi(WidgetRef ref, PointOfInterest poi) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.savePointOfInterest(poi);
    ref.invalidate(pointsOfInterestProvider(adventureId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeAdventureProvider);
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final locations = ref.watch(locationsProvider(adventureId));

    if (activeState.currentLocationId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: AppTheme.mutedForeground(context, alpha: 0.24),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecione um local para iniciar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.mutedForeground(context, alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final location = pois.firstWhere(
      (p) => p.id == activeState.currentLocationId,
      orElse: () {
        final db = ref.read(hiveDatabaseProvider);
        final adv = db.getAdventure(adventureId);
        final campaignId = adv?.campaignId ?? adventureId;
        return PointOfInterest.create(
          campaignId: campaignId,
          adventureId: adventureId,
          number: 0,
          name: 'Local Desconhecido',
          firstImpression: '',
          obvious: '',
          detail: '',
        );
      },
    );

    if (location.number == 0) {
      return const Center(child: Text("Local inválido ou excluído."));
    }

    Location? parentLocation;
    if (location.locationId != null) {
      try {
        parentLocation = locations.firstWhere(
          (loc) => loc.id == location.locationId,
        );
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parentLocation != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parentLocation.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (parentLocation.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      parentLocation.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForeground(context, alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          Row(
            children: [
              Text(
                '#${location.number}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  location.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  location.purpose.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const Divider(height: 32),

          if (location.imagePath != null && location.imagePath!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SmartNetworkImage(
                imageUrl: location.imagePath!,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],

          _SectionTitle(icon: Icons.visibility, title: 'Primeira Impressão'),
          EditableSmartText(
            text: location.firstImpression,
            adventureId: adventureId,
            label: 'Primeira Impressão',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            onSave: (val) =>
                _updatePoi(ref, location.copyWith(firstImpression: val)),
          ),
          const SizedBox(height: 24),

          _SectionTitle(icon: Icons.center_focus_strong, title: 'O Óbvio'),
          EditableSmartText(
            text: location.obvious,
            adventureId: adventureId,
            label: 'O Óbvio',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 16),
            onSave: (val) => _updatePoi(ref, location.copyWith(obvious: val)),
          ),
          const SizedBox(height: 24),

          ExpansionTile(
            title: const Text('Detalhes & Segredos'),
            leading: const Icon(Icons.search),
            childrenPadding: const EdgeInsets.all(16),
            backgroundColor: AppTheme.overlay(context),
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: EditableSmartText(
                  text: location.detail,
                  adventureId: adventureId,
                  label: 'Detalhes & Segredos',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  onSave: (val) =>
                      _updatePoi(ref, location.copyWith(detail: val)),
                ),
              ),
              if (location.id != 'null-id')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _FactList(
                      adventureId: adventureId,
                      sourceId: location.id,
                      label: 'Fatos sobre este local:',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.diamond, size: 16, color: AppTheme.accent),
                  SizedBox(width: 8),
                  Text(
                    'Tesouro / Itens',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.topLeft,
                child: EditableSmartText(
                  text: location.treasure,
                  adventureId: adventureId,
                  label: 'Tesouro / Itens',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 14),
                  onSave: (val) =>
                      _updatePoi(ref, location.copyWith(treasure: val)),
                ),
              ),
            ],
          ),

          if (location.creatureIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(icon: Icons.pets, title: 'Criaturas & NPCs'),
            _CreatureList(
              adventureId: adventureId,
              creatureIds: location.creatureIds,
            ),
          ],

          // GM Notes (session-scoped)
          const SizedBox(height: 24),
          _LocationNotesSection(locationId: location.id),

          if (location.connections.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            _SectionTitle(icon: Icons.alt_route, title: 'Saídas / Conexões'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: location.connections.map((connNumber) {
                final target = pois.firstWhere(
                  (p) => p.number == connNumber,
                  orElse: () {
                    final db = ref.read(hiveDatabaseProvider);
                    final adv = db.getAdventure(adventureId);
                    final campaignId = adv?.campaignId ?? adventureId;
                    return PointOfInterest.create(
                      campaignId: campaignId,
                      adventureId: adventureId,
                      number: connNumber,
                      name: 'Desconhecido',
                      firstImpression: '',
                      obvious: '',
                      detail: '',
                    );
                  },
                );
                return ActionChip(
                  avatar: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      '$connNumber',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  label: Text(
                    target.name.isEmpty ? 'Local #$connNumber' : target.name,
                  ),
                  onPressed: () {
                    if (target.id != 'null-id' &&
                        target.name != 'Desconhecido') {
                      ref
                          .read(activeAdventureProvider.notifier)
                          .setLocation(target.id);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatureList extends ConsumerWidget {
  final String adventureId;
  final List<String> creatureIds;

  const _CreatureList({required this.adventureId, required this.creatureIds});

  int _parseMaxHp(String stats) {
    final regex = RegExp(r'(?:HP|PV|Vida)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 10;
    }
    return 10;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCreatures = ref.watch(creaturesProvider(adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    final creatures = allCreatures
        .where((c) => creatureIds.contains(c.id))
        .toList();

    if (creatures.isEmpty) {
      return const Text('Nenhuma criatura encontrada.');
    }

    return Column(
      children: creatures.map((creature) {
        final maxHp = _parseMaxHp(creature.stats);
        final currentHp = activeState.monsterHp[creature.id] ?? maxHp;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => CreatureDetailDialog.show(
                          context,
                          creature: creature,
                          adventureId: adventureId,
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creature.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted,
                            ),
                          ),
                          Text(
                            creature.type == CreatureType.monster
                                ? 'Monstro'
                                : 'NPC',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppTheme.combat,
                          ),
                          onPressed: () {
                            ref
                                .read(activeAdventureProvider.notifier)
                                .updateMonsterHp(creature.id, currentHp - 1);
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          iconSize: 24,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$currentHp',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.success,
                          ),
                          onPressed: () {
                            ref
                                .read(activeAdventureProvider.notifier)
                                .updateMonsterHp(creature.id, currentHp + 1);
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ],
                ),
                if (creature.stats.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    creature.stats,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (creature.motivation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Quer: ${creature.motivation}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                _FactList(
                  adventureId: adventureId,
                  sourceId: creature.id,
                  label: 'Sabe sobre:',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactList extends ConsumerWidget {
  final String adventureId;
  final String sourceId;
  final String label;

  const _FactList({
    required this.adventureId,
    required this.sourceId,
    this.label = 'Fatos Conhecidos / Relacionados:',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFacts = ref.watch(factsProvider(adventureId));
    final activeState = ref.watch(activeAdventureProvider);
    final relatedFacts = allFacts.where((f) => f.sourceId == sourceId).toList();

    if (relatedFacts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...relatedFacts.map((fact) {
            final isRevealed = activeState.revealedFacts.contains(fact.id);
            final isSecret = fact.isSecret;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () {
                  ref.read(activeAdventureProvider.notifier).toggleFactRevealed(fact.id);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRevealed
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : isSecret
                            ? AppTheme.combat.withValues(alpha: 0.1)
                            : AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isRevealed
                          ? AppTheme.success.withValues(alpha: 0.4)
                          : isSecret
                              ? AppTheme.combat.withValues(alpha: 0.3)
                              : AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isRevealed
                            ? Icons.visibility
                            : isSecret
                                ? Icons.lock
                                : Icons.lightbulb_outline,
                        size: 14,
                        color: isRevealed
                            ? AppTheme.success
                            : isSecret
                                ? AppTheme.combat
                                : AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fact.content,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Tooltip(
                        message: isRevealed ? 'Revelado aos jogadores' : 'Clique para marcar como revelado',
                        child: Icon(
                          isRevealed ? Icons.check_circle : Icons.circle_outlined,
                          size: 14,
                          color: isRevealed ? AppTheme.success : AppTheme.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location notes (session-scoped sticky notes for GM)
// ---------------------------------------------------------------------------

class _LocationNotesSection extends ConsumerStatefulWidget {
  final String locationId;
  const _LocationNotesSection({required this.locationId});

  @override
  ConsumerState<_LocationNotesSection> createState() => _LocationNotesSectionState();
}

class _LocationNotesSectionState extends ConsumerState<_LocationNotesSection> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    final notes = ref.read(activeAdventureProvider).locationNotes[widget.locationId] ?? '';
    _controller = TextEditingController(text: notes);
    _isExpanded = notes.isNotEmpty;
  }

  @override
  void didUpdateWidget(_LocationNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) {
      final notes = ref.read(activeAdventureProvider).locationNotes[widget.locationId] ?? '';
      _controller.text = notes;
      _isExpanded = notes.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeAdventureProvider);
    final hasNotes = (activeState.locationNotes[widget.locationId] ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Icon(
                Icons.sticky_note_2,
                size: 20,
                color: hasNotes ? AppTheme.warning : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Notas do Mestre',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: hasNotes ? AppTheme.warning : AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Anotações rápidas sobre este local...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) {
                ref.read(activeAdventureProvider.notifier).updateLocationNote(widget.locationId, val);
              },
            ),
          ),
        ],
      ],
    );
  }
}
