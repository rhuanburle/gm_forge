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

/// SyncService - Handles cloud backup with minimal Firestore operations
///
/// Strategy:
/// - Store entire adventure as single document (1 read/write per adventure)
/// - Manual sync only (no real-time listeners)
/// - Batch operations for efficiency
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveDatabase _hiveDb;
  final String? _userId;

  SyncService({required HiveDatabase hiveDb, required String? userId})
    : _hiveDb = hiveDb,
      _userId = userId;

  /// Check if user is authenticated
  bool get _isAuthenticated => _userId != null;

  /// Get user's adventures collection reference
  CollectionReference<Map<String, dynamic>> get _adventuresRef =>
      _firestore.collection('users').doc(_userId).collection('adventures');

  /// Get user's campaigns collection reference
  CollectionReference<Map<String, dynamic>> get _campaignsRef =>
      _firestore.collection('users').doc(_userId).collection('campaigns');

  // ============ PUSH (Local -> Cloud) ============

  /// Push a single adventure to cloud (1 write)
  Future<void> pushAdventure(String adventureId) async {
    if (!_isAuthenticated) return;

    final adventure = _hiveDb.getAdventure(adventureId);
    if (adventure == null) return;

    // Collect all related data
    final pois = _hiveDb.getPointsOfInterest(adventureId);
    final creatures = _hiveDb.getCreatures(adventureId);
    final legends = _hiveDb.getLegends(adventureId);
    final events = _hiveDb.getRandomEvents(adventureId);

    // Create single document payload
    final payload = {
      'adventure': adventure.toJson(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'creatures': creatures.map((c) => c.toJson()).toList(),
      'legends': legends.map((l) => l.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 1,
    };

    // Single write for entire adventure
    await _adventuresRef.doc(adventureId).set(payload);
  }

  /// Push all adventures to cloud (batched)
  Future<void> pushAllAdventures() async {
    if (!_isAuthenticated) return;

    final adventures = _hiveDb.getAllAdventures();
    final batch = _firestore.batch();

    for (final adventure in adventures) {
      final pois = _hiveDb.getPointsOfInterest(adventure.id);
      final creatures = _hiveDb.getCreatures(adventure.id);
      final legends = _hiveDb.getLegends(adventure.id);
      final events = _hiveDb.getRandomEvents(adventure.id);

      final payload = {
        'adventure': adventure.toJson(),
        'pois': pois.map((p) => p.toJson()).toList(),
        'creatures': creatures.map((c) => c.toJson()).toList(),
        'legends': legends.map((l) => l.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'version': 1,
      };

      batch.set(_adventuresRef.doc(adventure.id), payload);
    }

    await batch.commit();
  }

  /// Push a campaign to cloud
  Future<void> pushCampaign(String campaignId) async {
    if (!_isAuthenticated) return;

    final campaign = _hiveDb.getCampaign(campaignId);
    if (campaign == null) return;

    await _campaignsRef.doc(campaignId).set({
      'campaign': campaign.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ PULL (Cloud -> Local) ============

  /// Pull all adventures from cloud (Smart Sync)
  ///
  /// Only imports if cloud version is newer than local version.
  Future<void> pullAllAdventures() async {
    if (!_isAuthenticated) return;

    final snapshot = await _adventuresRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      await _importAdventureData(data);
    }
  }

  /// Pull a single adventure from cloud (Smart Sync)
  ///
  /// Only imports if cloud version is newer than local version.
  Future<void> pullAdventure(String adventureId) async {
    if (!_isAuthenticated) return;

    final doc = await _adventuresRef.doc(adventureId).get();
    if (!doc.exists) return;

    await _importAdventureData(doc.data()!);
  }

  /// Import adventure data from cloud payload
  ///
  /// Returns true if imported, false if skipped (local is newer)
  Future<bool> _importAdventureData(Map<String, dynamic> data) async {
    // Check timestamps
    final cloudUpdatedAtRaw = data['updatedAt'];
    final cloudUpdatedAt = cloudUpdatedAtRaw is Timestamp
        ? cloudUpdatedAtRaw.toDate()
        : DateTime.now(); // Fallback

    final adventureJson = data['adventure'] as Map<String, dynamic>;
    final adventureId = adventureJson['id'] as String;

    final localAdventure = _hiveDb.getAdventure(adventureId);

    // Conflict Resolution:
    // If local exists and is NEWER than cloud, skip import (keep local).
    // If local exists and is OLDER than cloud, overwrite.
    // If local doesn't exist, import.
    if (localAdventure != null) {
      if (localAdventure.updatedAt.isAfter(cloudUpdatedAt)) {
        return false; // Local is newer, skip
      }
    }

    // Parse adventure
    final adventure = Adventure.fromJson(adventureJson);
    await _hiveDb.saveAdventure(adventure);

    // Parse POIs
    final poisJson = data['pois'] as List<dynamic>? ?? [];
    for (final poiJson in poisJson) {
      final poi = PointOfInterest.fromJson(poiJson as Map<String, dynamic>);
      await _hiveDb.savePointOfInterest(poi);
    }

    // Parse Creatures
    final creaturesJson = data['creatures'] as List<dynamic>? ?? [];
    for (final creatureJson in creaturesJson) {
      final creature = Creature.fromJson(creatureJson as Map<String, dynamic>);
      await _hiveDb.saveCreature(creature);
    }

    // Parse Legends
    final legendsJson = data['legends'] as List<dynamic>? ?? [];
    for (final legendJson in legendsJson) {
      final legend = Legend.fromJson(legendJson as Map<String, dynamic>);
      await _hiveDb.saveLegend(legend);
    }

    // Parse Events
    final eventsJson = data['events'] as List<dynamic>? ?? [];
    for (final eventJson in eventsJson) {
      final event = RandomEvent.fromJson(eventJson as Map<String, dynamic>);
      await _hiveDb.saveRandomEvent(event);
    }

    return true;
  }

  /// Pull all campaigns from cloud
  Future<void> pullAllCampaigns() async {
    if (!_isAuthenticated) return;

    final snapshot = await _campaignsRef.get();

    for (final doc in snapshot.docs) {
      final campaignJson = doc.data()['campaign'] as Map<String, dynamic>;
      final campaign = Campaign.fromJson(campaignJson);
      await _hiveDb.saveCampaign(campaign);
    }
  }

  // ============ SYNC (Bidirectional) ============

  /// Full sync - pull then push
  ///
  /// 1. Pulls all cloud adventures (updating local only if cloud is newer)
  /// 2. Pushes all local adventures (cloud will accept update based on server timestamp,
  ///    but we could optimize to only push if local.updatedAt > lastSync)
  ///
  /// For now, we push all local adventures to ensure cloud is up to date.
  /// Firestore writes are cheap enough for now (20k/day), and this ensures consistency.
  Future<void> fullSync() async {
    if (!_isAuthenticated) return;

    // 1. Pull (Cloud -> Local)
    await pullAllAdventures();
    await pullAllCampaigns();

    // 2. Push (Local -> Cloud)
    // In a more advanced version, we would track 'dirty' states or lastSyncTime.
    // For now, we push all. The cost is: 1 write per adventure per sync.
    // With 10 adventures, that's 10 writes. Very acceptable.
    await pushAllAdventures();

    final campaigns = _hiveDb.getAllCampaigns();
    for (final campaign in campaigns) {
      await pushCampaign(campaign.id);
    }
  }

  /// Delete adventure from cloud
  Future<void> deleteAdventure(String adventureId) async {
    if (!_isAuthenticated) return;
    await _adventuresRef.doc(adventureId).delete();
  }

  /// Delete campaign from cloud
  Future<void> deleteCampaign(String campaignId) async {
    if (!_isAuthenticated) return;
    await _campaignsRef.doc(campaignId).delete();
  }
}

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final hiveDb = ref.watch(hiveDatabaseProvider);
  final user = ref.watch(currentUserProvider);
  return SyncService(hiveDb: hiveDb, userId: user?.uid);
});

/// Sync status provider
final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

enum SyncStatus { idle, syncing, success, error }
