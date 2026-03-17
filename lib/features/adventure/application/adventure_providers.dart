import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/hive_database.dart';
import '../domain/domain.dart';

final hiveDatabaseProvider = Provider<HiveDatabase>((ref) {
  return HiveDatabase.instance;
});

final adventuresProvider = Provider<List<Adventure>>((ref) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getAllAdventures();
});

final adventureProvider = Provider.family<Adventure?, String>((ref, id) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getAdventure(id);
});

final legendsProvider = Provider.family<List<Legend>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getLegends(adventureId);
});

final pointsOfInterestProvider = Provider.family<List<PointOfInterest>, String>(
  (ref, adventureId) {
    final db = ref.watch(hiveDatabaseProvider);
    return db.getPointsOfInterest(adventureId);
  },
);

final randomEventsProvider = Provider.family<List<RandomEvent>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getRandomEvents(adventureId);
});

final creaturesProvider = Provider.family<List<Creature>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getCreatures(adventureId);
});

final locationsProvider = Provider.family<List<Location>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getLocations(adventureId);
});

final factsProvider = Provider.family<List<Fact>, String>((ref, adventureId) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getFacts(adventureId);
});

final sessionEntriesProvider = Provider.family<List<SessionEntry>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getSessionEntries(adventureId);
});

// Adventure-level providers
final itemsProvider = Provider.family<List<Item>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getItems(adventureId);
});

final questsProvider = Provider.family<List<Quest>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getQuests(adventureId);
});

final sessionsProvider = Provider.family<List<Session>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getSessions(adventureId);
});

final factionsProvider = Provider.family<List<Faction>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getFactionsByAdventure(adventureId);
});

// Campaign-level providers
final campaignQuestsProvider = Provider.family<List<Quest>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getAllQuestsByCampaign(campaignId);
});

final campaignFactionsProvider = Provider.family<List<Faction>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getFactions(campaignId);
});

final playerCharactersProvider = Provider.family<List<PlayerCharacter>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getPlayerCharacters(campaignId);
});

final loreEntriesProvider = Provider.family<List<LoreEntry>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getLoreEntries(campaignId);
});

final notesProvider = Provider.family<List<Note>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getNotes(campaignId);
});

final regionsProvider = Provider.family<List<Region>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getRegions(campaignId);
});

final campaignCreaturesProvider = Provider.family<List<Creature>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getCampaignCreatures(campaignId);
});

final campaignItemsProvider = Provider.family<List<Item>, String>((
  ref,
  campaignId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getCampaignItems(campaignId);
});

class AdventureListNotifier extends Notifier<List<Adventure>> {
  @override
  List<Adventure> build() {
    return ref.watch(hiveDatabaseProvider).getAllAdventures();
  }

  void refresh() {
    state = ref.read(hiveDatabaseProvider).getAllAdventures();
  }

  Future<Adventure> create({
    required String name,
    required String description,
    required String conceptWhat,
    required String conceptConflict,
    String? campaignId,
  }) async {
    final db = ref.read(hiveDatabaseProvider);
    final adventure = Adventure.create(
      name: name,
      description: description,
      conceptWhat: conceptWhat,
      conceptConflict: conceptConflict,
      campaignId: campaignId,
    );
    await db.saveAdventure(adventure);
    refresh();
    return adventure;
  }

  Future<void> update(Adventure adventure) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.saveAdventure(adventure);
    refresh();
  }

  Future<void> delete(String id) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.deleteAdventure(id);
    refresh();
  }
}

final adventureListProvider =
    NotifierProvider<AdventureListNotifier, List<Adventure>>(
      AdventureListNotifier.new,
    );

class CampaignListNotifier extends Notifier<List<Campaign>> {
  @override
  List<Campaign> build() {
    return ref.watch(hiveDatabaseProvider).getAllCampaigns();
  }

  void refresh() {
    state = ref.read(hiveDatabaseProvider).getAllCampaigns();
  }

  Future<Campaign> create({
    required String name,
    required String description,
  }) async {
    final db = ref.read(hiveDatabaseProvider);
    final campaign = Campaign.create(name: name, description: description);
    await db.saveCampaign(campaign);
    refresh();
    return campaign;
  }

  Future<void> update(Campaign campaign) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.saveCampaign(campaign);
    refresh();
  }

  Future<void> delete(String id) async {
    final db = ref.read(hiveDatabaseProvider);
    await db.deleteCampaign(id);
    refresh();
    ref.read(adventureListProvider.notifier).refresh();
  }
}

final campaignListProvider =
    NotifierProvider<CampaignListNotifier, List<Campaign>>(
      CampaignListNotifier.new,
    );

final campaignProvider = Provider.family<Campaign?, String>((ref, id) {
  final adventures = ref.watch(campaignListProvider);
  try {
    return adventures.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

final quickRulesProvider = Provider.family<List<QuickRule>, String>((ref, campaignId) {
  return ref.watch(hiveDatabaseProvider).getQuickRules(campaignId);
});


/// Pre-sorted view: most recently modified adventures first (max 5).
/// Avoids sorting inside build() on every frame.
final recentAdventuresProvider = Provider<List<Adventure>>((ref) {
  final adventures = ref.watch(adventureListProvider);
  final sorted = [...adventures]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sorted.take(5).toList();
});
