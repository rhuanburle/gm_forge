import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

/// Shows a collapsible recap of the most recent session's log entries and prep
/// data, so the GM remembers where they left off.
class PreviousSessionRecap extends ConsumerWidget {
  final String adventureId;

  const PreviousSessionRecap({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider(adventureId));
    if (sessions.isEmpty) return const SizedBox.shrink();

    // Most recently played/reviewed session
    final playedSessions = sessions
        .where((s) => s.status != SessionStatus.prep)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (playedSessions.isEmpty) return const SizedBox.shrink();
    final lastSession = playedSessions.first;

    // Get log entries for that session
    final allEntries = ref.watch(sessionEntriesProvider(adventureId));
    final sessionEntries = allEntries
        .where((e) => e.sessionId == lastSession.id)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Build content pieces
    final hasRecap = lastSession.recap.isNotEmpty;
    final hasEntries = sessionEntries.isNotEmpty;
    final hasStrongStart = lastSession.strongStart.isNotEmpty;

    if (!hasRecap && !hasEntries && !hasStrongStart) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading:
            const Icon(Icons.history, size: 16, color: AppTheme.discovery),
        title: Text(
          'Última Sessão: ${lastSession.name}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.discovery,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(lastSession.date),
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
        children: [
          // Recap text (from session prep)
          if (hasRecap) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.discovery.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.discovery.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                lastSession.recap,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Last log entries (show up to 8)
          if (hasEntries) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimos registros:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...sessionEntries
                .reversed
                .take(8)
                .toList()
                .reversed
                .map((entry) => _buildEntryRow(entry)),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryRow(SessionEntry entry) {
    final time = DateFormat('HH:mm').format(entry.timestamp);
    Color typeColor;
    switch (entry.entryType) {
      case SessionEntryType.combat:
        typeColor = AppTheme.error;
      case SessionEntryType.discovery:
        typeColor = AppTheme.discovery;
      case SessionEntryType.narrative:
        typeColor = AppTheme.primary;
      case SessionEntryType.note:
        typeColor = AppTheme.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 6),
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.text,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
