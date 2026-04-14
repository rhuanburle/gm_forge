import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/quick_rule.dart';

/// Parses `**bold**` markers in [text] and returns a [Text.rich].
/// [base] must carry the theme font-family (use DefaultTextStyle.of(context).style.copyWith(...)).
Widget _richContent(String text, TextStyle base) {
  final parts = text.split('**');
  if (parts.length == 1) return Text(text, style: base);
  final spans = <InlineSpan>[];
  for (int i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(TextSpan(
      text: parts[i],
      style: i.isOdd ? TextStyle(fontWeight: FontWeight.bold, fontFamily: base.fontFamily) : null,
    ));
  }
  return Text.rich(TextSpan(children: spans), style: base);
}

// ---------------------------------------------------------------------------
// Panel
// ---------------------------------------------------------------------------

class QuickReferencePanel extends ConsumerWidget {
  final String? campaignId;

  /// When true, renders as a full tab (no outer ExpansionTile).
  final bool expanded;

  const QuickReferencePanel({super.key, this.campaignId, this.expanded = false});

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'combate':
        return AppTheme.error;
      case 'magia':
        return AppTheme.info;
      case 'dano e saúde':
        return AppTheme.accent;
      case 'jornadas':
        return AppTheme.success;
      case 'perigos':
        return AppTheme.warning;
      case 'pnjs e monstros':
        return AppTheme.npc;
      case 'habilidades heroicas':
        return AppTheme.primary;
      case 'ferramentas do mestre':
        return AppTheme.discovery;
      default:
        return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (campaignId == null) return const SizedBox.shrink();
    final rules = ref.watch(quickRulesProvider(campaignId!));

    if (expanded) {
      return _buildExpandedView(context, rules);
    }

    // Collapsed sidebar mode (ExpansionTile)
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text(
          'Escudo do Mestre',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: rules.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Nenhum card de referência definido.\nAdicione em Campanha → Notas.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ]
            : _buildGroupedCards(context, rules),
      ),
    );
  }

  // ── Expanded tab view ────────────────────────────────────────────────────

  Widget _buildExpandedView(BuildContext context, List<QuickRule> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 2),
          child: Row(
            children: [
              const Text(
                'ESCUDO DO MESTRE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (rules.isNotEmpty)
                Tooltip(
                  message: 'Abrir Escudo Completo',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => _openFullShield(context, rules),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.fullscreen, size: 16, color: AppTheme.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (rules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Nenhum card de referência definido.\nAdicione em Campanha → Notas.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              children: _buildCategorySections(context, rules),
            ),
          ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Widget> _buildGroupedCards(BuildContext context, List<QuickRule> rules) {
    final grouped = _group(rules);
    return grouped.entries.map((entry) {
      final catColor = _categoryColor(entry.key);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.key.isNotEmpty && entry.key != 'Geral')
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: catColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ...entry.value.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CompactRuleCard(rule: rule, accentColor: catColor),
              )),
        ],
      );
    }).toList();
  }

  List<Widget> _buildCategorySections(BuildContext context, List<QuickRule> rules) {
    final grouped = _group(rules);
    return grouped.entries.map((entry) {
      final catColor = _categoryColor(entry.key);
      return _CategorySection(
        category: entry.key,
        rules: entry.value,
        color: catColor,
      );
    }).toList();
  }

  static Map<String, List<QuickRule>> _group(List<QuickRule> rules) {
    final grouped = <String, List<QuickRule>>{};
    for (final rule in rules) {
      grouped.putIfAbsent(rule.category, () => []).add(rule);
    }
    return grouped;
  }

  void _openFullShield(BuildContext context, List<QuickRule> rules) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (ctx, a1, a2) => _FullShieldScreen(rules: rules),
        transitionsBuilder: (ctx, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category section (expandable)
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  final String category;
  final List<QuickRule> rules;
  final Color color;

  const _CategorySection({
    required this.category,
    required this.rules,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isGeneral = category.isEmpty || category == 'Geral';
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 32,
        leading: Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          isGeneral ? 'GERAL' : category.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: isGeneral ? AppTheme.textMuted : color,
          ),
        ),
        children: [
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CompactRuleCard(rule: rule, accentColor: color),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact card (tap to expand)
// ---------------------------------------------------------------------------

class _CompactRuleCard extends StatelessWidget {
  final QuickRule rule;
  final Color accentColor;

  const _CompactRuleCard({required this.rule, required this.accentColor});

  void _showFullCard(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        minChildSize: 0.3,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rule.category.isNotEmpty && rule.category != 'Geral')
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 12,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            rule.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text(
                      rule.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                        height: 1.3,
                      ),
                    ),
                    if (rule.content.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: AppTheme.textMuted.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      _richContent(
                        rule.content,
                        base.copyWith(
                          fontSize: 13.5,
                          color: AppTheme.textSecondary,
                          height: 1.75,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showFullCard(context),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.textMuted.withValues(alpha: 0.15),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 7, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rule.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.open_in_full,
                        size: 9,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  if (rule.content.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      height: 1,
                      color: AppTheme.textMuted.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 5),
                    _richContent(
                      rule.content,
                      DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 10.5,
                            color: AppTheme.textSecondary.withValues(alpha: 0.9),
                            height: 1.6,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen GM Shield overlay
// ---------------------------------------------------------------------------

class _FullShieldScreen extends StatelessWidget {
  final List<QuickRule> rules;

  const _FullShieldScreen({required this.rules});

  @override
  Widget build(BuildContext context) {
    final grouped = QuickReferencePanel._group(rules);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textMuted),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Escudo do Mestre',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.secondary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 32),
        children: grouped.entries.map((entry) {
          final catColor = QuickReferencePanel._categoryColor(entry.key);
          final isGeneral = entry.key.isEmpty || entry.key == 'Geral';
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              leading: Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    isGeneral ? 'GERAL' : entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isGeneral ? AppTheme.textMuted : catColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: catColor.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
              children: [
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cols = constraints.maxWidth > 600
                        ? 3
                        : constraints.maxWidth > 380
                            ? 2
                            : 1;
                    final cardWidth =
                        (constraints.maxWidth - (cols - 1) * 8) / cols;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value
                          .map((rule) => SizedBox(
                                width: cardWidth,
                                child: _FullShieldCard(
                                  rule: rule,
                                  accentColor: catColor,
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Large card for the full-screen view
// ---------------------------------------------------------------------------

class _FullShieldCard extends StatelessWidget {
  final QuickRule rule;
  final Color accentColor;

  const _FullShieldCard({required this.rule, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                  height: 1.3,
                ),
              ),
              if (rule.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: AppTheme.textMuted.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 6),
                _richContent(
                  rule.content,
                  DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.65,
                      ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
