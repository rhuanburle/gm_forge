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
