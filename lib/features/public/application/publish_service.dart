import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/database/hive_database.dart';
import '../../adventure/application/adventure_providers.dart';
import '../../adventure/domain/domain.dart';
import '../domain/public_page.dart';

final publishServiceProvider = Provider<PublishService>((ref) {
  final db = ref.read(hiveDatabaseProvider);
  final auth = ref.read(authServiceProvider);
  return PublishService(db: db, userId: auth.currentUser?.uid);
});

/// Stored share IDs per campaign in Hive meta box.
final shareIdProvider = Provider.family<String?, String>((ref, campaignId) {
  final db = ref.read(hiveDatabaseProvider);
  return db.getMetaValue('shareId_$campaignId');
});

class PublishService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveDatabase _db;
  final String? _userId;

  PublishService({required HiveDatabase db, required String? userId})
      : _db = db,
        _userId = userId;

  CollectionReference<Map<String, dynamic>> get _publicPagesRef =>
      _firestore.collection('public_pages');

  /// Publish a campaign as a public page. Returns the share URL path.
  Future<String> publishCampaign(String campaignId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuário não autenticado');

    final campaign = _db.getCampaign(campaignId);
    if (campaign == null) throw Exception('Campanha não encontrada');

    // Get or create share ID
    String? shareId = _db.getMetaValue('shareId_$campaignId');
    if (shareId == null) {
      shareId = PublicPage.generateShareId();
      await _db.setMetaValue('shareId_$campaignId', shareId);
    }

    // Gather player-safe data
    final pcs = _db.getPlayerCharacters(campaignId);
    final allSessions = <Session>[];
    final allQuests = <Quest>[];
    final allCreatures = <Creature>[];
    final allFacts = <Fact>[];

    for (final advId in campaign.adventureIds) {
      allSessions.addAll(_db.getSessions(advId));
      allQuests.addAll(_db.getQuests(advId));
      allCreatures.addAll(_db.getCreatures(advId));
      allFacts.addAll(_db.getFacts(advId));
    }

    // Filter: only NPCs, non-secret facts, sessions with recaps
    final publicSessions = allSessions
        .where((s) => s.recap.isNotEmpty)
        .map((s) => PublicSession(
              number: s.number,
              name: s.name,
              date: '${s.date.day.toString().padLeft(2, '0')}/${s.date.month.toString().padLeft(2, '0')}/${s.date.year}',
              recap: s.recap,
            ))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    final publicQuests = allQuests
        .map((q) => PublicQuest(
              name: q.name,
              description: q.description,
              status: q.status.displayName,
              objectives: q.objectives
                  .map((o) => PublicObjective(
                      text: o.text, isComplete: o.isComplete))
                  .toList(),
            ))
        .toList();

    final publicNpcs = allCreatures
        .where((c) => c.type == CreatureType.npc)
        .map((c) => PublicCreature(
              name: c.name,
              description: c.description,
              imageUrl: c.imagePath,
            ))
        .toList();

    final publicFacts = allFacts
        .where((f) => !f.isSecret) // Only non-secret facts
        .map((f) => PublicFact(content: f.content))
        .toList();

    final publicPcs = pcs
        .map((pc) => PublicPlayerCharacter(
              name: pc.name,
              playerName: pc.playerName,
              species: pc.species,
              characterClass: pc.characterClass,
              level: pc.level,
              imageUrl: pc.imageUrl,
            ))
        .toList();

    final publicPage = PublicPage(
      shareId: shareId,
      userId: userId,
      campaignId: campaignId,
      campaignName: campaign.name,
      campaignDescription: campaign.description,
      sessions: publicSessions,
      quests: publicQuests,
      npcs: publicNpcs,
      facts: publicFacts,
      playerCharacters: publicPcs,
      publishedAt: DateTime.now(),
      isActive: true,
    );

    await _publicPagesRef.doc(shareId).set(publicPage.toJson());

    return shareId;
  }

  /// Unpublish a campaign's public page.
  Future<void> unpublishCampaign(String campaignId) async {
    final shareId = _db.getMetaValue('shareId_$campaignId');
    if (shareId == null) return;

    await _publicPagesRef.doc(shareId).update({'isActive': false});
  }

  /// Fetch a public page by share ID (no auth required).
  static Future<PublicPage?> fetchPublicPage(String shareId) async {
    final doc = await FirebaseFirestore.instance
        .collection('public_pages')
        .doc(shareId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['isActive'] != true) return null;
    return PublicPage.fromJson(data);
  }
}
