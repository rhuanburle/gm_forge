import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../application/adventure_providers.dart';
import '../../application/active_adventure_state.dart';
import '../widgets/play_mode/combat_tracker_panel.dart';
import '../widgets/play_mode/location_navigator.dart';
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
      _loadAndInit();
    });
  }

  @override
  void dispose() {
    // Persist state before leaving (don't clear — preserve for next session)
    try {
      ref.read(combatProvider.notifier).flush();
      ref.read(activeAdventureProvider.notifier).clear();
    } catch (_) {
      // Ignore if provider is already disposed or inaccessible
    }
    super.dispose();
  }

  Widget _buildSessionSelector() {
    final sessions = ref.watch(sessionsProvider(widget.adventureId));
    final activeState = ref.watch(activeAdventureProvider);
    final activeSessionId = activeState.activeSessionId;

    if (sessions.isEmpty) return const SizedBox.shrink();

    final sorted = List<Session>.from(sessions)
      ..sort((a, b) => b.number.compareTo(a.number));

    return PopupMenuButton<String?>(
      tooltip: 'Sessão ativa',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_edu,
            color: activeSessionId != null
                ? AppTheme.success
                : AppTheme.textMuted,
            size: 20,
          ),
          if (activeSessionId != null) ...[
            const SizedBox(width: 4),
            Text(
              '#${sorted.firstWhere((s) => s.id == activeSessionId, orElse: () => sorted.first).number}',
              style: const TextStyle(fontSize: 12, color: AppTheme.success),
            ),
          ],
        ],
      ),
      onSelected: (sessionId) {
        ref.read(activeAdventureProvider.notifier).setActiveSession(sessionId);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('Nenhuma sessão', style: TextStyle(fontStyle: FontStyle.italic)),
        ),
        const PopupMenuDivider(),
        ...sorted.map((s) => PopupMenuItem<String?>(
          value: s.id,
          child: Row(
            children: [
              if (s.id == activeSessionId)
                const Icon(Icons.check, size: 16, color: AppTheme.success)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text('Sessão #${s.number}: ${s.name}'),
            ],
          ),
        )),
      ],
    );
  }

  void _loadAndInit() {
    // Load persisted state for this adventure
    final notifier = ref.read(activeAdventureProvider.notifier);
    notifier.loadForAdventure(widget.adventureId);

    // Load persisted combat state
    ref.read(combatProvider.notifier).loadForAdventure(widget.adventureId);

    final activeState = ref.read(activeAdventureProvider);
    if (activeState.currentLocationId != null) return;

    final pois = ref.read(pointsOfInterestProvider(widget.adventureId));
    if (pois.isNotEmpty) {
      // Sort to find the "first" logical location (usually #1 or lowest number)
      final sortedPois = List<PointOfInterest>.from(pois)
        ..sort((a, b) => a.number.compareTo(b.number));

      notifier.setLocation(sortedPois.first.id);
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
          _buildSessionSelector(),
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
