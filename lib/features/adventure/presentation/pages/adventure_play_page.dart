import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/adventure_providers.dart';
import '../widgets/play_mode/location_navigator.dart';
import '../../application/active_adventure_state.dart';
import '../../domain/domain.dart';
import '../widgets/play_mode/scene_viewer.dart';
import '../widgets/play_mode/dm_tools_sidebar.dart';

class AdventurePlayPage extends ConsumerStatefulWidget {
  final String adventureId;

  const AdventurePlayPage({super.key, required this.adventureId});

  @override
  ConsumerState<AdventurePlayPage> createState() => _AdventurePlayPageState();
}

class _AdventurePlayPageState extends ConsumerState<AdventurePlayPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSelection();
    });
  }

  @override
  void dispose() {
    // Clear state when leaving the screen
    try {
      ref.read(activeAdventureProvider.notifier).clear();
    } catch (_) {
      // Ignore if provider is already disposed or inaccessible
    }
    super.dispose();
  }

  void _initSelection() {
    final activeState = ref.read(activeAdventureProvider);
    if (activeState.currentLocationId != null) return;

    final pois = ref.read(pointsOfInterestProvider(widget.adventureId));
    if (pois.isNotEmpty) {
      // Sort to find the "first" logical location (usually #1 or lowest number)
      final sortedPois = List<PointOfInterest>.from(pois)
        ..sort((a, b) => a.number.compareTo(b.number));

      ref
          .read(activeAdventureProvider.notifier)
          .setLocation(sortedPois.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch to ensure we have data, but selection logic is one-off in initState/callback
    final adventure = ref.watch(adventureProvider(widget.adventureId));

    // ... rest of build

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'adventure_title_${widget.adventureId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'Escudo do Mestre: ${adventure?.name ?? ""}',
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

      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: LocationNavigator(adventureId: widget.adventureId),
            ),
          ),

          Expanded(
            flex: 7,
            child: SceneViewer(adventureId: widget.adventureId),
          ),
          DMToolsSidebar(adventureId: widget.adventureId),
        ],
      ),
    );
  }
}
