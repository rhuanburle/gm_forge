import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../database/hive_database.dart';
import '../../features/adventure/application/adventure_providers.dart';
import '../../features/adventure/domain/adventure.dart';
import '../../features/adventure/domain/campaign.dart';
import '../../features/adventure/domain/creature.dart';
import '../../features/adventure/domain/legend.dart';
import '../../features/adventure/domain/point_of_interest.dart';
import '../../features/adventure/domain/random_event.dart';
import '../../features/adventure/domain/location.dart';
import '../../features/adventure/domain/fact.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveDatabase _hiveDb;
  final String? _userId;
  final bool _isAnonymous;

  SyncService({
    required HiveDatabase hiveDb,
    required String? userId,
    bool isAnonymous = false,
  }) : _hiveDb = hiveDb,
       _userId = userId,
       _isAnonymous = isAnonymous;

  bool get _isAuthenticated => _userId != null && !_isAnonymous;

  CollectionReference<Map<String, dynamic>> get _adventuresRef =>
      _firestore.collection('users').doc(_userId).collection('adventures');

  CollectionReference<Map<String, dynamic>> get _campaignsRef =>
      _firestore.collection('users').doc(_userId).collection('campaigns');

  Future<void> pushAdventure(String adventureId) async {
    if (!_isAuthenticated) return;

    final adventure = _hiveDb.getAdventure(adventureId);
    if (adventure == null) return;

    final pois = _hiveDb.getPointsOfInterest(adventureId);
    final creatures = _hiveDb.getCreatures(adventureId);
    final legends = _hiveDb.getLegends(adventureId);
    final events = _hiveDb.getRandomEvents(adventureId);
    final locations = _hiveDb.getLocations(adventureId);
    final facts = _hiveDb.getFacts(adventureId);

    final payload = {
      'adventure': adventure.toJson(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'creatures': creatures.map((c) => c.toJson()).toList(),
      'legends': legends.map((l) => l.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'locations': locations.map((l) => l.toJson()).toList(),
      'facts': facts.map((f) => f.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 1,
    };

    await _adventuresRef.doc(adventureId).set(payload);
  }

  Future<void> pushAllAdventures() async {
    if (!_isAuthenticated) return;

    final adventures = _hiveDb.getAllAdventures();
    final allPayloads = <String, Map<String, dynamic>>{};

    for (final adventure in adventures) {
      final pois = _hiveDb.getPointsOfInterest(adventure.id);
      final creatures = _hiveDb.getCreatures(adventure.id);
      final legends = _hiveDb.getLegends(adventure.id);
      final events = _hiveDb.getRandomEvents(adventure.id);
      final locations = _hiveDb.getLocations(adventure.id);
      final facts = _hiveDb.getFacts(adventure.id);

      allPayloads[adventure.id] = {
        'adventure': adventure.toJson(),
        'pois': pois.map((p) => p.toJson()).toList(),
        'creatures': creatures.map((c) => c.toJson()).toList(),
        'legends': legends.map((l) => l.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'locations': locations.map((l) => l.toJson()).toList(),
        'facts': facts.map((f) => f.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'version': 1,
      };
    }

    // Firebase batch limit is 500 operations — split if needed
    const batchLimit = 400;
    final entries = allPayloads.entries.toList();
    for (int i = 0; i < entries.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = entries.skip(i).take(batchLimit);
      for (final entry in chunk) {
        batch.set(_adventuresRef.doc(entry.key), entry.value);
      }
      await batch.commit();
    }
  }

  Future<void> pushCampaign(String campaignId) async {
    if (!_isAuthenticated) return;

    final campaign = _hiveDb.getCampaign(campaignId);
    if (campaign == null) return;

    await _campaignsRef.doc(campaignId).set({
      'campaign': campaign.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> pullAllAdventures() async {
    if (!_isAuthenticated) return;

    final snapshot = await _adventuresRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      await _importAdventureData(data);
    }
  }

  Future<void> pullAdventure(String adventureId) async {
    if (!_isAuthenticated) return;

    final doc = await _adventuresRef.doc(adventureId).get();
    if (!doc.exists) return;

    await _importAdventureData(doc.data()!);
  }

  Future<bool> _importAdventureData(Map<String, dynamic> data) async {
    final cloudUpdatedAtRaw = data['updatedAt'];
    final cloudUpdatedAt = cloudUpdatedAtRaw is Timestamp
        ? cloudUpdatedAtRaw.toDate()
        : DateTime.now();

    final adventureJson = data['adventure'] as Map<String, dynamic>;
    final adventureId = adventureJson['id'] as String;

    final localAdventure = _hiveDb.getAdventure(adventureId);

    if (localAdventure != null) {
      if (localAdventure.updatedAt.isAfter(cloudUpdatedAt)) {
        return false;
      }
    }

    final adventure = Adventure.fromJson(adventureJson);
    await _hiveDb.saveAdventure(adventure);

    final poisJson = data['pois'] as List<dynamic>? ?? [];
    for (final poiJson in poisJson) {
      final poi = PointOfInterest.fromJson(poiJson as Map<String, dynamic>);
      await _hiveDb.savePointOfInterest(poi);
    }

    final creaturesJson = data['creatures'] as List<dynamic>? ?? [];
    for (final creatureJson in creaturesJson) {
      final creature = Creature.fromJson(creatureJson as Map<String, dynamic>);
      await _hiveDb.saveCreature(creature);
    }

    final legendsJson = data['legends'] as List<dynamic>? ?? [];
    for (final legendJson in legendsJson) {
      final legend = Legend.fromJson(legendJson as Map<String, dynamic>);
      await _hiveDb.saveLegend(legend);
    }

    final eventsJson = data['events'] as List<dynamic>? ?? [];
    for (final eventJson in eventsJson) {
      final event = RandomEvent.fromJson(eventJson as Map<String, dynamic>);
      await _hiveDb.saveRandomEvent(event);
    }

    final locationsJson = data['locations'] as List<dynamic>? ?? [];
    for (final locationJson in locationsJson) {
      final location = Location.fromJson(locationJson as Map<String, dynamic>);
      await _hiveDb.saveLocation(location);
    }

    final factsJson = data['facts'] as List<dynamic>? ?? [];
    for (final factJson in factsJson) {
      final fact = Fact.fromJson(factJson as Map<String, dynamic>);
      await _hiveDb.saveFact(fact);
    }

    return true;
  }

  Future<void> pullAllCampaigns() async {
    if (!_isAuthenticated) return;

    final snapshot = await _campaignsRef.get();

    for (final doc in snapshot.docs) {
      final campaignJson = doc.data()['campaign'] as Map<String, dynamic>;
      final campaign = Campaign.fromJson(campaignJson);
      await _hiveDb.saveCampaign(campaign);
    }
  }

  Future<void> fullSync() async {
    if (!_isAuthenticated) return;

    try {
      await pullAllAdventures();
      await pullAllCampaigns();

      await pushAllAdventures();

      final campaigns = _hiveDb.getAllCampaigns();
      for (final campaign in campaigns) {
        await pushCampaign(campaign.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAdventure(String adventureId) async {
    if (!_isAuthenticated) return;
    await _adventuresRef.doc(adventureId).delete();
  }

  Future<void> deleteCampaign(String campaignId) async {
    if (!_isAuthenticated) return;
    await _campaignsRef.doc(campaignId).delete();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final hiveDb = ref.watch(hiveDatabaseProvider);
  final user = ref.watch(currentUserProvider);
  return SyncService(
    hiveDb: hiveDb,
    userId: user?.uid,
    isAnonymous: user?.isAnonymous ?? false,
  );
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

enum SyncStatus { idle, syncing, success, error }
