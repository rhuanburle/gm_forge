import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../features/adventure/domain/domain.dart';
import '../../features/adventure/domain/fact.dart';

class HiveDatabase {
  static const String _adventuresBox = 'adventures';
  static const String _legendsBox = 'legends';
  static const String _poisBox = 'points_of_interest';
  static const String _eventsBox = 'random_events';
  static const String _creaturesBox = 'creatures';
  static const String _campaignsBox = 'campaigns';
  static const String _locationsBox = 'locations';
  static const String _factsBox = 'facts';

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

    await Hive.openBox<Map>(_adventuresBox);
    await Hive.openBox<Map>(_legendsBox);
    await Hive.openBox<Map>(_poisBox);
    await Hive.openBox<Map>(_eventsBox);
    await Hive.openBox<Map>(_creaturesBox);
    await Hive.openBox<Map>(_campaignsBox);
    await Hive.openBox<Map>(_locationsBox);
    await Hive.openBox<Map>(_factsBox);

    _instance = HiveDatabase._();
    return _instance!;
  }

  HiveDatabase._();

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
    campaign.updatedAt = DateTime.now();
    await _campaigns.put(campaign.id, campaign.toJson());
  }

  Future<void> deleteCampaign(String id) async {
    final campaign = getCampaign(id);
    if (campaign != null) {
      for (final adventureId in campaign.adventureIds) {
        final adventure = getAdventure(adventureId);
        if (adventure != null) {
          adventure.campaignId = null;
          await saveAdventure(adventure);
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
    adventure.updatedAt = DateTime.now();
    await _adventures.put(adventure.id, adventure.toJson());
  }

  Future<void> deleteAdventure(String id) async {
    final adventure = getAdventure(id);
    if (adventure != null && adventure.campaignId != null) {
      final campaign = getCampaign(adventure.campaignId!);
      if (campaign != null) {
        campaign.adventureIds.remove(id);
        await saveCampaign(campaign);
      }
    }

    await _adventures.delete(id);
    await _deleteByAdventureId(_legends, id);
    await _deleteByAdventureId(_pois, id);
    await _deleteByAdventureId(_events, id);
    await _deleteByAdventureId(_creatures, id);
    await _deleteByAdventureId(_locations, id);
    await _deleteByAdventureId(_facts, id);
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
