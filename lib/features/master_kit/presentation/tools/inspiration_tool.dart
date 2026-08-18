import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../adventure/domain/campaign.dart';

/// Rolls on the built-in inspiration tables (atmosphere beats, complications,
/// room descriptions, flash NPCs). Reuses [InspirationTable.defaults] so the
/// Kit and the play-mode panel stay in sync.
class InspirationTool extends StatefulWidget {
  const InspirationTool({super.key});

  @override
  State<InspirationTool> createState() => _InspirationToolState();
}

class _InspirationToolState extends State<InspirationTool> {
  static final _rng = Random();
  final _tables = InspirationTable.defaults();

  late InspirationTable _selected = _tables.first;
  String? _result;

  void _roll() {
    if (_selected.entries.isEmpty) return;
    setState(() {
      _result = _selected.entries[_rng.nextInt(_selected.entries.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<InspirationTable>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'Tabela',
              prefixIcon: Icon(Icons.list_alt),
            ),
            items: _tables
                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selected = v;
                _result = null;
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _roll,
            icon: const Icon(Icons.casino),
            label: const Text('Rolar na tabela'),
          ),
          const SizedBox(height: 20),
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.narrative.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.narrative.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _result!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _result!));
                      AppSnackBar.success(context, 'Copiado!');
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
