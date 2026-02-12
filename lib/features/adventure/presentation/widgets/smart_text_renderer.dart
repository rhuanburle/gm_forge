import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/creature.dart';
import '../../domain/point_of_interest.dart';
import '../../application/adventure_providers.dart';

class SmartTextRenderer extends ConsumerWidget {
  final String text;
  final String adventureId;
  final TextStyle? style;
  final TextAlign textAlign;

  const SmartTextRenderer({
    super.key,
    required this.text,
    required this.adventureId,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (text.isEmpty) return const SizedBox.shrink();

    final spans = _parseText(context, ref);

    return RichText(
      text: TextSpan(
        children: spans,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      textAlign: textAlign,
    );
  }

  List<InlineSpan> _parseText(BuildContext context, WidgetRef ref) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'\[([^\]]+)\]\(([^:]+):([^)]+)\)');

    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final String label = match.group(1)!;
      final String type = match.group(2)!;
      final String id = match.group(3)!;

      spans.add(_createLinkSpan(context, ref, label, type, id));

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  InlineSpan _createLinkSpan(
    BuildContext context,
    WidgetRef ref,
    String label,
    String type,
    String id,
  ) {
    Color linkColor;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'creature':
      case 'npc':
      case 'monster':
        linkColor = AppTheme.accent;
        icon = Icons.pets;
        break;
      case 'location':
      case 'poi':
      case 'room':
        linkColor = AppTheme.primary;
        icon = Icons.place;
        break;
      default:
        linkColor = AppTheme.secondary;
        icon = Icons.link;
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () => _handleLinkTap(context, ref, type, id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: linkColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: linkColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: linkColor),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: linkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: (style?.fontSize ?? 14) * 0.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLinkTap(
    BuildContext context,
    WidgetRef ref,
    String type,
    String id,
  ) {
    switch (type.toLowerCase()) {
      case 'creature':
      case 'npc':
      case 'monster':
        _showCreatureDetails(context, ref, id);
        break;
      case 'location':
      case 'poi':
      case 'room':
        _showLocationDetails(context, ref, id);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tipo de link desconhecido: $type')),
        );
    }
  }

  void _showCreatureDetails(BuildContext context, WidgetRef ref, String id) {
    final creatures = ref.read(creaturesProvider(adventureId));
    try {
      final creature = creatures.firstWhere((c) => c.id == id);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                creature.type == CreatureType.npc ? Icons.person : Icons.pets,
                color: creature.type == CreatureType.npc
                    ? Colors.purple
                    : AppTheme.accent,
              ),
              const SizedBox(width: 8),
              Text(creature.name),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (creature.description.isNotEmpty) ...[
                  Text(
                    creature.description,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                ],
                _DetailRow('Motivação', creature.motivation),
                const SizedBox(height: 8),
                _DetailRow('Ao Perder', creature.losingBehavior),
                if (creature.stats.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Ficha',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: Text(
                      creature.stats,
                      style: const TextStyle(fontFamily: 'monospace'),
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
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Criatura não encontrada (pode ter sido excluída)'),
        ),
      );
    }
  }

  void _showLocationDetails(BuildContext context, WidgetRef ref, String id) {
    final pois = ref.read(pointsOfInterestProvider(adventureId));
    try {
      final poi = pois.firstWhere((p) => p.id == id);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.place, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('#${poi.number} ${poi.name}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(poi.purpose.displayName)),
                    if (poi.connections.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.arrow_forward, size: 14),
                        label: Text('Conexões: ${poi.connections.join(", ")}'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow('Primeira Impressão', poi.firstImpression),
                const SizedBox(height: 8),
                _DetailRow('O Óbvio', poi.obvious),
                const SizedBox(height: 8),
                _DetailRow('O Detalhe', poi.detail),
                if (poi.treasure.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow('Tesouro', poi.treasure, icon: Icons.diamond),
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
        ),
      );
    } catch (_) {
      try {
        final number = int.tryParse(id);
        if (number != null) {
          pois.firstWhere((p) => p.number == number);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Local não encontrado pelo ID')),
          );
          return;
        }
      } catch (__) {}

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Local não encontrado')));
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String text;
  final IconData? icon;

  const _DetailRow(this.label, this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppTheme.secondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        Text(text.isEmpty ? '-' : text),
      ],
    );
  }
}
