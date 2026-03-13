import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/quick_rule.dart';

class QuickReferencePanel extends ConsumerWidget {
  final String? campaignId;
  const QuickReferencePanel({super.key, this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (campaignId == null) return const SizedBox.shrink();

    final rules = ref.watch(quickRulesProvider(campaignId!));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text(
          'Regras Rápidas',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children:
            rules.isEmpty
                ? [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Nenhuma regra rápida definida para esta campanha.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                ]
                : _buildCategorizedRules(rules),
      ),
    );
  }

  List<Widget> _buildCategorizedRules(List<QuickRule> rules) {
    final categories = <String, List<QuickRule>>{};
    for (final rule in rules) {
      categories.putIfAbsent(rule.category, () => []).add(rule);
    }

    final widgets = <Widget>[];
    for (final category in categories.keys) {
      widgets.add(_buildCategoryHeader(category));
      for (final rule in categories[category]!) {
        widgets.add(_buildRuleItem(rule));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  Widget _buildCategoryHeader(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          category.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(QuickRule rule) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            rule.content,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
