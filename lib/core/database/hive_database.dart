import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../features/adventure/domain/domain.dart';

class HiveDatabase {
  static const String _adventuresBox = 'adventures';
  static const String _legendsBox = 'legends';
  static const String _poisBox = 'points_of_interest';
  static const String _eventsBox = 'random_events';
  static const String _creaturesBox = 'creatures';
  static const String _campaignsBox = 'campaigns';
  static const String _locationsBox = 'locations';
  static const String _factsBox = 'facts';
  static const String _sessionEntriesBox = 'session_entries';
  static const String _settingsBox = 'settings';

  static HiveDatabase? _instance;

  static HiveDatabase get instance {
    if (_instance == null) {
      throw StateError('HiveDatabase not initialized. Call init() first.');
    }
    return _instance!;
  }

  static Future<HiveDatabase> init() async {
    if (_instance != null) return _instance!;

    await Hive.initFlutter();

    await Hive.openBox<dynamic>(_settingsBox);
    await Hive.openBox<Map>(_adventuresBox);
    await Hive.openBox<Map>(_legendsBox);
    await Hive.openBox<Map>(_poisBox);
    await Hive.openBox<Map>(_eventsBox);
    await Hive.openBox<Map>(_creaturesBox);
    await Hive.openBox<Map>(_campaignsBox);
    await Hive.openBox<Map>(_locationsBox);
    await Hive.openBox<Map>(_factsBox);
    await Hive.openBox<Map>(_sessionEntriesBox);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';
      final settingsBox = Hive.box<dynamic>(_settingsBox);
      final storedVersion = settingsBox.get('appVersion') as String?;

      if (storedVersion != null && storedVersion != currentVersion) {
        await Hive.box<Map>(_adventuresBox).clear();
        await Hive.box<Map>(_legendsBox).clear();
        await Hive.box<Map>(_poisBox).clear();
        await Hive.box<Map>(_eventsBox).clear();
        await Hive.box<Map>(_creaturesBox).clear();
        await Hive.box<Map>(_campaignsBox).clear();
        await Hive.box<Map>(_locationsBox).clear();
        await Hive.box<Map>(_factsBox).clear();
        await Hive.box<Map>(_sessionEntriesBox).clear();
      }

      await settingsBox.put('appVersion', currentVersion);
    } catch (_) {
      // Version check is best-effort; never block app startup
    }

