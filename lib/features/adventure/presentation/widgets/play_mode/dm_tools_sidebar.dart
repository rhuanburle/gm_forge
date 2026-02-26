import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import 'session_log_panel.dart';

class DMToolsSidebar extends ConsumerStatefulWidget {
  final String adventureId;

  const DMToolsSidebar({super.key, required this.adventureId});

  @override
  ConsumerState<DMToolsSidebar> createState() => _DMToolsSidebarState();
}

class _DMToolsSidebarState extends ConsumerState<DMToolsSidebar> {
  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    if (adventure == null) return const SizedBox.shrink();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.secondary.withValues(alpha: 0.1),
            width: double.infinity,
            child: const Text(
              'Escudo do Mestre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/adventure/${widget.adventureId}');
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'Editar Aventura',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: activeState.currentLocationId == null
                      ? null
                      : () {
                          context.push(
                            '/adventure/${widget.adventureId}/location/${activeState.currentLocationId}',
                          );
                        },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text(
                    'Editar Local Atual',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          if (adventure.conceptWhat.isNotEmpty ||
              adventure.conceptConflict.isNotEmpty) ...[
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  'Conceito da Aventura',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                children: [
                  if (adventure.conceptWhat.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'O que está acontecendo?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        adventure.conceptWhat,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (adventure.conceptConflict.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Qual é o conflito?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        adventure.conceptConflict,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bloco de Notas da Partida',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: SessionLogPanel(adventureId: widget.adventureId)),
        ],
      ),
    );
  }
}
