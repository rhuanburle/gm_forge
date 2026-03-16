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
  static const String _factionsBox = 'factions';
  static const String _playerCharactersBox = 'player_characters';
  static const String _itemsBox = 'items';
  static const String _loreEntriesBox = 'lore_entries';
  static const String _questsBox = 'quests';
  static const String _sessionsBox = 'sessions';
  static const String _notesBox = 'notes';
  static const String _regionsBox = 'regions';
  static const String _settingsBox = 'settings';
  static const String _quickRulesBox = 'quick_rules';

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
    await Hive.openBox<Map>(_factionsBox);
    await Hive.openBox<Map>(_playerCharactersBox);
    await Hive.openBox<Map>(_itemsBox);
    await Hive.openBox<Map>(_loreEntriesBox);
    await Hive.openBox<Map>(_questsBox);
    await Hive.openBox<Map>(_sessionsBox);
    await Hive.openBox<Map>(_notesBox);
    await Hive.openBox<Map>(_regionsBox);
    await Hive.openBox<Map>(_quickRulesBox);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';
      final settingsBox = Hive.box<dynamic>(_settingsBox);

      // Track version without destroying data — migrations handle schema changes
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
    final migrationV2Done =
        _settings.get('migration_v2_bidirectional_links') as bool? ?? false;
    if (!migrationV2Done) {
      await _runMigrationV2();
    }

    final migrationV3Done =
        _settings.get('migration_v3_campaign_id_population') as bool? ?? false;
    if (!migrationV3Done) {
      await _runMigrationV3();
    }
  }

  Future<void> _runMigrationV2() async {
    try {
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
    } catch (e, stack) {
      // Migration is best-effort; never block app startup
      // ignore: avoid_print
      print('[HiveDB] Migration v2 failed (non-fatal): $e\n$stack');
    }
  }

  Future<void> _runMigrationV3() async {
    try {
      final adventuresBox = Hive.box<Map>(_adventuresBox);
      final campaignIdMap = <String, String>{};

      // 1. Map adventureId -> campaignId
      for (final raw in adventuresBox.values) {
        final data = Map<String, dynamic>.from(raw);
        final advId = data['id'] as String?;
        final campId = data['campaignId'] as String?;
        if (advId != null && campId != null) {
          campaignIdMap[advId] = campId;
        }
      }

      final boxesToMigrate = [
        _creaturesBox,
        _locationsBox,
        _itemsBox,
        _poisBox,
        _legendsBox,
        _eventsBox,
        _factsBox,
        _questsBox,
      ];

      // 2. Update entities in each box
      for (final boxName in boxesToMigrate) {
        final box = Hive.box<Map>(boxName);
        for (final key in box.keys.toList()) {
          final raw = box.get(key);
          if (raw == null) continue;
          final data = Map<String, dynamic>.from(raw);

          final advId = data['adventureId'] as String?;
          final currentCampId = data['campaignId'] as String?;

          if (currentCampId == null && advId != null) {
            // Use mapped campaignId, or fallback to adventureId if not in a campaign
            final newCampId = campaignIdMap[advId] ?? advId;
            data['campaignId'] = newCampId;
            await box.put(key, data);
          }
        }
      }

      await _settings.put('migration_v3_campaign_id_population', true);
    } catch (e, stack) {
      // Migration is best-effort; never block app startup
      // ignore: avoid_print
      print('[HiveDB] Migration v3 failed (non-fatal): $e\n$stack');
    }
  }

  Box<dynamic> get _settings => Hive.box<dynamic>(_settingsBox);

  bool get isGuestMode =>
      _settings.get('isGuestMode', defaultValue: false) as bool;

  Future<void> setGuestMode(bool value) async {
    await _settings.put('isGuestMode', value);
  }

  String? getMetaValue(String key) => _settings.get(key) as String?;

  Future<void> setMetaValue(String key, String value) async {
    await _settings.put(key, value);
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
    await _deleteByCampaignId(_playerCharacters, id);
    await _deleteByCampaignId(_loreEntries, id);
    await _deleteByCampaignId(_notes, id);
    await _deleteByCampaignId(_regions, id);
    await _deleteByCampaignId(_factions, id);
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
    await _deleteByAdventureId(_items, id);
    await _deleteByAdventureId(_quests, id);
    await _deleteByAdventureId(_sessions, id);
    await _deleteByAdventureId(_factions, id);
  }

  Box<Map> get _locations => Hive.box<Map>(_locationsBox);

  List<Location> getLocations(String adventureId) {
    final locations = <Location>[];
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _locations.values) {
      final data = Map<String, dynamic>.from(entry);
      final location = Location.fromJson(data);
      // Item is local to this adventure OR item is global to this campaign
      final isLocal = location.adventureId == adventureId;
      final isGlobal = location.adventureId == null && 
                      campaignId != null && 
                      location.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
        locations.add(location);
      }
    }
    locations.sort((a, b) => a.name.compareTo(b.name));
    return locations;
  }

  List<Location> getCampaignLocations(String campaignId) {
    final locations = <Location>[];
    for (final entry in _locations.values) {
      final data = Map<String, dynamic>.from(entry);
      final location = Location.fromJson(data);
      // Return only global items (no adventureId) for the campaign hub
      if (location.campaignId == campaignId && location.adventureId == null) {
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
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _legends.values) {
      final data = Map<String, dynamic>.from(entry);
      final legend = Legend.fromJson(data);
      final isLocal = legend.adventureId == adventureId;
      final isGlobal = legend.adventureId == null && 
                      campaignId != null && 
                      legend.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
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
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _pois.values) {
      final data = Map<String, dynamic>.from(entry);
      final poi = PointOfInterest.fromJson(data);
      final isLocal = poi.adventureId == adventureId;
      final isGlobal = poi.adventureId == null && 
                      campaignId != null && 
                      poi.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
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
      final poiNumber = data['number'] as int?;
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
        // Remove this POI's number from sibling POIs' connections
        if (poiNumber != null) {
          final siblingPois = getPointsOfInterest(adventureId);
          for (final sibling in siblingPois) {
            if (sibling.id != id && sibling.connections.contains(poiNumber)) {
              await savePointOfInterest(
                sibling.copyWith(
                  connections: sibling.connections
                      .where((n) => n != poiNumber)
                      .toList(),
                ),
              );
            }
          }
        }
      }
    }
    await _pois.delete(id);
  }

  Box<Map> get _events => Hive.box<Map>(_eventsBox);

  List<RandomEvent> getRandomEvents(String adventureId) {
    final events = <RandomEvent>[];
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _events.values) {
      final data = Map<String, dynamic>.from(entry);
      final event = RandomEvent.fromJson(data);
      final isLocal = event.adventureId == adventureId;
      final isGlobal = event.adventureId == null && 
                      campaignId != null && 
                      event.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
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
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _creatures.values) {
      final data = Map<String, dynamic>.from(entry);
      final creature = Creature.fromJson(data);
      final isLocal = creature.adventureId == adventureId;
      final isGlobal = creature.adventureId == null && 
                      campaignId != null && 
                      creature.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
        creatures.add(creature);
      }
    }
    return creatures;
  }

  List<Creature> getCampaignCreatures(String campaignId) {
    final creatures = <Creature>[];
    for (final entry in _creatures.values) {
      final data = Map<String, dynamic>.from(entry);
      final creature = Creature.fromJson(data);
      if (creature.campaignId == campaignId && creature.adventureId == null) {
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
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _facts.values) {
      final data = Map<String, dynamic>.from(entry);
      final fact = Fact.fromJson(data);
      final isLocal = fact.adventureId == adventureId;
      final isGlobal = fact.adventureId == null && 
                      campaignId != null && 
                      fact.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
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

  // ── Factions ──

  Box<Map> get _factions => Hive.box<Map>(_factionsBox);

  List<Faction> getFactions(String campaignId) {
    final items = <Faction>[];
    for (final entry in _factions.values) {
      final data = Map<String, dynamic>.from(entry);
      final faction = Faction.fromJson(data);
      if (faction.campaignId == campaignId && faction.adventureId == null) {
        items.add(faction);
      }
    }
    return items;
  }

  List<Faction> getFactionsByAdventure(String adventureId) {
    final items = <Faction>[];
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _factions.values) {
      final data = Map<String, dynamic>.from(entry);
      final faction = Faction.fromJson(data);
      final isLocal = faction.adventureId == adventureId;
      final isGlobal = faction.adventureId == null && 
                      campaignId != null && 
                      faction.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
        items.add(faction);
      }
    }
    return items;
  }

  Future<void> saveFaction(Faction faction) async {
    await _factions.put(faction.id, faction.toJson());
  }

  Future<void> deleteFaction(String id) async {
    await _factions.delete(id);
  }

  // ── Player Characters ──

  Box<Map> get _playerCharacters => Hive.box<Map>(_playerCharactersBox);

  List<PlayerCharacter> getPlayerCharacters(String campaignId) {
    final items = <PlayerCharacter>[];
    for (final entry in _playerCharacters.values) {
      final data = Map<String, dynamic>.from(entry);
      final pc = PlayerCharacter.fromJson(data);
      if (pc.campaignId == campaignId) {
        items.add(pc);
      }
    }
    return items;
  }

  Future<void> savePlayerCharacter(PlayerCharacter pc) async {
    await _playerCharacters.put(pc.id, pc.toJson());
  }

  Future<void> deletePlayerCharacter(String id) async {
    await _playerCharacters.delete(id);
  }

  // ── Items ──

  Box<Map> get _items => Hive.box<Map>(_itemsBox);

  List<Item> getItems(String adventureId) {
    final items = <Item>[];
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _items.values) {
      final data = Map<String, dynamic>.from(entry);
      final item = Item.fromJson(data);
      final isLocal = item.adventureId == adventureId;
      final isGlobal = item.adventureId == null && 
                      campaignId != null && 
                      item.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
        items.add(item);
      }
    }
    return items;
  }

  List<Item> getCampaignItems(String campaignId) {
    final items = <Item>[];
    for (final entry in _items.values) {
      final data = Map<String, dynamic>.from(entry);
      final item = Item.fromJson(data);
      if (item.campaignId == campaignId && item.adventureId == null) {
        items.add(item);
      }
    }
    return items;
  }

  Future<void> saveItem(Item item) async {
    await _items.put(item.id, item.toJson());
  }

  Future<void> deleteItem(String id) async {
    await _items.delete(id);
  }

  // ── Lore Entries ──

  Box<Map> get _loreEntries => Hive.box<Map>(_loreEntriesBox);

  List<LoreEntry> getLoreEntries(String campaignId) {
    final items = <LoreEntry>[];
    for (final entry in _loreEntries.values) {
      final data = Map<String, dynamic>.from(entry);
      final lore = LoreEntry.fromJson(data);
      if (lore.campaignId == campaignId) {
        items.add(lore);
      }
    }
    return items;
  }

  Future<void> saveLoreEntry(LoreEntry lore) async {
    await _loreEntries.put(lore.id, lore.toJson());
  }

  Future<void> deleteLoreEntry(String id) async {
    await _loreEntries.delete(id);
  }

  // ── Quests ──

  Box<Map> get _quests => Hive.box<Map>(_questsBox);

  List<Quest> getQuests(String adventureId) {
    final items = <Quest>[];
    final adv = getAdventure(adventureId);
    final campaignId = adv?.campaignId;

    for (final entry in _quests.values) {
      final data = Map<String, dynamic>.from(entry);
      final quest = Quest.fromJson(data);
      final isLocal = quest.adventureId == adventureId;
      final isGlobal = quest.adventureId == null && 
                      campaignId != null && 
                      quest.campaignId == campaignId;
      
      if (isLocal || isGlobal) {
        items.add(quest);
      }
    }
    return items;
  }

  Future<void> saveQuest(Quest quest) async {
    await _quests.put(quest.id, quest.toJson());
  }

  Future<void> deleteQuest(String id) async {
    await _quests.delete(id);
  }

  // ── Sessions ──

  Box<Map> get _sessions => Hive.box<Map>(_sessionsBox);

  List<Session> getSessions(String adventureId) {
    final items = <Session>[];
    for (final entry in _sessions.values) {
      final data = Map<String, dynamic>.from(entry);
      final session = Session.fromJson(data);
      if (session.adventureId == adventureId) {
        items.add(session);
      }
    }
    items.sort((a, b) => a.number.compareTo(b.number));
    return items;
  }

  Future<void> saveSession(Session session) async {
    await _sessions.put(session.id, session.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _sessions.delete(id);
  }

  // ── Notes ──

  Box<Map> get _notes => Hive.box<Map>(_notesBox);

  List<Note> getNotes(String campaignId) {
    final items = <Note>[];
    for (final entry in _notes.values) {
      final data = Map<String, dynamic>.from(entry);
      final note = Note.fromJson(data);
      if (note.campaignId == campaignId) {
        items.add(note);
      }
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> saveNote(Note note) async {
    await _notes.put(note.id, note.toJson());
  }

  Future<void> deleteNote(String id) async {
    await _notes.delete(id);
  }

  // ── Regions ──

  Box<Map> get _regions => Hive.box<Map>(_regionsBox);

  List<Region> getRegions(String campaignId) {
    final items = <Region>[];
    for (final entry in _regions.values) {
      final data = Map<String, dynamic>.from(entry);
      final region = Region.fromJson(data);
      if (region.campaignId == campaignId) {
        items.add(region);
      }
    }
    return items;
  }

  Future<void> saveRegion(Region region) async {
    await _regions.put(region.id, region.toJson());
  }

  Future<void> deleteRegion(String id) async {
    await _regions.delete(id);
  }

  // ── Quick Rules ──

  Box<Map> get _quickRules => Hive.box<Map>(_quickRulesBox);

  List<QuickRule> getQuickRules(String campaignId) {
    final items = <QuickRule>[];
    for (final entry in _quickRules.values) {
      final data = Map<String, dynamic>.from(entry);
      final rule = QuickRule.fromJson(data);
      if (rule.campaignId == campaignId) {
        items.add(rule);
      }
    }
    items.sort((a, b) {
      final categoryCmp = a.category.compareTo(b.category);
      if (categoryCmp != 0) return categoryCmp;
      return a.order.compareTo(b.order);
    });
    return items;
  }

  Future<void> saveQuickRule(QuickRule rule) async {
    await _quickRules.put(rule.id, rule.toJson());
  }

  Future<void> deleteQuickRule(String id) async {
    await _quickRules.delete(id);
  }

  Future<void> _deleteByCampaignId(Box<Map> box, String campaignId) async {
    final keysToDelete = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final map = Map<String, dynamic>.from(entry.value);
      if (map['campaignId'] == campaignId) {
        keysToDelete.add(entry.key);
      }
    }
    for (final key in keysToDelete) {
      await box.delete(key);
    }
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
