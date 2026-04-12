import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/quick_rule.dart';

class QuickReferencePanel extends ConsumerWidget {
  final String? campaignId;
  /// When true, renders content directly (no ExpansionTile) for use as a dedicated tab.
  final bool expanded;

  const QuickReferencePanel({super.key, this.campaignId, this.expanded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (campaignId == null) return const SizedBox.shrink();

    final rules = ref.watch(quickRulesProvider(campaignId!));

    if (expanded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: rules.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Nenhum card de referência definido.\nAdicione em Campanha → Notas.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              )
            : _buildCardGrid(context, rules),
      );
    }

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
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: rules.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Nenhum card de referência definido.\nAdicione em Campanha → Notas.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ]
            : [_buildCardGrid(context, rules)],
      ),
    );
  }

  Widget _buildCardGrid(BuildContext context, List<QuickRule> rules) {
    // Group by category
    final grouped = <String, List<QuickRule>>{};
    for (final rule in rules) {
      grouped.putIfAbsent(rule.category, () => []).add(rule);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.key.isNotEmpty && entry.key != 'Geral') ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondary,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 300 ? 2 : 1;
                final cardWidth = (constraints.maxWidth - (cols - 1) * 6) / cols;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.value
                      .map((rule) => SizedBox(
                            width: cardWidth,
                            child: _CompactRuleCard(rule: rule),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _CompactRuleCard extends StatelessWidget {
  final QuickRule rule;

  const _CompactRuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule.title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          if (rule.content.isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(height: 1, color: AppTheme.textMuted.withValues(alpha: 0.15)),
            const SizedBox(height: 5),
            Text(
              rule.content,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
