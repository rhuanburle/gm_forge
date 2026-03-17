import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/active_adventure_state.dart';

class ExplorationTrackerPanel extends ConsumerStatefulWidget {
  const ExplorationTrackerPanel({super.key});

  @override
  ConsumerState<ExplorationTrackerPanel> createState() =>
      _ExplorationTrackerPanelState();
}

class _ExplorationTrackerPanelState
    extends ConsumerState<ExplorationTrackerPanel> {
  /// Tracks which counter IDs triggered an alert on the last increment
  final Set<String> _flashingIds = {};

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activeAdventureProvider);
    final items = activeState.trackerItems;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: items.isNotEmpty,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: const Icon(Icons.explore, size: 16, color: AppTheme.secondary),
        title: Row(
          children: [
            const Text(
              'Rastreador',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              InkWell(
                onTap: _showResetConfirm,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.restart_alt, size: 14, color: AppTheme.textMuted),
                ),
              ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _showAddDialog(context),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add, size: 14, color: AppTheme.secondary),
              ),
            ),
          ],
        ),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Adicione contadores ou checkboxes\npara rastrear turnos, recursos, etc.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            )
          else
            ...items.map((item) => _buildTrackerRow(item)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tracker row
  // ---------------------------------------------------------------------------

  Widget _buildTrackerRow(TrackerItem item) {
    if (item.type == TrackerItemType.checkbox) {
      return _buildCheckboxRow(item);
    }
    return _buildCounterRow(item);
  }

  Widget _buildCounterRow(TrackerItem item) {
    final isFlashing = _flashingIds.contains(item.id);
    final isAtMax = item.maxValue > 0 && item.value >= item.maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isFlashing
              ? AppTheme.warning.withValues(alpha: 0.2)
              : isAtMax
                  ? AppTheme.error.withValues(alpha: 0.08)
                  : AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isFlashing
                ? AppTheme.warning.withValues(alpha: 0.6)
                : isAtMax
                    ? AppTheme.error.withValues(alpha: 0.3)
                    : AppTheme.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Remove button
            _tinyButton(
              icon: Icons.close,
              color: AppTheme.error,
              onPressed: () => _removeItem(item.id),
            ),
            const SizedBox(width: 6),
            // Label
            Expanded(
              child: GestureDetector(
                onTap: () => _showEditDialog(context, item),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isFlashing ? AppTheme.warning : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Decrement
            _tinyButton(
              icon: Icons.remove,
              onPressed: item.value > 0
                  ? () => _updateCounter(item, -1)
                  : null,
            ),
            // Value display
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: Text(
                item.maxValue > 0
                    ? '${item.value}/${item.maxValue}'
                    : '${item.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFlashing
                      ? AppTheme.warning
                      : isAtMax
                          ? AppTheme.error
                          : null,
                ),
              ),
            ),
            // Increment
            _tinyButton(
              icon: Icons.add,
              onPressed: (item.maxValue > 0 && item.value >= item.maxValue)
                  ? null
                  : () => _updateCounter(item, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(TrackerItem item) {
    final checked = item.value != 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          _tinyButton(
            icon: Icons.close,
            color: AppTheme.error,
            onPressed: () => _removeItem(item.id),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: checked,
              onChanged: (_) => _toggleCheckbox(item),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: AppTheme.success,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleCheckbox(item),
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? AppTheme.textMuted : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _updateCounter(TrackerItem item, int delta) {
    final notifier = ref.read(activeAdventureProvider.notifier);
    final newValue = (item.value + delta).clamp(
      0,
      item.maxValue > 0 ? item.maxValue : 999,
    );
    notifier.updateTrackerItem(item.id, value: newValue);

    // Alert check
    if (delta > 0 && item.alertEvery > 0 && newValue > 0 && newValue % item.alertEvery == 0) {
      setState(() => _flashingIds.add(item.id));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _flashingIds.remove(item.id));
      });
    }
  }

  void _toggleCheckbox(TrackerItem item) {
    final notifier = ref.read(activeAdventureProvider.notifier);
    notifier.updateTrackerItem(item.id, value: item.value == 0 ? 1 : 0);
  }

  void _removeItem(String itemId) {
    ref.read(activeAdventureProvider.notifier).removeTrackerItem(itemId);
  }

  void _showResetConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetar rastreadores?'),
        content: const Text('Todos os contadores e checkboxes voltarão a zero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(activeAdventureProvider.notifier).resetAllTrackers();
              Navigator.pop(ctx);
            },
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add dialog
  // ---------------------------------------------------------------------------

  void _showAddDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    final alertCtrl = TextEditingController();
    var selectedType = TrackerItemType.counter;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Rastreador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    hintText: 'Ex: Turno, Tocha, Ração...',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                SegmentedButton<TrackerItemType>(
                  segments: const [
                    ButtonSegment(
                      value: TrackerItemType.counter,
                      label: Text('Contador'),
                      icon: Icon(Icons.exposure_plus_1, size: 16),
                    ),
                    ButtonSegment(
                      value: TrackerItemType.checkbox,
                      label: Text('Checkbox'),
                      icon: Icon(Icons.check_box_outlined, size: 16),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) =>
                      setDialogState(() => selectedType = s.first),
                ),
                if (selectedType == TrackerItemType.counter) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Valor Máximo (opcional)',
                      hintText: '0 = sem limite',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: alertCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alertar a cada N (opcional)',
                      hintText: 'Ex: 3 = alerta no 3, 6, 9...',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                final item = TrackerItem.create(
                  label: label,
                  type: selectedType,
                  maxValue: int.tryParse(maxCtrl.text.trim()) ?? 0,
                  alertEvery: int.tryParse(alertCtrl.text.trim()) ?? 0,
                );
                ref.read(activeAdventureProvider.notifier).addTrackerItem(item);
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit dialog
  // ---------------------------------------------------------------------------

  void _showEditDialog(BuildContext context, TrackerItem item) {
    final labelCtrl = TextEditingController(text: item.label);
    final maxCtrl = TextEditingController(
      text: item.maxValue > 0 ? '${item.maxValue}' : '',
    );
    final alertCtrl = TextEditingController(
      text: item.alertEvery > 0 ? '${item.alertEvery}' : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Rastreador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              if (item.type == TrackerItemType.counter) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: maxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Valor Máximo',
                    hintText: '0 = sem limite',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alertCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alertar a cada N',
                    hintText: '0 = desligado',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              ref.read(activeAdventureProvider.notifier).updateTrackerItem(
                item.id,
                label: label,
                maxValue: int.tryParse(maxCtrl.text.trim()) ?? 0,
                alertEvery: int.tryParse(alertCtrl.text.trim()) ?? 0,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _tinyButton({
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 22,
      height: 22,
      child: IconButton(
        icon: Icon(icon, size: 13),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: color ?? AppTheme.textMuted,
        disabledColor: AppTheme.textMuted.withValues(alpha: 0.3),
      ),
    );
  }
}
