import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_theme.dart';

/// One entry inside an [EditorGroupTab].
class EditorSubTab {
  final String label;
  final IconData icon;
  final Widget child;

  const EditorSubTab({
    required this.label,
    required this.icon,
    required this.child,
  });
}

/// Groups several editor sub-views under a single top-level tab, with a
/// horizontally scrollable segmented control on top. Keeps every child alive
/// (IndexedStack) so scroll position and form state survive switching.
///
/// Used to collapse the old 10-tab editor into ~6 conceptual groups
/// (Elenco, Tesouro & Missões, Na Mesa).
class EditorGroupTab extends StatefulWidget {
  final List<EditorSubTab> tabs;
  final int initialIndex;

  const EditorGroupTab({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
  });

  @override
  State<EditorGroupTab> createState() => _EditorGroupTabState();
}

class _EditorGroupTabState extends State<EditorGroupTab> {
  late int _index = widget.initialIndex.clamp(0, widget.tabs.length - 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              for (var i = 0; i < widget.tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _SegChip(
                  label: widget.tabs[i].label,
                  icon: widget.tabs[i].icon,
                  selected: i == _index,
                  onTap: () => setState(() => _index = i),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: [for (final t in widget.tabs) t.child],
          ),
        ),
      ],
    );
  }
}

class _SegChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.secondary : AppTheme.textMuted;
    return Material(
      color: selected
          ? AppTheme.secondary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.secondary.withValues(alpha: 0.6)
                  : AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
