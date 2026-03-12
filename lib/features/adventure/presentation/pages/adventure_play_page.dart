import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _compactTabIndex = 0;

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

    final size = screenSizeOf(context);

    return Scaffold(
      key: _scaffoldKey,
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
          if (size == ScreenSize.medium)
            IconButton(
              icon: const Icon(Icons.menu_open),
              tooltip: 'Abrir Escudo',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Voltar para Editor',
            onPressed: () {
              context.push('/adventure/${widget.adventureId}');
            },
          ),
        ],
      ),
      endDrawer: size == ScreenSize.medium
          ? Drawer(
              width: 320,
              child: SafeArea(
                child: DMToolsSidebar(adventureId: widget.adventureId),
              ),
            )
          : null,
      bottomNavigationBar: size == ScreenSize.compact
          ? BottomNavigationBar(
              currentIndex: _compactTabIndex,
              onTap: (i) => setState(() => _compactTabIndex = i),
              selectedItemColor: AppTheme.secondary,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
                BottomNavigationBarItem(icon: Icon(Icons.visibility), label: 'Cena'),
                BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Escudo'),
              ],
            )
          : null,
      body: ResponsiveLayout(
        expanded: (context) => Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
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
        medium: (context) => Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                  ),
                ),
                child: LocationNavigator(adventureId: widget.adventureId),
              ),
            ),
            Expanded(
              flex: 7,
              child: SceneViewer(adventureId: widget.adventureId),
            ),
          ],
        ),
        compact: (context) {
          switch (_compactTabIndex) {
            case 0:
              return LocationNavigator(adventureId: widget.adventureId);
            case 1:
              return SceneViewer(adventureId: widget.adventureId);
            case 2:
              return DMToolsSidebar(adventureId: widget.adventureId);
            default:
              return SceneViewer(adventureId: widget.adventureId);
          }
        },
      ),
    );
  }
}
