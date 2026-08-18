import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// The walk-on nobody prepped: a name, a face/quirk and a motive in one roll.
/// Pure and system-agnostic — the names lean generic-fantasy but the traits and
/// motives work for any setting.
class NpcFlashTool extends StatefulWidget {
  const NpcFlashTool({super.key});

  @override
  State<NpcFlashTool> createState() => _NpcFlashToolState();
}

class _NpcFlashToolState extends State<NpcFlashTool> {
  static final _rng = Random();

  String? _name;
  String? _trait;
  String? _motive;

  static const _names = [
    'Alaric', 'Maren', 'Cedric', 'Isolde', 'Theron', 'Brynn', 'Aldara',
    'Corwin', 'Elara', 'Gareth', 'Sela', 'Doran', 'Ivette', 'Kaspar',
    'Lira', 'Bram', 'Nessa', 'Orin', 'Petra', 'Rus', 'Talia', 'Veska',
    'Hollis', 'Marta', 'Osvald', 'Fenn', 'Dagna', 'Yorick', 'Cora', 'Emeric',
  ];
  static const _traits = [
    'Cicatriz atravessando o olho, fala arrastando as palavras',
    'Mãos calejadas, ri alto e cedo demais',
    'Magro, olhar que não pousa em nada',
    'Cheira a fumaça, coça sempre o antebraço',
    'Voz rouca, guarda uma moeda entre os dedos',
    'Sorriso fácil, dentes de ouro',
    'Manca da perna esquerda, veste bem demais para o lugar',
    'Tatuagem desbotada no pescoço, sussurra ao falar',
    'Jovem demais para o cargo, fala rápido quando nervoso',
    'Cabelo grisalho preso às pressas, unhas roídas',
    'Enorme e silencioso, evita o olhar dos outros',
    'Elegante e sujo ao mesmo tempo, cheira a vinho',
    'Olhos de cores diferentes, mexe num amuleto',
    'Rosto queimado de sol, gargalhada seca',
    'Baixo e atarracado, aperta a mão forte demais',
  ];
  static const _motives = [
    'Quer pagar uma dívida antes que cobrem à força',
    'Procura um parente que sumiu há anos',
    'Esconde algo do próprio patrão',
    'Quer provar valor a quem o despreza',
    'Busca vingança e finge que não',
    'Só quer sair da cidade sem ser notado',
    'Protege alguém que não merece',
    'Está atrás de um item que perdeu (ou roubaram)',
    'Acredita numa profecia que ninguém mais leva a sério',
    'Vende informação — verdadeira ou não, tanto faz',
    'Precisa de dinheiro rápido e não é orgulhoso',
    'Quer um favor que só aventureiros podem dar',
    'Guarda um segredo que pesa mais a cada dia',
    'Testa os PJs antes de confiar neles',
    'Trabalha para os dois lados e sabe que é perigoso',
  ];

  void _generate() {
    setState(() {
      _name = _names[_rng.nextInt(_names.length)];
      _trait = _traits[_rng.nextInt(_traits.length)];
      _motive = _motives[_rng.nextInt(_motives.length)];
    });
  }

  void _copy() {
    if (_name == null) return;
    Clipboard.setData(ClipboardData(text: '$_name — $_trait. $_motive.'));
    AppSnackBar.success(context, 'PNJ copiado!');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.casino),
            label: Text(_name == null ? 'Gerar PNJ' : 'Gerar outro'),
          ),
          const SizedBox(height: 20),
          if (_name != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.discovery.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _line(context, Icons.face, _trait!),
                  const SizedBox(height: 6),
                  _line(context, Icons.flag, _motive!),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}
