import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'tools/oracle_tool.dart';
import 'tools/npc_flash_tool.dart';
import 'tools/inspiration_tool.dart';
import 'tools/dice_tool.dart';

/// A tool on the GM's bench. Register a new one by adding an entry to
/// [_kitTools] — the tab and its view come from this list, nothing else.
class KitTool {
  final String name;
  final IconData icon;
  final String blurb;
  final WidgetBuilder builder;

  const KitTool({
    required this.name,
    required this.icon,
    required this.blurb,
    required this.builder,
  });
}

const List<KitTool> _kitTools = [
  KitTool(
    name: 'Oráculo',
    icon: Icons.help_outline,
    blurb: 'Sim ou não, com nuance — para o que a preparação não previu.',
    builder: _oracle,
  ),
  KitTool(
    name: 'PNJ Relâmpago',
    icon: Icons.person_pin_circle,
    blurb: 'Nome, cara e motivo numa rolagem para o figurante inesperado.',
    builder: _npc,
  ),
  KitTool(
    name: 'Inspiração',
    icon: Icons.list_alt,
    blurb: 'Atmosfera, complicações e descrições de sala na hora.',
    builder: _inspiration,
  ),
  KitTool(
    name: 'Dados',
    icon: Icons.casino,
    blurb: 'Rolagem rápida: dados avulsos ou fórmula NdM+K.',
    builder: _dice,
  ),
];

// Tear-off builders (const list can't hold closures).
Widget _oracle(BuildContext _) => const OracleTool();
Widget _npc(BuildContext _) => const NpcFlashTool();
Widget _inspiration(BuildContext _) => const InspirationTool();
Widget _dice(BuildContext _) => const DiceTool();

/// The GM's bench: pure, always-available generators that need no adventure or
/// campaign loaded. Reachable from anywhere via `/kit`.
class MasterKitPage extends StatefulWidget {
  const MasterKitPage({super.key});

  @override
  State<MasterKitPage> createState() => _MasterKitPageState();
}

class _MasterKitPageState extends State<MasterKitPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: _kitTools.length, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Row(
          children: [
            Icon(Icons.handyman, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text('Kit do Mestre'),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            for (final t in _kitTools)
              Tab(icon: Icon(t.icon, size: 18), text: t.name),
          ],
        ),
      ),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _tab,
            builder: (context, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: AppTheme.secondary.withValues(alpha: 0.06),
              child: Text(
                _kitTools[_tab.index].blurb,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TabBarView(
                  controller: _tab,
                  children: [
                    for (final t in _kitTools) t.builder(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
