import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Dice roll model & state
// ---------------------------------------------------------------------------

class DiceRoll {
  final int sides;
  final int count;
  final List<int> results;
  final int modifier;
  final DateTime timestamp;

  const DiceRoll({
    required this.sides,
    this.count = 1,
    required this.results,
    this.modifier = 0,
    required this.timestamp,
  });

  int get total => results.fold(0, (sum, r) => sum + r) + modifier;

  String get label {
    final base = count > 1 ? '${count}d$sides' : 'd$sides';
    if (modifier > 0) return '$base+$modifier';
    if (modifier < 0) return '$base$modifier';
    return base;
  }

  String get resultText {
    if (count == 1 && modifier == 0) return '$total';
    final rolls = results.join(', ');
    if (modifier != 0) return '[$rolls] ${modifier > 0 ? "+" : ""}$modifier = $total';
    return '[$rolls] = $total';
  }

  bool get isNat20 => sides == 20 && count == 1 && results.first == 20;
  bool get isNat1 => sides == 20 && count == 1 && results.first == 1;
}

class DiceState {
  final List<DiceRoll> history;
  final DiceRoll? lastRoll;

  const DiceState({
    this.history = const [],
    this.lastRoll,
  });

  DiceState copyWith({List<DiceRoll>? history, DiceRoll? lastRoll}) {
    return DiceState(
      history: history ?? this.history,
      lastRoll: lastRoll ?? this.lastRoll,
    );
  }
}

class DiceNotifier extends Notifier<DiceState> {
  final _rng = Random();

  @override
  DiceState build() => const DiceState();

  DiceRoll roll(int sides, {int count = 1, int modifier = 0}) {
    final results = List.generate(count, (_) => _rng.nextInt(sides) + 1);
    final diceRoll = DiceRoll(
      sides: sides,
      count: count,
      results: results,
      modifier: modifier,
      timestamp: DateTime.now(),
    );

    final history = [diceRoll, ...state.history];
    // Keep last 20 rolls
    state = DiceState(
      history: history.length > 20 ? history.sublist(0, 20) : history,
      lastRoll: diceRoll,
    );
    return diceRoll;
  }

  void clear() {
    state = const DiceState();
  }
}

final diceProvider = NotifierProvider<DiceNotifier, DiceState>(
  DiceNotifier.new,
);

// ---------------------------------------------------------------------------
// Dice roller widget
// ---------------------------------------------------------------------------

class DiceRollerPanel extends ConsumerStatefulWidget {
  const DiceRollerPanel({super.key});

  @override
  ConsumerState<DiceRollerPanel> createState() => _DiceRollerPanelState();
}

class _DiceRollerPanelState extends ConsumerState<DiceRollerPanel>
    with SingleTickerProviderStateMixin {
  bool _showHistory = false;
  bool _showAdvanced = false;
  int _count = 1;
  int _modifier = 0;

  @override
  Widget build(BuildContext context) {
    final dice = ref.watch(diceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.casino, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rolador de Dados',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (dice.history.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _showHistory ? Icons.expand_less : Icons.history,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Histórico',
                  color: AppTheme.textMuted,
                ),
            ],
          ),
        ),

        // Last result
        if (dice.lastRoll != null)
          _LastRollDisplay(roll: dice.lastRoll!),

        // Dice buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [4, 6, 8, 10, 12, 20, 100].map((sides) {
              return _DiceButton(
                sides: sides,
                onTap: () {
                  ref.read(diceProvider.notifier).roll(
                    sides,
                    count: _count,
                    modifier: _modifier,
                  );
                },
              );
            }).toList(),
          ),
        ),

        // Advanced options toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAdvanced ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAdvanced ? 'Menos opções' : 'Mais opções',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Advanced: count and modifier
        if (_showAdvanced)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Count
                const Text('Qtd:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.remove, size: 14),
                  onPressed: _count > 1 ? () => setState(() => _count--) : null,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 14,
                ),
                Text('$_count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  onPressed: () => setState(() => _count++),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 14,
                ),
                const SizedBox(width: 16),
                // Modifier
                const Text('Mod:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.remove, size: 14),
                  onPressed: () => setState(() => _modifier--),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 14,
                ),
                Text(
                  _modifier >= 0 ? '+$_modifier' : '$_modifier',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  onPressed: () => setState(() => _modifier++),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  iconSize: 14,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _count = 1;
                    _modifier = 0;
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),

        // History
        if (_showHistory && dice.history.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: dice.history.length,
              itemBuilder: (ctx, idx) {
                final roll = dice.history[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          roll.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: idx == 0 ? AppTheme.secondary : AppTheme.textMuted,
                            fontWeight: idx == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          roll.resultText,
                          style: TextStyle(
                            fontSize: 10,
                            color: idx == 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${roll.timestamp.hour.toString().padLeft(2, '0')}:${roll.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        const Divider(height: 1),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Last roll result display
// ---------------------------------------------------------------------------

class _LastRollDisplay extends StatelessWidget {
  final DiceRoll roll;

  const _LastRollDisplay({required this.roll});

  @override
  Widget build(BuildContext context) {
    Color resultColor = AppTheme.textPrimary;
    String? badge;

    if (roll.isNat20) {
      resultColor = AppTheme.success;
      badge = 'CRÍTICO!';
    } else if (roll.isNat1) {
      resultColor = AppTheme.combat;
      badge = 'FALHA!';
    }

    final isCritical = roll.isNat20 || roll.isNat1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: resultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: resultColor.withValues(alpha: isCritical ? 0.6 : 0.3),
          width: isCritical ? 2 : 1,
        ),
        boxShadow: isCritical
            ? [
                BoxShadow(
                  color: resultColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            roll.label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${roll.total}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          if (roll.count > 1 || roll.modifier != 0) ...[
            const SizedBox(width: 8),
            Text(
              roll.resultText,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual dice button
// ---------------------------------------------------------------------------

class _DiceButton extends StatefulWidget {
  final int sides;
  final VoidCallback onTap;

  const _DiceButton({required this.sides, required this.onTap});

  @override
  State<_DiceButton> createState() => _DiceButtonState();
}

class _DiceButtonState extends State<_DiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'd${widget.sides}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
