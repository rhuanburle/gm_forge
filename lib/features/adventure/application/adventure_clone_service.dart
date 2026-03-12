import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/hive_database.dart';
import '../domain/domain.dart';
import 'adventure_providers.dart';

final adventureCloneServiceProvider = Provider<AdventureCloneService>((ref) {
  return AdventureCloneService(ref.watch(hiveDatabaseProvider));
});

class AdventureCloneService {
  final HiveDatabase _db;
  final _uuid = const Uuid();

  AdventureCloneService(this._db);

  Future<void> cloneAdventure(Adventure adventure) async {
    final newAdventureId = _uuid.v4();
    final idMap = <String, String>{}; // map of oldId -> newId

    // 1. Fetch all nested entities
    final locations = _db.getLocations(adventure.id);
    final pois = _db.getPointsOfInterest(adventure.id);
    final creatures = _db.getCreatures(adventure.id);
    final legends = _db.getLegends(adventure.id);
    final events = _db.getRandomEvents(adventure.id);
    final facts = _db.getFacts(adventure.id);
    final items = _db.getItems(adventure.id);
    final quests = _db.getQuests(adventure.id);
    final sessions = _db.getSessions(adventure.id);

    // 2. Generate new IDs map to map SmartText references later
    for (final loc in locations) {
      idMap[loc.id] = _uuid.v4();
    }
    for (final poi in pois) {
      idMap[poi.id] = _uuid.v4();
    }
    for (final cr in creatures) {
      idMap[cr.id] = _uuid.v4();
    }
    for (final leg in legends) {
      idMap[leg.id] = _uuid.v4();
    }
    for (final evt in events) {
      idMap[evt.id] = _uuid.v4();
    }
    for (final fact in facts) {
      idMap[fact.id] = _uuid.v4();
    }
    for (final item in items) {
      idMap[item.id] = _uuid.v4();
    }
    for (final quest in quests) {
      idMap[quest.id] = _uuid.v4();
    }
    for (final session in sessions) {
      idMap[session.id] = _uuid.v4();
    }

    // Helper to replace text references
    String replaceSmartText(String text) {
      if (text.isEmpty) return text;
      var newText = text;
      idMap.forEach((oldId, newId) {
        newText = newText.replaceAll(oldId, newId);
      });
      return newText;
    }

    final now = DateTime.now();

    final newAdventure = Adventure(
      id: newAdventureId,
      name: '${adventure.name} (Cópia)',
      description: adventure.description,
      conceptWhat: replaceSmartText(adventure.conceptWhat),
      conceptConflict: replaceSmartText(adventure.conceptConflict),
      sessionNotes: replaceSmartText(adventure.sessionNotes ?? ''),
      campaignId: adventure.campaignId,
      dungeonMapPath: adventure.dungeonMapPath,
      createdAt: now,
      updatedAt: now,
    );
    await _db.saveAdventure(newAdventure);

    for (var loc in locations) {
      final newId = idMap[loc.id]!;
      await _db.saveLocation(
        Location(
          id: newId,
          adventureId: newAdventureId,
          name: replaceSmartText(loc.name),
          description: replaceSmartText(loc.description),
          imagePath: loc.imagePath,
          parentLocationId: loc.parentLocationId != null
              ? (idMap[loc.parentLocationId] ?? loc.parentLocationId)
              : null,
          creatureIds: loc.creatureIds.map((id) => idMap[id] ?? id).toList(),
        ),
      );
    }

    for (var cr in creatures) {
      final newId = idMap[cr.id]!;
      await _db.saveCreature(
        Creature(
          id: newId,
          adventureId: newAdventureId,
          name: replaceSmartText(cr.name),
          type: cr.type,
          description: replaceSmartText(cr.description),
          motivation: replaceSmartText(cr.motivation),
          losingBehavior: replaceSmartText(cr.losingBehavior),
          locationIds: cr.locationIds.map((id) => idMap[id] ?? id).toList(),
          stats: replaceSmartText(cr.stats),
          imagePath: cr.imagePath,
          legacyLocation: cr.legacyLocation,
        ),
      );
    }

    for (var fact in facts) {
      final newId = idMap[fact.id]!;
      await _db.saveFact(
        Fact(
          id: newId,
          adventureId: newAdventureId,
          content: replaceSmartText(fact.content),
          sourceId: fact.sourceId != null
              ? (idMap[fact.sourceId] ?? fact.sourceId)
              : null,
          isSecret: fact.isSecret,
          tags: List.from(fact.tags),
          createdAt: now,
        ),
      );
    }

    for (var poi in pois) {
      final newId = idMap[poi.id]!;
      await _db.savePointOfInterest(
        PointOfInterest(
          id: newId,
          adventureId: newAdventureId,
          number: poi.number,
          name: replaceSmartText(poi.name),
          purpose: poi.purpose,
          firstImpression: replaceSmartText(poi.firstImpression),
          obvious: replaceSmartText(poi.obvious),
          detail: replaceSmartText(poi.detail),
          connections: List.from(poi.connections),
          treasure: replaceSmartText(poi.treasure),
          creatureIds: poi.creatureIds.map((id) => idMap[id] ?? id).toList(),
          imagePath: poi.imagePath,
          locationId: poi.locationId != null
              ? (idMap[poi.locationId] ?? poi.locationId)
              : null,
        ),
      );
    }

    for (var leg in legends) {
      final newId = idMap[leg.id]!;
      await _db.saveLegend(
        Legend(
          id: newId,
          adventureId: newAdventureId,
          text: replaceSmartText(leg.text),
          isTrue: leg.isTrue,
          source: leg.source != null ? replaceSmartText(leg.source!) : null,
          diceResult: replaceSmartText(leg.diceResult),
          relatedCreatureId: leg.relatedCreatureId != null
              ? (idMap[leg.relatedCreatureId] ?? leg.relatedCreatureId)
              : null,
          relatedLocationId: leg.relatedLocationId != null
              ? (idMap[leg.relatedLocationId] ?? leg.relatedLocationId)
              : null,
        ),
      );
    }

    for (var evt in events) {
      final newId = idMap[evt.id]!;
      await _db.saveRandomEvent(
        RandomEvent(
          id: newId,
          adventureId: newAdventureId,
          diceRange: evt.diceRange,
          eventType: evt.eventType,
          description: replaceSmartText(evt.description),
          impact: replaceSmartText(evt.impact),
        ),
      );
    }

    // Clone items
    for (final item in items) {
      final newId = idMap[item.id]!;
      await _db.saveItem(
        Item(
          id: newId,
          adventureId: newAdventureId,
          name: replaceSmartText(item.name),
          description: replaceSmartText(item.description),
          type: item.type,
          mechanics: replaceSmartText(item.mechanics),
          ownerCreatureId: item.ownerCreatureId != null
              ? (idMap[item.ownerCreatureId] ?? item.ownerCreatureId)
              : null,
          locationId: item.locationId != null
              ? (idMap[item.locationId] ?? item.locationId)
              : null,
          rarity: item.rarity,
        ),
      );
    }

    // Clone quests
    for (final quest in quests) {
      final newId = idMap[quest.id]!;
      await _db.saveQuest(
        Quest(
          id: newId,
          adventureId: newAdventureId,
          name: replaceSmartText(quest.name),
          description: replaceSmartText(quest.description),
          status: quest.status,
          giverCreatureId: quest.giverCreatureId != null
              ? (idMap[quest.giverCreatureId] ?? quest.giverCreatureId)
              : null,
          objectives: List.from(quest.objectives),
          rewardDescription: replaceSmartText(quest.rewardDescription),
          relatedLocationIds: quest.relatedLocationIds
              .map((id) => idMap[id] ?? id)
              .toList(),
        ),
      );
    }

    // Clone sessions
    for (final session in sessions) {
      final newId = idMap[session.id]!;
      await _db.saveSession(
        Session(
          id: newId,
          adventureId: newAdventureId,
          name: session.name,
          date: session.date,
          status: session.status,
          number: session.number,
          strongStart: replaceSmartText(session.strongStart),
          scenes: session.scenes.map(replaceSmartText).toList(),
          secrets: session.secrets.map(replaceSmartText).toList(),
          fantasticLocations: session.fantasticLocations.map(replaceSmartText).toList(),
          npcs: session.npcs.map(replaceSmartText).toList(),
          monsters: session.monsters.map(replaceSmartText).toList(),
          treasures: session.treasures.map(replaceSmartText).toList(),
          recap: replaceSmartText(session.recap),
        ),
      );
    }

    if (adventure.campaignId != null) {
      final campaign = _db.getCampaign(adventure.campaignId!);
      if (campaign != null) {
        final newAdventureIds = List<String>.from(campaign.adventureIds)
          ..add(newAdventureId);
        await _db.saveCampaign(
          campaign.copyWith(adventureIds: newAdventureIds),
        );
      }
    }
  }
}
