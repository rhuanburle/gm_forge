import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/adventure_providers.dart';
import '../widgets/play_mode/location_navigator.dart';
import '../widgets/play_mode/scene_viewer.dart';

class AdventurePlayPage extends ConsumerStatefulWidget {
  final String adventureId;

  const AdventurePlayPage({super.key, required this.adventureId});

  @override
  ConsumerState<AdventurePlayPage> createState() => _AdventurePlayPageState();
}

class _AdventurePlayPageState extends ConsumerState<AdventurePlayPage> {
  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'adventure_title_${widget.adventureId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              adventure?.name ?? 'Aventura ...',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Voltar para Editor',
            onPressed: () {
              context.push('/adventure/${widget.adventureId}');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventRoll(context),
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.casino),
        tooltip: 'Rolar Evento (d66)',
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: LocationNavigator(adventureId: widget.adventureId),
            ),
          ),

          Expanded(
            flex: 9,
            child: SceneViewer(adventureId: widget.adventureId),
          ),
        ],
      ),
    );
  }

  void _showEventRoll(BuildContext context) {
    final d1 = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
    final d2 = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
    final result = int.parse('$d1$d2');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.casino, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Evento Aleatório (d66)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$result',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Consulte a tabela de eventos na aba "Eventos".',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
