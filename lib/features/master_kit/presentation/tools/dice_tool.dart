import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Pure dice roller — no adventure/campaign context. Quick dice buttons plus a
/// free-form "NdM+K" formula, with a short roll history.
class DiceTool extends StatefulWidget {
  const DiceTool({super.key});

  @override
  State<DiceTool> createState() => _DiceToolState();
}

class _DiceToolState extends State<DiceTool> {
  static final _rng = Random();
  final _formulaCtrl = TextEditingController();
  final List<String> _history = [];
  String _last = '';

  static const _quick = [4, 6, 8, 10, 12, 20, 100];

  @override
  void dispose() {
    _formulaCtrl.dispose();
    super.dispose();
  }

  void _rollDie(int sides) {
    final r = _rng.nextInt(sides) + 1;
    _record('d$sides', '$r', r.toString());
  }

  void _rollFormula() {
    final raw = _formulaCtrl.text.trim();
    if (raw.isEmpty) return;
    final parsed = _parse(raw);
    if (parsed == null) {
      setState(() => _last = 'Fórmula inválida — use algo como 2d6+3');
      return;
    }
    _record(raw, parsed.$1, parsed.$2);
  }

  /// Returns (total, breakdown) or null if unparseable.
  (String, String)? _parse(String input) {
    final m = RegExp(r'^(\d*)d(\d+)\s*([+-]\s*\d+)?$', caseSensitive: false)
        .firstMatch(input.replaceAll(' ', ''));
    if (m == null) return null;
    final count = int.tryParse(m.group(1) ?? '') ?? 1;
    final sides = int.tryParse(m.group(2)!) ?? 0;
    if (count < 1 || count > 100 || sides < 2 || sides > 1000) return null;
    final mod = int.tryParse((m.group(3) ?? '0').replaceAll(' ', '')) ?? 0;
    final rolls = List.generate(count, (_) => _rng.nextInt(sides) + 1);
    final total = rolls.fold<int>(0, (a, b) => a + b) + mod;
    final modStr = mod == 0 ? '' : (mod > 0 ? ' + $mod' : ' - ${mod.abs()}');
    final breakdown = count == 1 && mod == 0
        ? '$total'
        : '${rolls.join(' + ')}$modStr = $total';
    return ('$total', breakdown);
  }

  void _record(String label, String total, String breakdown) {
    setState(() {
      _last = '$label → $total';
      _history.insert(0, '$label:  $breakdown');
      if (_history.length > 12) _history.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _quick)
                ElevatedButton(
                  onPressed: () => _rollDie(s),
                  child: Text('d$s'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _formulaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fórmula',
                    hintText: '2d6+3',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _rollFormula(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _rollFormula,
                icon: const Icon(Icons.casino, size: 18),
                label: const Text('Rolar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_last.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _last,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Histórico',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._history.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(h,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondary)),
                )),
          ],
        ],
      ),
    );
  }
}
