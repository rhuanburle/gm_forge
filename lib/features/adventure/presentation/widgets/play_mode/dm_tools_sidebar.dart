import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../../core/theme/app_theme.dart';

class DMToolsSidebar extends StatefulWidget {
  const DMToolsSidebar({super.key});

  @override
  State<DMToolsSidebar> createState() => _DMToolsSidebarState();
}

class _DMToolsSidebarState extends State<DMToolsSidebar> {
  final List<String> _rollHistory = [];

  void _rollDice(String dice) {
    int result = 0;
    String details = '';

    if (dice == 'd6') {
      result = Random().nextInt(6) + 1;
      details = 'd6';
    } else if (dice == '2d6') {
      final d1 = Random().nextInt(6) + 1;
      final d2 = Random().nextInt(6) + 1;
      result = d1 + d2;
      details = '($d1 + $d2)';
    } else if (dice == 'd20') {
      result = Random().nextInt(20) + 1;
      details = 'd20';
    } else if (dice == 'd66') {
      final d1 = Random().nextInt(6) + 1;
      final d2 = Random().nextInt(6) + 1;
      result = int.parse('$d1$d2');
      details = 'Evento (d66)';
    } else if (dice == 'd100') {
      result = Random().nextInt(100) + 1;
      details = 'd100';
    }

    setState(() {
      _rollHistory.insert(0, '$result - $details');
      if (_rollHistory.length > 20) {
        _rollHistory.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.secondary.withValues(alpha: 0.1),
            width: double.infinity,
            child: const Text(
              'Ferramentas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Dados',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _DiceButton('d6', () => _rollDice('d6')),
              _DiceButton('2d6', () => _rollDice('2d6')),
              _DiceButton('d66', () => _rollDice('d66'), highlight: true),
              _DiceButton('d20', () => _rollDice('d20')),
              _DiceButton('d100', () => _rollDice('d100')),
            ],
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Histórico de Rolagens',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _rollHistory.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _rollHistory[index],
                    style: TextStyle(
                      fontWeight: index == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool highlight;

  const _DiceButton(this.label, this.onPressed, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: highlight ? AppTheme.secondary : Colors.grey[200],
          foregroundColor: highlight ? Colors.white : Colors.black87,
          elevation: highlight ? 2 : 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
