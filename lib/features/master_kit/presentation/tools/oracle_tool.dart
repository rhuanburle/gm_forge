import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// System-agnostic "yes/no" oracle plus a random focus prompt, for improvising
/// answers to questions the prep never covered. Pure — no persistence.
class OracleTool extends StatefulWidget {
  const OracleTool({super.key});

  @override
  State<OracleTool> createState() => _OracleToolState();
}

enum _Likelihood { veryUnlikely, unlikely, fifty, likely, veryLikely }

extension _LikelihoodX on _Likelihood {
  String get label => switch (this) {
        _Likelihood.veryUnlikely => 'Muito improvável',
        _Likelihood.unlikely => 'Improvável',
        _Likelihood.fifty => '50 / 50',
        _Likelihood.likely => 'Provável',
        _Likelihood.veryLikely => 'Muito provável',
      };

  /// Chance (out of 100) that the answer is "yes".
  int get yesChance => switch (this) {
        _Likelihood.veryUnlikely => 15,
        _Likelihood.unlikely => 35,
        _Likelihood.fifty => 50,
        _Likelihood.likely => 65,
        _Likelihood.veryLikely => 85,
      };
}

class _OracleToolState extends State<OracleTool> {
  static final _rng = Random();

  _Likelihood _likelihood = _Likelihood.fifty;
  String? _answer;
  bool _answerPositive = false;
  String? _focus;

  static const _actions = [
    'Ataca', 'Ajuda', 'Trai', 'Esconde', 'Revela', 'Persegue', 'Foge',
    'Exige', 'Oferece', 'Ameaça', 'Protege', 'Rouba', 'Abandona',
    'Corrompe', 'Liberta', 'Vigia', 'Sabota', 'Une', 'Divide', 'Sacrifica',
  ];
  static const _themes = [
    'um aliado', 'um inimigo', 'um segredo', 'um lugar', 'um objeto',
    'o passado', 'uma dívida', 'a fé', 'o poder', 'a verdade',
    'um inocente', 'uma promessa', 'o dinheiro', 'a morte', 'um plano',
    'uma facção', 'a natureza', 'um ritual', 'a família', 'o medo',
  ];

  void _ask() {
    final roll = _rng.nextInt(100) + 1; // 1..100
    final chance = _likelihood.yesChance;
    final yes = roll <= chance;

    // Nuance: extremes of the winning band add "e…" / "mas…".
    String suffix = '';
    if (yes) {
      if (roll <= (chance * 0.2).ceil()) {
        suffix = ', e mais ainda…';
      } else if (roll > (chance * 0.8).floor()) {
        suffix = ', mas há um custo…';
      }
    } else {
      final noBand = 100 - chance;
      final into = roll - chance; // 1..noBand
      if (into > (noBand * 0.8).floor()) {
        suffix = ', e piora…';
      } else if (into <= (noBand * 0.2).ceil()) {
        suffix = ', mas há uma brecha…';
      }
    }

    setState(() {
      _answerPositive = yes;
      _answer = '${yes ? 'Sim' : 'Não'}$suffix';
    });
  }

  void _rollFocus() {
    setState(() {
      _focus =
          '${_actions[_rng.nextInt(_actions.length)]} · ${_themes[_rng.nextInt(_themes.length)]}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _answer == null
        ? AppTheme.secondary
        : (_answerPositive ? AppTheme.success : AppTheme.error);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quão provável é a resposta ser "sim"?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in _Likelihood.values)
                ChoiceChip(
                  label: Text(l.label),
                  selected: _likelihood == l,
                  onSelected: (_) => setState(() => _likelihood = l),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _ask,
            icon: const Icon(Icons.help_outline),
            label: const Text('Perguntar ao oráculo'),
          ),
          const SizedBox(height: 20),
          if (_answer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                _answer!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),
          Text('Travou? Um empurrão aleatório:',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _rollFocus,
            icon: const Icon(Icons.bolt),
            label: const Text('Foco aleatório'),
          ),
          if (_focus != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.discovery.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.discovery.withValues(alpha: 0.3)),
              ),
              child: Text(
                _focus!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
