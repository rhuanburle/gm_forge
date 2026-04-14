import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../adventure/application/adventure_providers.dart';
import '../../../../adventure/application/active_adventure_state.dart';
import '../../../../adventure/domain/domain.dart';

/// Shows the current session's strongStart when playing, or the previous session's recap otherwise.
class PreviousSessionRecap extends ConsumerWidget {
  final String adventureId;

  const PreviousSessionRecap({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider(adventureId));
    if (sessions.isEmpty) return const SizedBox.shrink();

    final activeState = ref.watch(activeAdventureProvider);
    final activeSessionId = activeState.activeSessionId;

    // If there's an active session, show its strongStart
    if (activeSessionId != null) {
      final activeSession = sessions
          .where((s) => s.id == activeSessionId)
          .firstOrNull;
      if (activeSession != null && activeSession.strongStart.isNotEmpty) {
        return _buildCurrentSessionPanel(context, activeSession);
      }
    }

    // Otherwise show previous session recap
    final playedSessions =
        sessions.where((s) => s.status != SessionStatus.prep).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (playedSessions.isEmpty) return const SizedBox.shrink();
    final lastSession = playedSessions.first;

    final allEntries = ref.watch(sessionEntriesProvider(adventureId));
    final sessionEntries =
        allEntries.where((e) => e.sessionId == lastSession.id).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
        leading: const Icon(Icons.history, size: 16, color: AppTheme.discovery),
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
            ...sessionEntries.reversed
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
            decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
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

  Widget _buildCurrentSessionPanel(BuildContext context, Session session) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: const Icon(Icons.flash_on, size: 16, color: AppTheme.warning),
        title: Text(
          'Sessão Atual: ${session.name}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.warning,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(session.date),
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, size: 14, color: AppTheme.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Início Forte',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session.strongStart,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
