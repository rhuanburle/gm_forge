import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../database/hive_database.dart';
import '../../features/adventure/application/adventure_providers.dart';
import '../../features/adventure/domain/domain.dart';

/// Safely casts a Firestore/Hive dynamic map to Map<String, dynamic>.
/// Firestore returns nested maps as Map<dynamic, dynamic>, so a direct
/// `as Map<String, dynamic>` cast throws at runtime.
Map<String, dynamic> _m(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return raw.cast<String, dynamic>();
  throw TypeError();
}

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
    final sessionEntries = _hiveDb.getSessionEntries(adventureId);
    final items = _hiveDb.getItems(adventureId);
    final quests = _hiveDb.getQuests(adventureId);
    final sessions = _hiveDb.getSessions(adventureId);
    final factions = _hiveDb.getFactionsByAdventure(adventureId);

    final payload = {
      'adventure': adventure.toJson(),
      'pois': pois.map((p) => p.toJson()).toList(),
      'creatures': creatures.map((c) => c.toJson()).toList(),
      'legends': legends.map((l) => l.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'locations': locations.map((l) => l.toJson()).toList(),
      'facts': facts.map((f) => f.toJson()).toList(),
      'session_entries': sessionEntries.map((se) => se.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
      'quests': quests.map((q) => q.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'factions': factions.map((f) => f.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 2,
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
      final sessionEntries = _hiveDb.getSessionEntries(adventure.id);
      final items = _hiveDb.getItems(adventure.id);
      final quests = _hiveDb.getQuests(adventure.id);
      final sessions = _hiveDb.getSessions(adventure.id);
      final factions = _hiveDb.getFactionsByAdventure(adventure.id);

      allPayloads[adventure.id] = {
        'adventure': adventure.toJson(),
        'pois': pois.map((p) => p.toJson()).toList(),
        'creatures': creatures.map((c) => c.toJson()).toList(),
        'legends': legends.map((l) => l.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'locations': locations.map((l) => l.toJson()).toList(),
        'facts': facts.map((f) => f.toJson()).toList(),
        'session_entries': sessionEntries.map((se) => se.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'quests': quests.map((q) => q.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'factions': factions.map((f) => f.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'version': 2,
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

    final playerCharacters = _hiveDb.getPlayerCharacters(campaignId);
    final loreEntries = _hiveDb.getLoreEntries(campaignId);
    final notes = _hiveDb.getNotes(campaignId);
    final regions = _hiveDb.getRegions(campaignId);
    final campaignFactions = _hiveDb.getFactions(campaignId);
    final quickRules = _hiveDb.getQuickRules(campaignId);
    final campaignItems = _hiveDb.getCampaignItems(campaignId);
    final campaignCreatures = _hiveDb.getCampaignCreatures(campaignId);

    await _campaignsRef.doc(campaignId).set({
      'campaign': campaign.toJson(),
      'playerCharacters':
          playerCharacters.map((pc) => pc.toJson()).toList(),
      'loreEntries': loreEntries.map((l) => l.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'regions': regions.map((r) => r.toJson()).toList(),
      'factions': campaignFactions.map((f) => f.toJson()).toList(),
      'quickRules': quickRules.map((qr) => qr.toJson()).toList(),
      'items': campaignItems.map((i) => i.toJson()).toList(),
      'creatures': campaignCreatures.map((c) => c.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> pullAllAdventures() async {
    if (!_isAuthenticated) return;

    final snapshot = await _adventuresRef.get();
    final cloudIds = snapshot.docs.map((d) => d.id).toSet();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      await _importAdventureData(data);
    }

    // Remove local adventures that were deleted on another device
    final localAdventures = _hiveDb.getAllAdventures();
    for (final local in localAdventures) {
      if (!cloudIds.contains(local.id)) {
        await _hiveDb.deleteAdventure(local.id);
      }
    }
  }

  Future<void> pullAdventure(String adventureId) async {
    if (!_isAuthenticated) return;

    final doc = await _adventuresRef.doc(adventureId).get();
    if (!doc.exists) return;

    await _importAdventureData(doc.data()!);
  }

  Future<bool> _importAdventureData(Map<String, dynamic> data) async {
    try {
      final cloudUpdatedAtRaw = data['updatedAt'];
      final cloudUpdatedAt = cloudUpdatedAtRaw is Timestamp
          ? cloudUpdatedAtRaw.toDate()
          : DateTime.now();

      final adventureJson = data['adventure'] == null ? null : _m(data['adventure']);
      if (adventureJson == null || adventureJson['id'] == null) return false;
      final adventureId = adventureJson['id'] as String;

      final localAdventure = _hiveDb.getAdventure(adventureId);
      if (localAdventure != null &&
          localAdventure.updatedAt.isAfter(cloudUpdatedAt)) {
        return false;
      }

      final adventure = Adventure.fromJson(adventureJson);
      await _hiveDb.saveAdventure(adventure);

      await _importList<PointOfInterest>(
        data['pois'], PointOfInterest.fromJson, _hiveDb.savePointOfInterest);
      await _importList<Creature>(
        data['creatures'], Creature.fromJson, _hiveDb.saveCreature);
      await _importList<Legend>(
        data['legends'], Legend.fromJson, _hiveDb.saveLegend);
      await _importList<RandomEvent>(
        data['events'], RandomEvent.fromJson, _hiveDb.saveRandomEvent);
      await _importList<Location>(
        data['locations'], Location.fromJson, _hiveDb.saveLocation);
      await _importList<Fact>(
        data['facts'], Fact.fromJson, _hiveDb.saveFact);
      await _importList<SessionEntry>(
        data['session_entries'], SessionEntry.fromJson, _hiveDb.saveSessionEntry);
      await _importList<Item>(
        data['items'], Item.fromJson, _hiveDb.saveItem);
      await _importList<Quest>(
        data['quests'], Quest.fromJson, _hiveDb.saveQuest);
      await _importList<Session>(
        data['sessions'], Session.fromJson, _hiveDb.saveSession);
      await _importList<Faction>(
        data['factions'], Faction.fromJson, _hiveDb.saveFaction);

      return true;
    } catch (e, stack) {
      // ignore: avoid_print
      print('[SyncService] Failed to import adventure data: $e\n$stack');
      return false;
    }
  }

  Future<void> _importList<T>(
    dynamic rawList,
    T Function(Map<String, dynamic>) fromJson,
    Future<void> Function(T) save,
  ) async {
    final list = rawList as List<dynamic>? ?? [];
    for (final item in list) {
      try {
        final entity = fromJson(_m(item));
        await save(entity);
      } catch (e) {
        // Skip malformed entries rather than aborting the whole import
        // ignore: avoid_print
        print('[SyncService] Skipping malformed entry: $e');
      }
    }
  }

  Future<void> pullAllCampaigns() async {
    if (!_isAuthenticated) return;

    final snapshot = await _campaignsRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final campaignJson = _m(data['campaign']);
      final campaign = Campaign.fromJson(campaignJson);

      // Check if local version is newer — skip import if so
      final cloudUpdatedAtRaw = data['updatedAt'];
      final cloudUpdatedAt = cloudUpdatedAtRaw is Timestamp
          ? cloudUpdatedAtRaw.toDate()
          : DateTime.now();
      final localCampaign = _hiveDb.getCampaign(campaign.id);
      if (localCampaign != null &&
          localCampaign.updatedAt.isAfter(cloudUpdatedAt)) {
        continue;
      }

      await _hiveDb.saveCampaign(campaign);

      final pcsJson = data['playerCharacters'] as List<dynamic>? ?? [];
      for (final pcJson in pcsJson) {
        final pc = PlayerCharacter.fromJson(_m(pcJson));
        await _hiveDb.savePlayerCharacter(pc);
      }

      final loreJson = data['loreEntries'] as List<dynamic>? ?? [];
      for (final lJson in loreJson) {
        final lore = LoreEntry.fromJson(_m(lJson));
        await _hiveDb.saveLoreEntry(lore);
      }

      final notesJson = data['notes'] as List<dynamic>? ?? [];
      for (final nJson in notesJson) {
        final note = Note.fromJson(_m(nJson));
        await _hiveDb.saveNote(note);
      }

      final regionsJson = data['regions'] as List<dynamic>? ?? [];
      for (final rJson in regionsJson) {
        final region = Region.fromJson(_m(rJson));
        await _hiveDb.saveRegion(region);
      }

      final factionsJson = data['factions'] as List<dynamic>? ?? [];
      for (final fJson in factionsJson) {
        final faction = Faction.fromJson(_m(fJson));
        await _hiveDb.saveFaction(faction);
      }

      final quickRulesJson = data['quickRules'] as List<dynamic>? ?? [];
      for (final qrJson in quickRulesJson) {
        final quickRule = QuickRule.fromJson(_m(qrJson));
        await _hiveDb.saveQuickRule(quickRule);
      }

      final itemsJson = data['items'] as List<dynamic>? ?? [];
      for (final iJson in itemsJson) {
        final item = Item.fromJson(_m(iJson));
        await _hiveDb.saveItem(item);
      }

      final creaturesJson = data['creatures'] as List<dynamic>? ?? [];
      for (final cJson in creaturesJson) {
        final creature = Creature.fromJson(_m(cJson));
        await _hiveDb.saveCreature(creature);
      }
    }

    // Remove local campaigns that were deleted on another device
    final cloudCampaignIds = snapshot.docs.map((d) => d.id).toSet();
    final localCampaigns = _hiveDb.getAllCampaigns();
    for (final local in localCampaigns) {
      if (!cloudCampaignIds.contains(local.id)) {
        await _hiveDb.deleteCampaign(local.id);
      }
    }
  }

  Future<void> fullSync() async {
    if (!_isAuthenticated) return;

    try {
      // Push local changes FIRST to avoid cloud overwriting unsaved edits
      await pushAllAdventures();

      final campaigns = _hiveDb.getAllCampaigns();
      for (final campaign in campaigns) {
        await pushCampaign(campaign.id);
      }

      // Then pull cloud data (which now includes our pushed changes)
      await pullAllAdventures();
      await pullAllCampaigns();
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
