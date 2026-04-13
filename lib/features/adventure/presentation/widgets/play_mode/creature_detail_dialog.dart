import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/smart_network_image.dart';
import '../../../../../core/widgets/image_fullscreen.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';
import 'combat_tracker_panel.dart';

/// Enhanced creature/NPC detail dialog with full context:
/// facts, quests, faction membership, locations, and combat integration.
class CreatureDetailDialog extends ConsumerWidget {
  final Creature creature;
  final String adventureId;

  const CreatureDetailDialog({
    super.key,
    required this.creature,
    required this.adventureId,
  });

  static void show(BuildContext context, {required Creature creature, required String adventureId}) {
    showDialog(
      context: context,
      builder: (_) => CreatureDetailDialog(creature: creature, adventureId: adventureId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = ref.watch(factsProvider(adventureId));
    final quests = ref.watch(questsProvider(adventureId));
    final factions = ref.watch(factionsProvider(adventureId));
    final locations = ref.watch(locationsProvider(adventureId));
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final combat = ref.watch(combatProvider);

    // Related data
    final relatedFacts = facts.where((f) => f.sourceId == creature.id).toList();
    final relatedQuests = quests.where((q) => q.giverCreatureId == creature.id).toList();
    final memberFactions = factions.where((f) =>
      f.leaderCreatureId == creature.id ||
      f.memberCreatureIds.contains(creature.id)
    ).toList();

    // Locations where this creature appears
    final creatureLocations = <String>[];
    for (final loc in locations) {
      if (creature.locationIds.contains(loc.id)) {
        creatureLocations.add(loc.name);
      }
    }
    for (final poi in pois) {
      if (poi.creatureIds.contains(creature.id)) {
        creatureLocations.add('#${poi.number} ${poi.name}');
      }
    }

    final alreadyInCombat = combat.participants.any((p) => p.creatureId == creature.id);
    final isNpc = creature.type == CreatureType.npc;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isNpc ? Icons.person : Icons.pets,
            color: isNpc ? AppTheme.npc : AppTheme.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(creature.name, overflow: TextOverflow.ellipsis),
          ),
          // Inline image thumbnail (tappable for fullscreen)
          if (creature.imagePath != null && creature.imagePath!.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => showImageFullscreen(context, creature.imagePath!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SmartNetworkImage(
                  imageUrl: creature.imagePath!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          // Add to combat button
          if (!alreadyInCombat)
            IconButton(
              icon: const Icon(Icons.add_circle, size: 20),
              color: AppTheme.combat,
              tooltip: 'Adicionar ao Combate',
              onPressed: () {
                final maxHp = _parseHp(creature.stats);
                final ac = _parseAc(creature.stats);
                ref.read(combatProvider.notifier).addParticipant(
                  CombatParticipant.create(
                    name: creature.name,
                    currentHp: maxHp,
                    maxHp: maxHp,
                    armorClass: ac,
                    isPlayerCharacter: false,
                    creatureId: creature.id,
                  ),
                );
                AppSnackBar.success(context, '${creature.name} adicionado ao combate!');
              },
            )
          else
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check_circle, size: 18, color: AppTheme.success),
            ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Description
              if (creature.description.isNotEmpty) ...[
                Text(
                  creature.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Core info
              _InfoSection(
                children: [
                  if (creature.motivation.isNotEmpty)
                    _IconRow(
                      icon: Icons.psychology,
                      label: 'Motivação',
                      value: creature.motivation,
                      color: AppTheme.secondary,
                    ),
                  if (creature.losingBehavior.isNotEmpty)
                    _IconRow(
                      icon: Icons.trending_down,
                      label: 'Ao Perder',
                      value: creature.losingBehavior,
                      color: AppTheme.combat,
                    ),
                  if (creature.roleplayNotes.isNotEmpty)
                    _IconRow(
                      icon: Icons.theater_comedy,
                      label: 'Roleplay',
                      value: creature.roleplayNotes,
                      color: AppTheme.npc,
                    ),
                ],
              ),

              // Conversation topics
              if (creature.conversationTopics.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(icon: Icons.chat_bubble, label: 'Tópicos de Conversa', color: AppTheme.npc),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: creature.conversationTopics.map((topic) => Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    label: Text(topic, style: const TextStyle(fontSize: 10, color: AppTheme.npc)),
                    side: BorderSide(color: AppTheme.npc.withValues(alpha: 0.4)),
                    backgroundColor: AppTheme.npc.withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],

              // Stats
              if (creature.stats.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assessment, size: 14, color: AppTheme.secondary),
                          SizedBox(width: 4),
                          Text(
                            'Ficha / Stats',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        creature.stats,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],

              // Locations
              if (creatureLocations.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ChipSection(
                  icon: Icons.place,
                  label: 'Locais',
                  color: AppTheme.primary,
                  items: creatureLocations,
                ),
              ],

              // Facts (what they know)
              if (relatedFacts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionHeader(icon: Icons.lightbulb, label: 'O que sabe', color: AppTheme.discovery),
                const SizedBox(height: 4),
                ...relatedFacts.map((fact) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (fact.isSecret
                        ? AppTheme.combat
                        : AppTheme.discovery
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (fact.isSecret
                          ? AppTheme.combat
                          : AppTheme.discovery
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fact.isSecret)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.lock, size: 12, color: AppTheme.combat),
                        ),
                      Expanded(
                        child: Text(
                          fact.content,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              // Quests given by this NPC
              if (relatedQuests.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionHeader(icon: Icons.assignment, label: 'Missões', color: AppTheme.quest),
                const SizedBox(height: 4),
                ...relatedQuests.map((quest) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    quest.status == QuestStatus.completed
                        ? Icons.check_circle
                        : quest.status == QuestStatus.inProgress
                            ? Icons.play_circle_outline
                            : Icons.circle_outlined,
                    size: 18,
                    color: quest.status == QuestStatus.completed
                        ? AppTheme.success
                        : quest.status == QuestStatus.inProgress
                            ? AppTheme.info
                            : AppTheme.textMuted,
                  ),
                  title: Text(quest.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    quest.status.displayName,
                    style: const TextStyle(fontSize: 10),
                  ),
                )),
              ],

              // Faction membership
              if (memberFactions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionHeader(icon: Icons.groups, label: 'Facções', color: AppTheme.faction),
                const SizedBox(height: 4),
                ...memberFactions.map((faction) {
                  final isLeader = faction.leaderCreatureId == creature.id;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      faction.type == FactionType.front ? Icons.warning : Icons.groups,
                      size: 18,
                      color: AppTheme.faction,
                    ),
                    title: Text(faction.name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      isLeader ? 'Líder' : 'Membro',
                      style: TextStyle(
                        fontSize: 10,
                        color: isLeader ? AppTheme.secondary : AppTheme.textMuted,
                        fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  int _parseHp(String stats) {
    final regex = RegExp(r'(?:HP|PV|Vida)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    return match != null ? (int.tryParse(match.group(1) ?? '') ?? 10) : 10;
  }

  int _parseAc(String stats) {
    final regex = RegExp(r'(?:CA|AC|Armadura)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    return match != null ? (int.tryParse(match.group(1) ?? '') ?? 10) : 10;
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.whereType<_IconRow>().expand<Widget>((w) => [w, const SizedBox(height: 6)]).toList(),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IconRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                ),
                TextSpan(text: value, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<String> items;

  const _ChipSection({
    required this.icon,
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: icon, label: label, color: color),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items.map((item) => Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            label: Text(item, style: TextStyle(fontSize: 10, color: color)),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            backgroundColor: color.withValues(alpha: 0.1),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }
}
