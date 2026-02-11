import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/hive_database.dart';
import '../domain/domain.dart';

/// Provider for HiveDatabase
final hiveDatabaseProvider = Provider<HiveDatabase>((ref) {
  return HiveDatabase.instance;
});

/// Provider for all adventures list
final adventuresProvider = Provider<List<Adventure>>((ref) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getAllAdventures();
});

/// Provider for a specific adventure by ID
final adventureProvider = Provider.family<Adventure?, String>((ref, id) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getAdventure(id);
});

/// Provider for legends of an adventure
final legendsProvider = Provider.family<List<Legend>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getLegends(adventureId);
});

/// Provider for points of interest of an adventure
final pointsOfInterestProvider = Provider.family<List<PointOfInterest>, String>(
  (ref, adventureId) {
    final db = ref.watch(hiveDatabaseProvider);
    return db.getPointsOfInterest(adventureId);
  },
);

/// Provider for random events of an adventure
final randomEventsProvider = Provider.family<List<RandomEvent>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getRandomEvents(adventureId);
});

/// Provider for creatures of an adventure
final creaturesProvider = Provider.family<List<Creature>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getCreatures(adventureId);
});

/// Provider for locations (zones) of an adventure
final locationsProvider = Provider.family<List<Location>, String>((
  ref,
  adventureId,
) {
  final db = ref.watch(hiveDatabaseProvider);
  return db.getLocations(adventureId);
});

/// Notifier for managing adventure state with mutations
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
    final adventure = Adventure(
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

/// Notifier for managing campaign state
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
    final campaign = Campaign(name: name, description: description);
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
    // Refresh adventure list as some might have been unlinked
    ref.read(adventureListProvider.notifier).refresh();
  }
}

final campaignListProvider =
    NotifierProvider<CampaignListNotifier, List<Campaign>>(
      CampaignListNotifier.new,
    );

/// Provider for a specific campaign by ID
final campaignProvider = Provider.family<Campaign?, String>((ref, id) {
  final adventures = ref.watch(campaignListProvider);
  try {
    return adventures.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
