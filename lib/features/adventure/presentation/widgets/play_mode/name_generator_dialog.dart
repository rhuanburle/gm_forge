import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_theme.dart';

class NameGeneratorDialog extends StatefulWidget {
  const NameGeneratorDialog({super.key});

  @override
  State<NameGeneratorDialog> createState() => _NameGeneratorDialogState();
}

enum _NameCategory { humano, elfo, anao, orc, taverna, loja }

extension _NameCategoryExtension on _NameCategory {
  String get displayName {
    switch (this) {
      case _NameCategory.humano:
        return 'Humano';
      case _NameCategory.elfo:
        return 'Elfo';
      case _NameCategory.anao:
        return 'Anão';
      case _NameCategory.orc:
        return 'Orc';
      case _NameCategory.taverna:
        return 'Taverna';
      case _NameCategory.loja:
        return 'Loja';
    }
  }
}

class _NameGeneratorDialogState extends State<NameGeneratorDialog> {
  static final _random = Random();

  _NameCategory _selectedCategory = _NameCategory.humano;
  String _generatedName = '';

  static const Map<_NameCategory, List<String>> _nameLists = {
    _NameCategory.humano: [
      'Alaric',
      'Cedric',
      'Isolde',
      'Maren',
      'Theron',
      'Brynn',
      'Aldara',
      'Corwin',
      'Elara',
      'Gareth',
    ],
    _NameCategory.elfo: [
      'Aelindra',
      'Caelith',
      'Faenor',
      'Lúthien',
      'Sylvara',
      'Thalion',
      'Aelarion',
      'Miriel',
      'Elowen',
      'Galadorn',
    ],
    _NameCategory.anao: [
      'Thorin',
      'Brokk',
      'Gilda',
      'Durin',
      'Helga',
      'Balin',
      'Dagna',
      'Grundi',
      'Hilda',
      'Torin',
    ],
    _NameCategory.orc: [
      'Grukash',
      'Thokk',
      'Mogra',
      'Urzog',
      'Shagga',
      'Borgol',
      'Nargul',
      'Krazzt',
      'Lugdush',
      'Azog',
    ],
    _NameCategory.taverna: [
      'O Barril Dourado',
      'A Caneca Rachada',
      'O Dragão Bêbado',
      'A Lança Enferrujada',
      'O Javali Risonho',
      'A Taverna do Corvo',
      'O Cálice de Prata',
    ],
    _NameCategory.loja: [
      'Empório do Alquimista',
      'Ferraria do Martelo Negro',
      'Pergaminhos & Poções',
      'O Bazar Arcano',
      'Suprimentos do Aventureiro',
      'A Forja Rúnica',
    ],
  };

  void _generate() {
    final names = _nameLists[_selectedCategory]!;
    setState(() {
      _generatedName = names[_random.nextInt(names.length)];
    });
  }

  void _copyToClipboard() {
    if (_generatedName.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedName));
    AppSnackBar.success(context, 'Nome copiado!');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.discovery),
          SizedBox(width: 8),
          Text('Gerador de Nomes'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category selector
            DropdownButtonFormField<_NameCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.category),
              ),
              items: _NameCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _generatedName = '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.casino),
                label: const Text('Gerar'),
                onPressed: _generate,
              ),
            ),
            const SizedBox(height: 24),

            // Generated name display
            if (_generatedName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.discovery.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _generatedName,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar'),
                      onPressed: _copyToClipboard,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
