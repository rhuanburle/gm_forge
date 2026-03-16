import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';
import 'detail_row.dart';
import 'creature_detail_dialog.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../core/widgets/smart_network_image.dart';

class LocationNavigator extends ConsumerStatefulWidget {
  final String adventureId;
  const LocationNavigator({super.key, required this.adventureId});

  @override
  ConsumerState<LocationNavigator> createState() => _LocationNavigatorState();
}

class _LocationNavigatorState extends ConsumerState<LocationNavigator> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pois = ref.watch(pointsOfInterestProvider(widget.adventureId));
    final locations = ref.watch(locationsProvider(widget.adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    final filteredPois = pois.where((poi) {
      if (_searchQuery.isEmpty) return true;
      return poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          poi.number.toString().contains(_searchQuery);
    }).toList();

    final poisByLocation = <String, List<PointOfInterest>>{};
    final orphanedPois = <PointOfInterest>[];

    for (final poi in filteredPois) {
      if (poi.locationId != null &&
          locations.any((l) => l.id == poi.locationId)) {
        poisByLocation.putIfAbsent(poi.locationId!, () => []).add(poi);
      } else {
        orphanedPois.add(poi);
      }
    }

    for (final list in poisByLocation.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }
    orphanedPois.sort((a, b) => a.number.compareTo(b.number));

    final creatures = ref.watch(creaturesProvider(widget.adventureId));
    final facts = ref.watch(factsProvider(widget.adventureId));
    final randomEvents = ref.watch(randomEventsProvider(widget.adventureId));

    final legends = ref.watch(legendsProvider(widget.adventureId));

    final filteredCreatures = creatures.where((c) {
      if (c.type != CreatureType.npc) return false;
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredMonsters = creatures.where((c) {
      if (c.type != CreatureType.monster) return false;
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Merge Facts and Legends for visibility
    final mergedFacts =
        [
          ...facts.map(
            (f) => {'type': 'fact', 'content': f.content, 'source': 'Fato'},
          ),
          ...legends.map(
            (l) => {'type': 'legend', 'content': l.text, 'source': 'Rumor'},
          ),
        ].where((item) {
          if (_searchQuery.isEmpty) return true;
          return item['content']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

    final filteredEvents = randomEvents.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.impact.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final factions = ref.watch(factionsProvider(widget.adventureId));
    final items = ref.watch(itemsProvider(widget.adventureId));
    final quests = ref.watch(questsProvider(widget.adventureId));

    final filteredFactions = factions.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredItems = items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredQuests = quests.where((q) {
      if (_searchQuery.isEmpty) return true;
      return q.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          q.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          TabBar(
            tabs: [
              _badgeTab('Locais', pois.length),
              _badgeTab('NPCs', filteredCreatures.length),
              _badgeTab('Criaturas', filteredMonsters.length),
              _badgeTab('Rumores', mergedFacts.length),
              _badgeTab('Eventos', filteredEvents.length),
              _badgeTab('Facções', filteredFactions.length),
              _badgeTab('Itens', filteredItems.length),
              _badgeTab('Missões', filteredQuests.length),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // LOCATIONS TAB
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...locations.map((location) {
                      final locationPois = poisByLocation[location.id] ?? [];
                      if (_searchQuery.isNotEmpty && locationPois.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final hasActivePoi = locationPois.any(
                        (p) => p.id == activeState.currentLocationId,
                      );

                      final visitedCount = locationPois.where((p) => p.isVisited).length;

                      return ExpansionTile(
                        key: PageStorageKey('zone-${location.id}'),
                        initiallyExpanded:
                            hasActivePoi || _searchQuery.isNotEmpty,
                        leading: const Icon(Icons.map, size: 20),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                location.name,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (locationPois.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: visitedCount == locationPois.length
                                      ? AppTheme.success.withValues(alpha: 0.15)
                                      : AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: visitedCount == locationPois.length
                                        ? AppTheme.success.withValues(alpha: 0.4)
                                        : AppTheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '$visitedCount/${locationPois.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: visitedCount == locationPois.length
                                        ? AppTheme.success
                                        : AppTheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: locationPois.isEmpty
                            ? const Text("Vazio")
                            : null,
                        children: locationPois
                            .map((poi) => _buildPoiTile(poi, activeState))
                            .toList(),
                      );
                    }),
                    if (orphanedPois.isNotEmpty) ...[
                      if (locations.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Divider(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Outros Locais',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ],
                      ...orphanedPois.map(
                        (poi) => _buildPoiTile(poi, activeState),
                      ),
                    ],
                  ],
                ),

                // NPCS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredCreatures.length,
                  itemBuilder: (context, index) {
                    final creature = filteredCreatures[index];
                    return ListTile(
                      leading: _creatureAvatar(creature, AppTheme.npc, Icons.person),
                      title: Text(creature.name),
                      subtitle: Text(
                        creature.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _showCreatureDetails(context, ref, creature);
                      },
                    );
                  },
                ),

                // CREATURES TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredMonsters.length,
                  itemBuilder: (context, index) {
                    final creature = filteredMonsters[index];
                    return ListTile(
                      leading: _creatureAvatar(creature, AppTheme.accent, Icons.pets),
                      title: Text(creature.name),
                      subtitle: Text(
                        creature.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _showCreatureDetails(context, ref, creature);
                      },
                    );
                  },
                ),

                // FACTS & RUMORS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: mergedFacts.length,
                  itemBuilder: (context, index) {
                    final item = mergedFacts[index];
                    final isFact = item['type'] == 'fact';
                    return ListTile(
                      leading: Icon(
                        isFact ? Icons.lightbulb : Icons.chat_bubble_outline,
                        color: isFact ? AppTheme.secondary : AppTheme.primary,
                      ),
                      title: Text(item['content']!),
                      subtitle: Text(
                        item['source']!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),

                // EVENTS TAB
                Column(
                  children: [
                    if (randomEvents.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.casino),
                            label: const Text('Rolar Evento'),
                            onPressed: () => _rollEvent(context, randomEvents),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppTheme.warning.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                event.diceRange,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ),
                            title: Text(event.description),
                            subtitle: Text(
                              event.impact,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              _showEventDetails(context, event);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // FACTIONS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredFactions.length,
                  itemBuilder: (context, index) {
                    final faction = filteredFactions[index];
                    return ListTile(
                      leading: Icon(
                        faction.type == FactionType.front
                            ? Icons.warning
                            : Icons.groups,
                        color: faction.type == FactionType.front
                            ? AppTheme.warning
                            : AppTheme.primary,
                      ),
                      title: Text(faction.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${faction.type.displayName} \u2022 ${faction.powerLevel.displayName}',
                          ),
                          if (faction.objectives.isNotEmpty)
                            ...faction.objectives.map(
                              (o) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: LinearProgressIndicator(
                                  value: o.maxProgress > 0
                                      ? o.currentProgress / o.maxProgress
                                      : 0,
                                  backgroundColor: AppTheme.textMuted
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _showFactionDetails(context, faction),
                    );
                  },
                ),

                // ITEMS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return ListTile(
                      leading: Icon(
                        _itemTypeIcon(item.type),
                        color: _itemRarityColor(item.rarity),
                      ),
                      title: Text(item.name),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _itemRarityColor(
                                item.rarity,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _itemRarityColor(
                                  item.rarity,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              item.rarity.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _itemRarityColor(item.rarity),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.type.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showItemDetails(context, item),
                    );
                  },
                ),

                // QUESTS TAB
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredQuests.length,
                  itemBuilder: (context, index) {
                    final quest = filteredQuests[index];
                    return ListTile(
                      leading: Icon(
                        _questStatusIcon(quest.status),
                        color: _questStatusColor(quest.status),
                      ),
                      title: Text(quest.name),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _questStatusColor(
                                quest.status,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _questStatusColor(
                                  quest.status,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              quest.status.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _questStatusColor(quest.status),
                              ),
                            ),
                          ),
                          if (quest.objectives.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${quest.objectives.where((o) => o.isComplete).length}/${quest.objectives.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _showQuestDetails(context, quest),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatureDetails(
    BuildContext context,
    WidgetRef ref,
    Creature creature,
  ) {
    CreatureDetailDialog.show(
      context,
      creature: creature,
      adventureId: widget.adventureId,
    );
  }

  void _showEventDetails(BuildContext context, RandomEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('Evento: ${event.eventType.displayName}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DetailRow('Rolagem', event.diceRange),
              const SizedBox(height: 8),
              DetailRow('Descrição', event.description),
              const SizedBox(height: 8),
              DetailRow('Impacto', event.impact),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _rollEvent(BuildContext context, List<RandomEvent> events) {
    if (events.isEmpty) return;

    final d1 = Random().nextInt(6) + 1;
    final d2 = Random().nextInt(6) + 1;
    final resultScore = int.parse('$d1$d2');

    // Find event that matches result
    RandomEvent? found;
    for (final e in events) {
      if (e.diceRange.contains('-')) {
        final parts = e.diceRange.split('-');
        final start = int.tryParse(parts[0]) ?? 0;
        final end = int.tryParse(parts[1]) ?? 0;
        if (resultScore >= start && resultScore <= end) {
          found = e;
          break;
        }
      } else if (int.tryParse(e.diceRange) == resultScore) {
        found = e;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('Resultado: $resultScore'),
          ],
        ),
        content: found != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    found.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Impacto: ${found.impact}'),
                ],
              )
            : const Text(
                'Nenhum evento correspondente encontrado para este resultado.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // --- Faction detail dialog ---
  void _showFactionDetails(BuildContext context, Faction faction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              faction.type == FactionType.front ? Icons.warning : Icons.groups,
              color: faction.type == FactionType.front
                  ? AppTheme.warning
                  : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(faction.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (faction.description.isNotEmpty) ...[
                Text(
                  faction.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
              ],
              DetailRow('Tipo', faction.type.displayName),
              const SizedBox(height: 8),
              DetailRow('Poder', faction.powerLevel.displayName),
              if (faction.stakes.isNotEmpty) ...[
                const SizedBox(height: 8),
                DetailRow('Apostas', faction.stakes),
              ],
              if (faction.objectives.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Objetivos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...faction.objectives.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.text),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: o.maxProgress > 0
                              ? o.currentProgress / o.maxProgress
                              : 0,
                          backgroundColor: AppTheme.textMuted.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        Text(
                          '${o.currentProgress}/${o.maxProgress}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (faction.dangers.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Perigos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...faction.dangers.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (d.drive.isNotEmpty) Text('Impulso: ${d.drive}'),
                        if (d.imminentDisaster.isNotEmpty)
                          Text('Desastre Iminente: ${d.imminentDisaster}'),
                      ],
                    ),
                  ),
                ),
              ],
              if (faction.allies.isNotEmpty) ...[
                const Divider(),
                DetailRow('Aliados', faction.allies.join(', ')),
              ],
              if (faction.enemies.isNotEmpty) ...[
                const SizedBox(height: 8),
                DetailRow('Inimigos', faction.enemies.join(', ')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // --- Item helpers ---
  IconData _itemTypeIcon(ItemType type) {
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

  Color _itemRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return AppTheme.textMuted;
      case ItemRarity.uncommon:
        return AppTheme.success;
      case ItemRarity.rare:
        return AppTheme.info;
      case ItemRarity.veryRare:
        return AppTheme.npc;
      case ItemRarity.legendary:
        return AppTheme.secondary;
    }
  }

  void _showItemDetails(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _itemTypeIcon(item.type),
              color: _itemRarityColor(item.rarity),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _itemRarityColor(
                        item.rarity,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _itemRarityColor(
                          item.rarity,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      item.rarity.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _itemRarityColor(item.rarity),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.type.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  item.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              if (item.mechanics.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Mecânicas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: AppTheme.overlay(context),
                  child: Text(
                    item.mechanics,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // --- Quest helpers ---
  IconData _questStatusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return Icons.circle_outlined;
      case QuestStatus.inProgress:
        return Icons.play_circle_outline;
      case QuestStatus.completed:
        return Icons.check_circle;
      case QuestStatus.failed:
        return Icons.cancel;
    }
  }

  Color _questStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return AppTheme.textMuted;
      case QuestStatus.inProgress:
        return AppTheme.info;
      case QuestStatus.completed:
        return AppTheme.success;
      case QuestStatus.failed:
        return AppTheme.error;
    }
  }

  void _showQuestDetails(BuildContext context, Quest quest) {
    showDialog(
      context: context,
      builder: (dialogContext) => _QuestDetailDialog(
        quest: quest,
        adventureId: widget.adventureId,
        questStatusIcon: _questStatusIcon,
        questStatusColor: _questStatusColor,
      ),
    );
  }

  Widget _badgeTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _creatureAvatar(Creature creature, Color fallbackColor, IconData fallbackIcon) {
    if (creature.imagePath != null && creature.imagePath!.isNotEmpty) {
      return ClipOval(
        child: SmartNetworkImage(
          imageUrl: creature.imagePath!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: fallbackColor.withValues(alpha: 0.15),
      child: Icon(fallbackIcon, size: 18, color: fallbackColor),
    );
  }

  Widget _buildPoiTile(PointOfInterest poi, ActiveAdventureState activeState) {
    final isSelected = activeState.currentLocationId == poi.id;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.textMuted.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${poi.number}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ),
      title: Text(
        poi.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            poi.purpose.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
          if (poi.creatureIds.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets,
                  size: 12,
                  color: AppTheme.combat.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 2),
                Text(
                  '${poi.creatureIds.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.combat.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          poi.isVisited ? Icons.check_circle : Icons.circle_outlined,
          color: poi.isVisited
              ? AppTheme.primary
              : AppTheme.textMuted.withValues(alpha: 0.5),
        ),
        onPressed: () async {
          final updatedPoi = poi.copyWith(isVisited: !poi.isVisited);
          await ref.read(hiveDatabaseProvider).savePointOfInterest(updatedPoi);
          ref.invalidate(pointsOfInterestProvider(widget.adventureId));
          ref.read(unsyncedChangesProvider.notifier).state = true;
        },
      ),
      onTap: () {
        ref.read(activeAdventureProvider.notifier).setLocation(poi.id);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Quest detail dialog with toggleable objectives and status
// ---------------------------------------------------------------------------

class _QuestDetailDialog extends ConsumerStatefulWidget {
  final Quest quest;
  final String adventureId;
  final IconData Function(QuestStatus) questStatusIcon;
  final Color Function(QuestStatus) questStatusColor;

  const _QuestDetailDialog({
    required this.quest,
    required this.adventureId,
    required this.questStatusIcon,
    required this.questStatusColor,
  });

  @override
  ConsumerState<_QuestDetailDialog> createState() => _QuestDetailDialogState();
}

class _QuestDetailDialogState extends ConsumerState<_QuestDetailDialog> {
  late Quest _quest;

  @override
  void initState() {
    super.initState();
    _quest = widget.quest;
  }

  Future<void> _saveQuest(Quest updated) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.saveQuest(updated);
    ref.invalidate(questsProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
    setState(() => _quest = updated);
  }

  void _toggleObjective(int index) {
    final objectives = List<QuestObjective>.from(_quest.objectives);
    objectives[index] = QuestObjective(
      text: objectives[index].text,
      isComplete: !objectives[index].isComplete,
    );
    _saveQuest(_quest.copyWith(objectives: objectives));
  }

  void _cycleStatus() {
    final statuses = QuestStatus.values;
    final nextIndex = (statuses.indexOf(_quest.status) + 1) % statuses.length;
    _saveQuest(_quest.copyWith(status: statuses[nextIndex]));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.questStatusIcon(_quest.status),
            color: widget.questStatusColor(_quest.status),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(_quest.name)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tappable status badge
            InkWell(
              onTap: _cycleStatus,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.questStatusColor(_quest.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.questStatusColor(_quest.status).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _quest.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.questStatusColor(_quest.status),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz,
                      size: 14,
                      color: widget.questStatusColor(_quest.status),
                    ),
                  ],
                ),
              ),
            ),
            if (_quest.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _quest.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_quest.objectives.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Objetivos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...List.generate(_quest.objectives.length, (i) {
                final o = _quest.objectives[i];
                return InkWell(
                  onTap: () => _toggleObjective(i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          o.isComplete ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: o.isComplete ? AppTheme.success : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            o.text,
                            style: TextStyle(
                              decoration: o.isComplete ? TextDecoration.lineThrough : null,
                              color: o.isComplete ? AppTheme.textMuted : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            if (_quest.rewardDescription.isNotEmpty) ...[
              const Divider(),
              DetailRow('Recompensa', _quest.rewardDescription),
            ],
          ],
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
}
