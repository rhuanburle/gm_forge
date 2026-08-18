import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../core/services/chronicle_service.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

/// Compact "GM cockpit" panel showing the most-actionable bullets:
/// - Adventure-level reminders (always)
/// - POI-level reminders (when a scene is active)
/// - Next pending escalation step
/// - Sidebars attached to current POI (collapsed cards)
class GmRemindersPanel extends ConsumerWidget {
  final String adventureId;
  final String? currentPoiId;

  const GmRemindersPanel({
    super.key,
    required this.adventureId,
    this.currentPoiId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventure = ref.watch(adventureProvider(adventureId));
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final escalations = ref.watch(escalationsProvider(adventureId));
    final sidebars = ref.watch(sidebarsProvider(adventureId));

    if (adventure == null) return const SizedBox.shrink();

    final currentPoi = currentPoiId == null
        ? null
        : pois.where((p) => p.id == currentPoiId).firstOrNull;

    final adventureReminders = adventure.gmReminders;
    final poiReminders = currentPoi?.gmReminders ?? const <String>[];
    final contextualSidebars = currentPoi == null
        ? const <Sidebar>[]
        : sidebars.where((s) =>
            s.attachedPoiId == currentPoi.id ||
            currentPoi.sidebarIds.contains(s.id)).toList();

    final hasAnything = adventureReminders.isNotEmpty ||
        poiReminders.isNotEmpty ||
        escalations.isNotEmpty ||
        contextualSidebars.isNotEmpty;

    if (!hasAnything) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt, size: 14, color: AppTheme.warning),
              SizedBox(width: 6),
              Text(
                'LEMBRETES DO MESTRE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          if (poiReminders.isNotEmpty) ...[
            const SizedBox(height: 8),
            _section(context, 'Nesta cena', poiReminders),
          ],
          if (adventureReminders.isNotEmpty) ...[
            const SizedBox(height: 8),
            _section(context, 'Aventura', adventureReminders),
          ],
          if (escalations.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...escalations.map((e) => _escalationPreview(context, ref, e)),
          ],
          if (contextualSidebars.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...contextualSidebars
                .map((s) => _sidebarCard(context, s)),
          ],
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String label, List<String> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        ...bullets.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(fontSize: 12, color: AppTheme.warning)),
                Expanded(
                  child: Text(
                    b,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _escalationPreview(
    BuildContext context,
    WidgetRef ref,
    Escalation esc,
  ) {
    final nextStepIdx = esc.steps.indexWhere((s) => !s.fired);
    final nextStep = nextStepIdx >= 0 ? esc.steps[nextStepIdx] : null;
    final done = nextStep == null;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 12, color: AppTheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    esc.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                Text(
                  done
                      ? 'TODOS DISPARADOS'
                      : 'PRÓX. ${nextStepIdx + 1}/${esc.steps.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            if (nextStep != null) ...[
              const SizedBox(height: 6),
              Text(
                nextStep.label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (nextStep.trigger != null && nextStep.trigger!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '⚡ ${nextStep.trigger}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
              if (nextStep.effect != null && nextStep.effect!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  nextStep.effect!,
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _advanceEscalation(ref, esc, nextStepIdx),
                  icon: const Icon(Icons.skip_next, size: 14),
                  label: const Text('Disparar',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
            ] else if (esc.defaultOutcome != null &&
                esc.defaultOutcome!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Resultado: ${esc.defaultOutcome}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _advanceEscalation(
    WidgetRef ref,
    Escalation esc,
    int stepIdx,
  ) async {
    final db = ref.read(hiveDatabaseProvider);
    final newSteps = List<EscalationStep>.from(esc.steps);
    newSteps[stepIdx] = newSteps[stepIdx].copyWith(fired: true);
    await db.saveEscalation(esc.copyWith(
      steps: newSteps,
      currentStepIndex: stepIdx + 1,
    ));

    // Auto-chronicle: an escalation firing is a world beat worth remembering.
    final firedLabel = newSteps[stepIdx].label;
    final entry = await ref.read(chronicleServiceProvider).record(
          campaignId: esc.campaignId,
          title: 'Escalação: ${esc.title}',
          description: firedLabel,
          type: TimelineEntryType.worldEvent,
        );
    if (entry != null) {
      ref.invalidate(timelineEntriesProvider(esc.campaignId));
    }

    ref.invalidate(escalationsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  Widget _sidebarCard(BuildContext context, Sidebar sb) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.3),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding:
              const EdgeInsets.fromLTRB(10, 0, 10, 10),
          dense: true,
          leading: Icon(
            sb.playerFacing ? Icons.menu_book : Icons.bookmark,
            size: 14,
            color: AppTheme.accent,
          ),
          title: Text(
            sb.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            sb.kind,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          trailing: sb.playerFacing
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.fullscreen, size: 18),
                  tooltip: 'Mostrar aos Jogadores',
                  onPressed: () => _showHandoutFullscreen(context, sb),
                )
              : null,
          children: [
            Text(
              sb.body,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showHandoutFullscreen(BuildContext context, Sidebar sb) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).cardColor,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sb.title,
                      style: Theme.of(ctx).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    sb.body,
                    style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.5,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
