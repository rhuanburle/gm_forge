import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/hive_database.dart';
import '../../features/adventure/application/adventure_providers.dart';
import '../../features/adventure/domain/domain.dart';

/// Auto-chronicle: turns notable play events (a session ending, an escalation
/// firing) into campaign timeline entries, so the "Linha do Tempo" fills itself
/// instead of relying on the GM to log everything by hand.
///
/// Campaign-scoped only: a standalone adventure has no campaign timeline, so
/// [record] no-ops when the id doesn't resolve to a real campaign.
class ChronicleService {
  final HiveDatabase _db;

  ChronicleService(this._db);

  Future<TimelineEntry?> record({
    required String campaignId,
    required String title,
    String description = '',
    TimelineEntryType type = TimelineEntryType.worldEvent,
    int? sessionNumber,
  }) async {
    if (campaignId.trim().isEmpty) return null;
    final campaign = _db.getCampaign(campaignId);
    if (campaign == null) return null; // no timeline to append to

    final entry = TimelineEntry.create(
      campaignId: campaignId,
      day: campaign.currentDay,
      title: title,
      description: description,
      type: type,
      sessionNumber: sessionNumber,
    );
    await _db.saveTimelineEntry(entry);
    return entry;
  }
}

final chronicleServiceProvider = Provider<ChronicleService>((ref) {
  return ChronicleService(ref.watch(hiveDatabaseProvider));
});
