import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../application/adventure_providers.dart';

/// Explains the local-vs-campaign scope of Creatures / Factions / Items once,
/// using the same icons the list badges use, and — when the adventure belongs
/// to a campaign — offers a shortcut to the shared pool in the Campaign Hub.
///
/// Renders nothing for standalone adventures: with no campaign there is no
/// "shared" scope, so there is nothing to disambiguate.
class ScopeHint extends ConsumerWidget {
  final String adventureId;

  /// Plural noun used in the copy ("criaturas", "facções", "itens").
  final String noun;

  const ScopeHint({
    super.key,
    required this.adventureId,
    required this.noun,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventure = ref.watch(adventureProvider(adventureId));
    final campaignId = adventure?.campaignId;
    if (campaignId == null || campaignId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.r12),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppTheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                const Icon(Icons.push_pin, size: 13, color: AppTheme.textMuted),
                Text(
                  'Local = só nesta aventura.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.public, size: 13, color: AppTheme.primary),
                Text(
                  'Campanha = $noun compartilhados com todas as aventuras.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => context.push('/campaign/$campaignId'),
            icon: const Icon(Icons.hub, size: 16),
            label: const Text('Hub', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
