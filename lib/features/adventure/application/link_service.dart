import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/database/hive_database.dart";
import "../domain/domain.dart";
import "adventure_providers.dart";

class LinkService {
  final HiveDatabase _db;

  LinkService(this._db);

  /// Links a creature to a POI (bidirectional).
  /// Adds [creatureId] to [poi.creatureIds] and [poi.id] to [creature.locationIds].
  Future<void> linkCreatureToPoi(
    String creatureId,
    String poiId,
    String adventureId,
  ) async {
    final pois = _db.getPointsOfInterest(adventureId);
    final creatures = _db.getCreatures(adventureId);

    final poi = _findPoi(pois, poiId);
    final creature = _findCreature(creatures, creatureId);
    if (poi == null || creature == null) return;

    if (!poi.creatureIds.contains(creatureId)) {
      await _db.savePointOfInterest(
        poi.copyWith(creatureIds: [...poi.creatureIds, creatureId]),
      );
    }
    if (!creature.locationIds.contains(poiId)) {
      await _db.saveCreature(
        creature.copyWith(locationIds: [...creature.locationIds, poiId]),
      );
    }
  }

  /// Unlinks a creature from a POI (bidirectional).
  Future<void> unlinkCreatureFromPoi(
    String creatureId,
    String poiId,
    String adventureId,
  ) async {
    final pois = _db.getPointsOfInterest(adventureId);
    final creatures = _db.getCreatures(adventureId);

    final poi = _findPoi(pois, poiId);
    final creature = _findCreature(creatures, creatureId);

    if (poi != null && poi.creatureIds.contains(creatureId)) {
      await _db.savePointOfInterest(
        poi.copyWith(
          creatureIds: poi.creatureIds.where((id) => id != creatureId).toList(),
        ),
      );
    }
    if (creature != null && creature.locationIds.contains(poiId)) {
      await _db.saveCreature(
        creature.copyWith(
          locationIds: creature.locationIds.where((id) => id != poiId).toList(),
        ),
      );
    }
  }

  /// Links a creature to a Location (bidirectional).
  Future<void> linkCreatureToLocation(
    String creatureId,
    String locationId,
    String adventureId,
  ) async {
    final locations = _db.getLocations(adventureId);
    final creatures = _db.getCreatures(adventureId);

    final location = _findLocation(locations, locationId);
    final creature = _findCreature(creatures, creatureId);
    if (location == null || creature == null) return;

    if (!location.creatureIds.contains(creatureId)) {
      await _db.saveLocation(
        location.copyWith(creatureIds: [...location.creatureIds, creatureId]),
      );
    }
    if (!creature.locationIds.contains(locationId)) {
      await _db.saveCreature(
        creature.copyWith(locationIds: [...creature.locationIds, locationId]),
      );
    }
  }

  /// Unlinks a creature from a Location (bidirectional).
  Future<void> unlinkCreatureFromLocation(
    String creatureId,
    String locationId,
    String adventureId,
  ) async {
    final locations = _db.getLocations(adventureId);
    final creatures = _db.getCreatures(adventureId);

    final location = _findLocation(locations, locationId);
    final creature = _findCreature(creatures, creatureId);

    if (location != null && location.creatureIds.contains(creatureId)) {
      await _db.saveLocation(
        location.copyWith(
          creatureIds: location.creatureIds
              .where((id) => id != creatureId)
              .toList(),
        ),
      );
    }
    if (creature != null && creature.locationIds.contains(locationId)) {
      await _db.saveCreature(
        creature.copyWith(
          locationIds: creature.locationIds
              .where((id) => id != locationId)
              .toList(),
        ),
      );
    }
  }

  /// Removes all references to [creatureId] from every POI and Location in the adventure.
  /// Called on creature deletion to maintain referential integrity.
  Future<void> cleanupCreatureReferences(
    String creatureId,
    String adventureId,
  ) async {
    final pois = _db.getPointsOfInterest(adventureId);
    for (final poi in pois) {
      if (poi.creatureIds.contains(creatureId)) {
        await _db.savePointOfInterest(
          poi.copyWith(
            creatureIds: poi.creatureIds
                .where((id) => id != creatureId)
                .toList(),
          ),
        );
      }
    }

    final locations = _db.getLocations(adventureId);
    for (final location in locations) {
      if (location.creatureIds.contains(creatureId)) {
        await _db.saveLocation(
          location.copyWith(
            creatureIds: location.creatureIds
                .where((id) => id != creatureId)
                .toList(),
          ),
        );
      }
    }
  }

  /// Removes all references to [poiId] from every Creature in the adventure.
  /// Called on POI deletion to maintain referential integrity.
  Future<void> cleanupPoiReferences(String poiId, String adventureId) async {
    final creatures = _db.getCreatures(adventureId);
    for (final creature in creatures) {
      if (creature.locationIds.contains(poiId)) {
        await _db.saveCreature(
          creature.copyWith(
            locationIds: creature.locationIds
                .where((id) => id != poiId)
                .toList(),
          ),
        );
      }
    }
  }

  /// Removes all references to [locationId] from every Creature in the adventure.
  /// Called on Location deletion to maintain referential integrity.
  Future<void> cleanupLocationReferences(
    String locationId,
    String adventureId,
  ) async {
    final creatures = _db.getCreatures(adventureId);
    for (final creature in creatures) {
      if (creature.locationIds.contains(locationId)) {
        await _db.saveCreature(
          creature.copyWith(
            locationIds: creature.locationIds
                .where((id) => id != locationId)
                .toList(),
          ),
        );
      }
    }
  }

  PointOfInterest? _findPoi(List<PointOfInterest> pois, String id) {
    try {
      return pois.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Creature? _findCreature(List<Creature> creatures, String id) {
    try {
      return creatures.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Location? _findLocation(List<Location> locations, String id) {
    try {
      return locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

final linkServiceProvider = Provider<LinkService>((ref) {
  return LinkService(ref.read(hiveDatabaseProvider));
});
