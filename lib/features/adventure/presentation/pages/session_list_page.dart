import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';

class SessionListPage extends ConsumerWidget {
  final String adventureId;

  const SessionListPage({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventure = ref.watch(adventureProvider(adventureId));
    final sessions = ref.watch(sessionsProvider(adventureId));
    final sorted = List<Session>.from(sessions)
      ..sort((a, b) => b.number.compareTo(a.number));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(adventure?.name ?? 'Sessões'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final nextNumber = sessions.isEmpty
              ? 1
              : sessions.map((s) => s.number).reduce((a, b) => a > b ? a : b) + 1;
          final newSession = Session.create(
            adventureId: adventureId,
            name: 'Sessão $nextNumber',
            number: nextNumber,
          );
          ref.read(hiveDatabaseProvider).saveSession(newSession);
          ref.invalidate(sessionsProvider(adventureId));
          context.push('/adventure/$adventureId/session/${newSession.id}');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Sessão'),
      ),
      body: sorted.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64,
                      color: AppTheme.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Nenhuma sessão criada ainda.'),
                  const SizedBox(height: 8),
                  Text(
                    'Crie uma sessão para preparar e registrar suas aventuras.',
                    style: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final session = sorted[index];
                return _SessionCard(
                  session: session,
                  adventureId: adventureId,
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir Sessão'),
                        content: Text('Excluir "${session.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Excluir',
                                style: TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(hiveDatabaseProvider).deleteSession(session.id);
                      ref.invalidate(sessionsProvider(adventureId));
                    }
                  },
                );
              },
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final String adventureId;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.adventureId,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (session.status) {
      case SessionStatus.prep:
        return AppTheme.warning;
      case SessionStatus.played:
        return AppTheme.success;
      case SessionStatus.reviewed:
        return AppTheme.info;
    }
  }

  IconData _statusIcon() {
    switch (session.status) {
      case SessionStatus.prep:
        return Icons.edit_note;
      case SessionStatus.played:
        return Icons.check_circle_outline;
      case SessionStatus.reviewed:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final hasRecap = session.recap.isNotEmpty;
    final dateStr =
        '${session.date.day.toString().padLeft(2, '0')}/${session.date.month.toString().padLeft(2, '0')}/${session.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/adventure/$adventureId/session/${session.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Session number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${session.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(_statusIcon(), size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              session.status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 20,
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppTheme.error, size: 18),
                            SizedBox(width: 8),
                            Text('Excluir'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Strong Start preview
              if (session.strongStart.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session.strongStart,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              // Recap preview
              if (hasRecap) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.discovery.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.discovery.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_stories, size: 12, color: AppTheme.discovery),
                          SizedBox(width: 4),
                          Text(
                            'Recap',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.discovery,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.recap,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              // Prep checklist mini-badges
              if (session.status == SessionStatus.prep) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _prepBadge('Cenas', session.scenes.length),
                    _prepBadge('Segredos', session.secrets.length),
                    _prepBadge('NPCs', session.npcs.length),
                    _prepBadge('Tesouros', session.treasures.length),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _prepBadge(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.textMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: count > 0
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: count > 0 ? AppTheme.success : AppTheme.textMuted,
        ),
      ),
    );
  }
}
