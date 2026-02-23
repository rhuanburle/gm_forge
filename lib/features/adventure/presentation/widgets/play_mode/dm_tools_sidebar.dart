import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/debouncer.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';

class DMToolsSidebar extends ConsumerStatefulWidget {
  final String adventureId;

  const DMToolsSidebar({super.key, required this.adventureId});

  @override
  ConsumerState<DMToolsSidebar> createState() => _DMToolsSidebarState();
}

class _DMToolsSidebarState extends ConsumerState<DMToolsSidebar> {
  late TextEditingController _notesController;
  final _debouncer = Debouncer(milliseconds: 1000);
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    final activeState = ref.watch(activeAdventureProvider);

    if (adventure == null) return const SizedBox.shrink();

    if (!_initialized) {
      _notesController.text = adventure.sessionNotes ?? '';
      _initialized = true;
    }

    return Container(
      width: 250,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Anotações da sessão (HP, iniciativa, ideias)...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13, height: 1.4),
                onChanged: (text) {
                  _debouncer.run(() {
                    ref
                        .read(adventureListProvider.notifier)
                        .update(adventure.copyWith(sessionNotes: text));
                    ref.read(unsyncedChangesProvider.notifier).state = true;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
