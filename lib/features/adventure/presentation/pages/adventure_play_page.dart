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
import '../widgets/play_mode/session_end_dialog.dart';

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

    final activeSession = activeSessionId != null
        ? sorted.where((s) => s.id == activeSessionId).firstOrNull
        : null;

    if (activeSession != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_edu, color: AppTheme.success, size: 16),
            const SizedBox(width: 4),
            Text(
              '#${activeSession.number}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showSessionSelectorDialog(context, sorted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warning, size: 16),
            const SizedBox(width: 4),
            Text(
              'Selecionar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionSelectorDialog(
    BuildContext context,
    List<Session> sessions,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecionar Sessão'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                  child: Text(
                    '#${session.number}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                title: Text(session.name),
                subtitle: session.strongStart.isNotEmpty
                    ? Text(
                        session.strongStart,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
                onTap: () {
                  ref
                      .read(activeAdventureProvider.notifier)
                      .setActiveSession(session.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
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
    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          _buildSessionWarning(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSessionWarning() {
    final activeState = ref.watch(activeAdventureProvider);
    final activeSessionId = activeState.activeSessionId;

    if (activeSessionId != null) return const SizedBox.shrink();

    final sessions = ref.watch(sessionsProvider(widget.adventureId));
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 18, color: AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nenhuma sessão selecionada',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.warning,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    final size = screenSizeOf(context);

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
          _buildSessionSelector(),
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Encerrar Sessão',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) =>
                    SessionEndDialog(adventureId: widget.adventureId),
              );
            },
          ),
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.visibility),
                  label: 'Cena',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shield),
                  label: 'Escudo',
                ),
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
                    right: BorderSide(
                      color: AppTheme.textMuted.withValues(alpha: 0.2),
                    ),
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
                    right: BorderSide(
                      color: AppTheme.textMuted.withValues(alpha: 0.2),
                    ),
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
