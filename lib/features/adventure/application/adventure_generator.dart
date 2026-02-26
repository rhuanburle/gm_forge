import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/ai_prompts.dart';
import '../../../core/ai/ai_providers.dart';
import 'adventure_providers.dart';
import '../domain/domain.dart';

final adventureGeneratorProvider = Provider<AdventureGenerator>((ref) {
  return AdventureGenerator(ref);
});

class GeneratedAdventure {
  final List<Location> locations;
  final List<PointOfInterest> pois;
  final List<Creature> creatures;
  final List<Legend> legends;
  final List<RandomEvent> events;

  const GeneratedAdventure({
    this.locations = const [],
    this.pois = const [],
    this.creatures = const [],
    this.legends = const [],
    this.events = const [],
  });

  int get totalItems =>
      locations.length +
      pois.length +
      creatures.length +
      legends.length +
      events.length;
}

class AdventureGenerator {
  final Ref _ref;

  AdventureGenerator(this._ref);

  Future<GeneratedAdventure> generate({
    required String adventureId,
    required String adventureName,
    required String conceptWhat,
    required String conceptConflict,
  }) async {
    final service = _ref.read(geminiServiceProvider);
    if (service == null) throw Exception('IA não configurada');

    final prompt = AiPrompts.buildAdventureGenerationPrompt(
      adventureName: adventureName,
      conceptWhat: conceptWhat,
      conceptConflict: conceptConflict,
    );

    final json = await service.generateStructured(prompt);

    return _parseAdventure(json, adventureId);
  }

  GeneratedAdventure _parseAdventure(
    Map<String, dynamic> json,
    String adventureId,
  ) {
    final creatures = <Creature>[];
    final creatureNameToId = <String, String>{};

    // Parse creatures first to build name→id mapping
    final creaturesJson = json['creatures'] as List<dynamic>? ?? [];
    for (final c in creaturesJson) {
      final data = c as Map<String, dynamic>;
      final creature = Creature.create(
        adventureId: adventureId,
        name: data['name'] as String? ?? 'Sem nome',
        description: data['description'] as String? ?? '',
        stats: data['stats'] as String? ?? '',
        type: (data['type'] as int?) == 1
            ? CreatureType.npc
            : CreatureType.monster,
        motivation: data['motivation'] as String? ?? '',
        losingBehavior: data['losingBehavior'] as String? ?? '',
      );
      creatures.add(creature);
      creatureNameToId[creature.name.toLowerCase()] = creature.id;
    }

    // Parse locations & POIs
    final locations = <Location>[];
    final pois = <PointOfInterest>[];

    final locationsJson = json['locations'] as List<dynamic>? ?? [];
    for (final l in locationsJson) {
      final locData = l as Map<String, dynamic>;
      final location = Location.create(
        adventureId: adventureId,
        name: locData['name'] as String? ?? 'Sem nome',
        description: locData['description'] as String? ?? '',
      );

      final poisJson = locData['pois'] as List<dynamic>? ?? [];
      final locationCreatureIds = <String>{};

      for (final p in poisJson) {
        final poiData = p as Map<String, dynamic>;

        // Resolve creature names to IDs
        final poiCreatureNames =
            (poiData['creatureNames'] as List<dynamic>?)?.cast<String>() ?? [];
        final poiCreatureIds = <String>[];
        for (final name in poiCreatureNames) {
          final id = creatureNameToId[name.toLowerCase()];
          if (id != null) {
            poiCreatureIds.add(id);
            locationCreatureIds.add(id);
          }
        }

        final purposeIndex = poiData['purpose'] as int? ?? 3;
        final poi = PointOfInterest.create(
          adventureId: adventureId,
          locationId: location.id,
          number: poiData['number'] as int? ?? pois.length + 1,
          name: poiData['name'] as String? ?? 'Sem nome',
          purpose: RoomPurpose
              .values[purposeIndex.clamp(0, RoomPurpose.values.length - 1)],
          firstImpression: poiData['firstImpression'] as String? ?? '',
          obvious: poiData['obvious'] as String? ?? '',
          detail: poiData['detail'] as String? ?? '',
          treasure: poiData['treasure'] as String? ?? '',
          creatureIds: poiCreatureIds,
        );
        pois.add(poi);

        // Update creature.locationIds with this POI
        for (final cId in poiCreatureIds) {
          final idx = creatures.indexWhere((c) => c.id == cId);
          if (idx >= 0) {
            final c = creatures[idx];
            if (!c.locationIds.contains(poi.id)) {
              creatures[idx] = c.copyWith(
                locationIds: [...c.locationIds, poi.id],
              );
            }
          }
        }
      }

      // Update location with creature IDs
      locations.add(
        location.copyWith(creatureIds: locationCreatureIds.toList()),
      );
    }

    // Parse legends
    final legends = <Legend>[];
    final legendsJson = json['legends'] as List<dynamic>? ?? [];
    for (final l in legendsJson) {
      final data = l as Map<String, dynamic>;
      legends.add(
        Legend.create(
          adventureId: adventureId,
          text: data['text'] as String? ?? '',
          isTrue: data['isTrue'] as bool? ?? true,
          source: data['source'] as String?,
          diceResult: data['diceResult'] as String? ?? '1',
        ),
      );
    }

    // Parse events
    final events = <RandomEvent>[];
    final eventsJson = json['events'] as List<dynamic>? ?? [];
    for (final e in eventsJson) {
      final data = e as Map<String, dynamic>;
      final eventTypeIndex = data['eventType'] as int? ?? 3;
      events.add(
        RandomEvent.create(
          adventureId: adventureId,
          diceRange: data['diceRange'] as String? ?? '1',
          eventType: EventType
              .values[eventTypeIndex.clamp(0, EventType.values.length - 1)],
          description: data['description'] as String? ?? '',
          impact: data['impact'] as String? ?? '',
        ),
      );
    }

    return GeneratedAdventure(
      locations: locations,
      pois: pois,
      creatures: creatures,
      legends: legends,
      events: events,
    );
  }

  Future<void> saveAll(GeneratedAdventure adventure) async {
    final db = _ref.read(hiveDatabaseProvider);

    for (final location in adventure.locations) {
      await db.saveLocation(location);
    }
    for (final poi in adventure.pois) {
      await db.savePointOfInterest(poi);
    }
    for (final creature in adventure.creatures) {
      await db.saveCreature(creature);
    }
    for (final legend in adventure.legends) {
      await db.saveLegend(legend);
    }
    for (final event in adventure.events) {
      await db.saveRandomEvent(event);
    }
  }
}