    _instance = HiveDatabase._();
    await _instance!._runMigrations();
    return _instance!;
  }

  HiveDatabase._();

  Future<void> _runMigrations() async {
    final migrationDone =
        _settings.get('migration_v2_bidirectional_links') as bool? ?? false;
    if (migrationDone) return;

    try {
      // Step 1: Re-save all creatures to convert old format to new format.
      // Old creatures have "location" (String?) field — fromJson preserves it
      // as legacyLocation. The new toJson writes "locationIds" instead.
      // This step ensures the stored JSON is in the new format.
      final creaturesBox = Hive.box<Map>(_creaturesBox);
      for (final key in creaturesBox.keys.toList()) {
        final raw = creaturesBox.get(key);
        if (raw == null) continue;
        final data = Map<String, dynamic>.from(raw);

        // Only migrate entries that still have old "location" field
        if (data.containsKey('location') && !data.containsKey('locationIds')) {
          data['locationIds'] = <String>[];
          data.remove('location');
          await creaturesBox.put(key, data);
        }
      }

      // Step 2: Rebuild Location.creatureIds from existing POI→creature links.
      // POIs already have creatureIds — we mirror those onto the parent Location.
      final locationsBox = Hive.box<Map>(_locationsBox);
      final poisBox = Hive.box<Map>(_poisBox);

      for (final locKey in locationsBox.keys.toList()) {
        final locRaw = locationsBox.get(locKey);
        if (locRaw == null) continue;
        final locData = Map<String, dynamic>.from(locRaw);
        final locId = locData['id'] as String?;
        if (locId == null) continue;

        // Find all POIs belonging to this location
        final linkedCreatureIds = <String>{};
        for (final poiRaw in poisBox.values) {
          final poiData = Map<String, dynamic>.from(poiRaw);
          if (poiData['locationId'] == locId) {
            final poiCreatureIds =
                (poiData['creatureIds'] as List<dynamic>?)?.cast<String>() ??
                [];
            linkedCreatureIds.addAll(poiCreatureIds);
          }
        }

        // Also preserve any existing creatureIds already on the location
        final existingCreatureIds =
            (locData['creatureIds'] as List<dynamic>?)?.cast<String>() ?? [];
        linkedCreatureIds.addAll(existingCreatureIds);

        locData['creatureIds'] = linkedCreatureIds.toList();
        await locationsBox.put(locKey, locData);
      }

      // Step 3: Rebuild Creature.locationIds from POI.creatureIds backlinks.
      for (final creatureKey in creaturesBox.keys.toList()) {
        final creatureRaw = creaturesBox.get(creatureKey);
        if (creatureRaw == null) continue;
        final creatureData = Map<String, dynamic>.from(creatureRaw);
        final creatureId = creatureData['id'] as String?;
        if (creatureId == null) continue;

        final appearsIn = <String>{};
        // Existing locationIds
        final existing =
            (creatureData['locationIds'] as List<dynamic>?)?.cast<String>() ??
            [];
        appearsIn.addAll(existing);

        // Find POIs that reference this creature
        for (final poiRaw in poisBox.values) {
          final poiData = Map<String, dynamic>.from(poiRaw);
          final poiCreatureIds =
              (poiData['creatureIds'] as List<dynamic>?)?.cast<String>() ?? [];
          if (poiCreatureIds.contains(creatureId)) {
            final poiId = poiData['id'] as String?;
            if (poiId != null) appearsIn.add(poiId);
          }
        }

        creatureData['locationIds'] = appearsIn.toList();
        await creaturesBox.put(creatureKey, creatureData);
      }

      await _settings.put('migration_v2_bidirectional_links', true);
    } catch (_) {
      // Migration is best-effort; never block app startup
    }
  }

  Box<dynamic> get _settings => Hive.box<dynamic>(_settingsBox);

  bool get isGuestMode =>
      _settings.get('isGuestMode', defaultValue: false) as bool;

  Future<void> setGuestMode(bool value) async {
    await _settings.put('isGuestMode', value);
  }

  Box<Map> get _campaigns => Hive.box<Map>(_campaignsBox);

  List<Campaign> getAllCampaigns() {
    final campaigns = <Campaign>[];
    for (final entry in _campaigns.values) {
      final data = Map<String, dynamic>.from(entry);
      campaigns.add(Campaign.fromJson(data));
    }
    campaigns.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return campaigns;
  }

  Campaign? getCampaign(String id) {
    final data = _campaigns.get(id);
    if (data == null) return null;
    return Campaign.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveCampaign(Campaign campaign) async {
    final updatedCampaign = campaign.copyWith(updatedAt: DateTime.now());
    await _campaigns.put(updatedCampaign.id, updatedCampaign.toJson());
  }

  Future<void> deleteCampaign(String id) async {
    final campaign = getCampaign(id);
    if (campaign != null) {
      for (final adventureId in campaign.adventureIds) {
        final adventure = getAdventure(adventureId);
        if (adventure != null) {
          // Removes campaign association
          final updatedAdventure = adventure.copyWith(clearCampaignId: true);
          await saveAdventure(updatedAdventure);
        }
      }
    }
    await _campaigns.delete(id);
  }

  Box<Map> get _adventures => Hive.box<Map>(_adventuresBox);

  List<Adventure> getAllAdventures() {
    final adventures = <Adventure>[];
    for (final entry in _adventures.values) {
      final data = Map<String, dynamic>.from(entry);
      adventures.add(Adventure.fromJson(data));
    }
    adventures.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return adventures;
  }

  Adventure? getAdventure(String id) {
    final data = _adventures.get(id);
    if (data == null) return null;
    return Adventure.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveAdventure(Adventure adventure) async {
    // Handle campaign relationship
    final oldAdventure = getAdventure(adventure.id);

    // 1. If campaign changed, remove from old campaign
    if (oldAdventure != null &&
        oldAdventure.campaignId != null &&
        oldAdventure.campaignId != adventure.campaignId) {
      final oldCampaign = getCampaign(oldAdventure.campaignId!);
      if (oldCampaign != null) {
        final newAdventureIds = List<String>.from(oldCampaign.adventureIds);
        newAdventureIds.remove(adventure.id);
        await saveCampaign(oldCampaign.copyWith(adventureIds: newAdventureIds));
      }
    }

    // 2. Add to new campaign if needed
    if (adventure.campaignId != null) {
      final newCampaign = getCampaign(adventure.campaignId!);
      if (newCampaign != null) {
        if (!newCampaign.adventureIds.contains(adventure.id)) {
          final newAdventureIds = List<String>.from(newCampaign.adventureIds);
          newAdventureIds.add(adventure.id);
          await saveCampaign(
            newCampaign.copyWith(adventureIds: newAdventureIds),
          );
        }
      }
    }

    final updatedAdventure = adventure.copyWith(updatedAt: DateTime.now());
    await _adventures.put(updatedAdventure.id, updatedAdventure.toJson());
  }

  Future<void> deleteAdventure(String id) async {
    final adventure = getAdventure(id);
    if (adventure != null && adventure.campaignId != null) {
      final campaign = getCampaign(adventure.campaignId!);
      if (campaign != null) {
        final newAdventureIds = List<String>.from(campaign.adventureIds);
        newAdventureIds.remove(id);
        await saveCampaign(campaign.copyWith(adventureIds: newAdventureIds));
      }
    }

    await _adventures.delete(id);
    await _deleteByAdventureId(_legends, id);
    await _deleteByAdventureId(_pois, id);
    await _deleteByAdventureId(_events, id);
    await _deleteByAdventureId(_creatures, id);
    await _deleteByAdventureId(_locations, id);
    await _deleteByAdventureId(_facts, id);
    await _deleteByAdventureId(_sessionEntries, id);
  }

  Box<Map> get _locations => Hive.box<Map>(_locationsBox);

  List<Location> getLocations(String adventureId) {
    final locations = <Location>[];
    for (final entry in _locations.values) {
      final data = Map<String, dynamic>.from(entry);
      final location = Location.fromJson(data);
      if (location.adventureId == adventureId) {
        locations.add(location);
      }
    }
    locations.sort((a, b) => a.name.compareTo(b.name));
    return locations;
  }

  Future<void> saveLocation(Location location) async {
    await _locations.put(location.id, location.toJson());
  }

  Future<void> deleteLocation(String id) async {
    final location = _locations.get(id);
    if (location != null) {
      final data = Map<String, dynamic>.from(location);
      final adventureId = data['adventureId'] as String?;
      if (adventureId != null) {
        // Remove this locationId from all creature.locationIds
        final creatures = getCreatures(adventureId);
        for (final creature in creatures) {
          if (creature.locationIds.contains(id)) {
            await saveCreature(
              creature.copyWith(
                locationIds: creature.locationIds
                    .where((lid) => lid != id)
                    .toList(),
              ),
            );
          }
        }
        // Remove associated POIs that reference this location
        final pois = getPointsOfInterest(adventureId);
        for (final poi in pois) {
          if (poi.locationId == id) {
            // Cleanup POI's creature backlinks before deleting
            for (final creatureId in poi.creatureIds) {
              final creature = getCreatures(
                adventureId,
              ).where((c) => c.id == creatureId).firstOrNull;
              if (creature != null && creature.locationIds.contains(poi.id)) {
                await saveCreature(
                  creature.copyWith(
                    locationIds: creature.locationIds
                        .where((lid) => lid != poi.id)
                        .toList(),
                  ),
                );
              }
            }
            await _pois.delete(poi.id);
          }
        }
      }
    }
    await _locations.delete(id);
  }

  Box<Map> get _legends => Hive.box<Map>(_legendsBox);

  List<Legend> getLegends(String adventureId) {
    final legends = <Legend>[];
    for (final entry in _legends.values) {
      final data = Map<String, dynamic>.from(entry);
      final legend = Legend.fromJson(data);
      if (legend.adventureId == adventureId) {
        legends.add(legend);
      }
    }
    return legends;
  }

  Future<void> saveLegend(Legend legend) async {
    await _legends.put(legend.id, legend.toJson());
  }

  Future<void> deleteLegend(String id) async {
    await _legends.delete(id);
  }

  Box<Map> get _pois => Hive.box<Map>(_poisBox);

  List<PointOfInterest> getPointsOfInterest(String adventureId) {
    final pois = <PointOfInterest>[];
    for (final entry in _pois.values) {
      final data = Map<String, dynamic>.from(entry);
      final poi = PointOfInterest.fromJson(data);
      if (poi.adventureId == adventureId) {
        pois.add(poi);
      }
    }
    pois.sort((a, b) => a.number.compareTo(b.number));
    return pois;
  }

  Future<void> savePointOfInterest(PointOfInterest poi) async {
    await _pois.put(poi.id, poi.toJson());
  }

  Future<void> deletePointOfInterest(String id) async {
    final poiData = _pois.get(id);
    if (poiData != null) {
      final data = Map<String, dynamic>.from(poiData);
      final adventureId = data['adventureId'] as String?;
      final creatureIds =
          (data['creatureIds'] as List<dynamic>?)?.cast<String>() ?? [];
      if (adventureId != null) {
        // Remove this POI's id from all creature.locationIds
        for (final creatureId in creatureIds) {
          final creatures = getCreatures(adventureId);
          final creature = creatures
              .where((c) => c.id == creatureId)
              .firstOrNull;
          if (creature != null && creature.locationIds.contains(id)) {
            await saveCreature(
              creature.copyWith(
                locationIds: creature.locationIds
                    .where((lid) => lid != id)
                    .toList(),
              ),
            );
          }
        }
      }
    }
    await _pois.delete(id);
  }

  Box<Map> get _events => Hive.box<Map>(_eventsBox);

  List<RandomEvent> getRandomEvents(String adventureId) {
    final events = <RandomEvent>[];
    for (final entry in _events.values) {
      final data = Map<String, dynamic>.from(entry);
      final event = RandomEvent.fromJson(data);
      if (event.adventureId == adventureId) {
        events.add(event);
      }
    }
    return events;
  }

  Future<void> saveRandomEvent(RandomEvent event) async {
    await _events.put(event.id, event.toJson());
  }

  Future<void> deleteRandomEvent(String id) async {
    await _events.delete(id);
  }

  Box<Map> get _creatures => Hive.box<Map>(_creaturesBox);

  List<Creature> getCreatures(String adventureId) {
    final creatures = <Creature>[];
    for (final entry in _creatures.values) {
      final data = Map<String, dynamic>.from(entry);
      final creature = Creature.fromJson(data);
      if (creature.adventureId == adventureId) {
        creatures.add(creature);
      }
    }
    return creatures;
  }

  Future<void> saveCreature(Creature creature) async {
    await _creatures.put(creature.id, creature.toJson());
  }

  Future<void> deleteCreature(String id) async {
    final creatureData = _creatures.get(id);
    if (creatureData != null) {
      final data = Map<String, dynamic>.from(creatureData);
      final adventureId = data['adventureId'] as String?;
      if (adventureId != null) {
        // Remove this creature's id from all POI.creatureIds
        final pois = getPointsOfInterest(adventureId);
        for (final poi in pois) {
          if (poi.creatureIds.contains(id)) {
            await savePointOfInterest(
              poi.copyWith(
                creatureIds: poi.creatureIds.where((cid) => cid != id).toList(),
              ),
            );
          }
        }
        // Remove this creature's id from all Location.creatureIds
        final locations = getLocations(adventureId);
        for (final location in locations) {
          if (location.creatureIds.contains(id)) {
            await saveLocation(
              location.copyWith(
                creatureIds: location.creatureIds
                    .where((cid) => cid != id)
                    .toList(),
              ),
            );
          }
        }
      }
    }
    await _creatures.delete(id);
  }

  Box<Map> get _facts => Hive.box<Map>(_factsBox);

  List<Fact> getFacts(String adventureId) {
    final facts = <Fact>[];
    for (final entry in _facts.values) {
      final data = Map<String, dynamic>.from(entry);
      final fact = Fact.fromJson(data);
      if (fact.adventureId == adventureId) {
        facts.add(fact);
      }
    }
    facts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return facts;
  }

  Future<void> saveFact(Fact fact) async {
    await _facts.put(fact.id, fact.toJson());
  }

  Future<void> deleteFact(String id) async {
    await _facts.delete(id);
  }

  Box<Map> get _sessionEntries => Hive.box<Map>(_sessionEntriesBox);

  List<SessionEntry> getSessionEntries(String adventureId) {
    final entries = <SessionEntry>[];
    for (final entry in _sessionEntries.toMap().entries) {
      final map = Map<String, dynamic>.from(entry.value);
      if (map['adventureId'] == adventureId) {
        entries.add(SessionEntry.fromJson(map));
      }
    }
    entries.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    ); // Descending by default
    return entries;
  }

  Future<void> saveSessionEntry(SessionEntry entry) async {
    await _sessionEntries.put(entry.id, entry.toJson());
  }

  Future<void> deleteSessionEntry(String id) async {
    await _sessionEntries.delete(id);
  }

  Future<void> _deleteByAdventureId(Box<Map> box, String adventureId) async {
    final keysToDelete = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final map = Map<String, dynamic>.from(entry.value);
      if (map['adventureId'] == adventureId) {
        keysToDelete.add(entry.key);
      }
    }
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  Future<void> close() async {
    await Hive.close();
    _instance = null;
  }
}
