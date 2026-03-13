import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

class SessionTimeline extends ConsumerWidget {
  final String campaignId;
  const SessionTimeline({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignProvider(campaignId));
    if (campaign == null) return const SizedBox.shrink();

    // Gather sessions from all campaign adventures
    final allSessions = <_SessionWithAdventure>[];
    for (final advId in campaign.adventureIds) {
      final adventure = ref.watch(adventureProvider(advId));
      if (adventure == null) continue;
      final sessions = ref.watch(sessionsProvider(advId));
      for (final session in sessions) {
        allSessions.add(_SessionWithAdventure(session: session, adventure: adventure));
      }
    }

    if (allSessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nenhuma sessão registrada nas aventuras desta campanha.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    // Sort by date descending (most recent first)
    allSessions.sort((a, b) => b.session.date.compareTo(a.session.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...allSessions.map((entry) => _SessionTimelineCard(
          entry: entry,
          isFirst: entry == allSessions.first,
          isLast: entry == allSessions.last,
        )),
      ],
    );
  }
}

class _SessionWithAdventure {
  final Session session;
  final Adventure adventure;
  const _SessionWithAdventure({required this.session, required this.adventure});
}

class _SessionTimelineCard extends StatelessWidget {
  final _SessionWithAdventure entry;
  final bool isFirst;
  final bool isLast;

  const _SessionTimelineCard({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  Color _statusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.prep:
        return AppTheme.warning;
      case SessionStatus.played:
        return AppTheme.success;
      case SessionStatus.reviewed:
        return AppTheme.info;
    }
  }

  IconData _statusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.prep:
        return Icons.edit_note;
      case SessionStatus.played:
        return Icons.play_circle;
      case SessionStatus.reviewed:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = entry.session;
    final adventure = entry.adventure;
    final color = _statusColor(session.status);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 8, color: AppTheme.textMuted.withValues(alpha: 0.2)),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(_statusIcon(session.status), size: 10, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
              child: InkWell(
                onTap: () {
                  context.push('/adventure/${adventure.id}/session/${session.id}');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${session.number}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              session.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            dateFormat.format(session.date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.map, size: 10, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              adventure.name,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              session.status.displayName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (session.recap.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          session.recap,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.mutedForeground(context, alpha: 0.7),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (session.strongStart.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          session.strongStart,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedForeground(context, alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
