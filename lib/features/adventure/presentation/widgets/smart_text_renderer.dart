import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/domain.dart';
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
        style: Theme.of(context).textTheme.bodyMedium?.merge(style),
      ),
      textAlign: textAlign,
    );
  }

  List<InlineSpan> _parseText(BuildContext context, WidgetRef ref) {
    final List<InlineSpan> spans = [];
    // Matches [Label](Type:ID) OR [@Name], [#Name], [!Name]
    final RegExp exp = RegExp(
      r'\[([^\]]+)\]\(([^:]+):([^)]+)\)|\[([@#!])([^\]]+)\]',
    );

    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      if (match.group(1) != null) {
        // Old Format: [Label](Type:ID)
        final String label = match.group(1)!;
        final String type = match.group(2)!;
        final String id = match.group(3)!;
        spans.add(_createLinkSpan(context, ref, label, type, id: id));
      } else {
        // New Format: [@Name], [#Name], [!Name]
        final String trigger = match.group(4)!;
        final String name = match.group(5)!;
        String type;
        String label = name;

        switch (trigger) {
          case '@':
            type = 'creature';
            break;
          case '#':
            type = 'location';
            break;
          case '!':
            type = 'fact';
            break;
          default:
            type = 'unknown';
        }

        spans.add(_createLinkSpan(context, ref, label, type, nameSearch: name));
      }

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
    String type, {
    String? id,
    String? nameSearch,
  }) {
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
      case 'fact':
        linkColor = AppTheme.secondary;
        icon = Icons.lightbulb;
        break;
      default:
        linkColor = AppTheme.secondary;
        icon = Icons.link;
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () => _handleLinkTap(context, ref, type, id, nameSearch),
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
    String? id,
    String? nameSearch,
  ) {
    switch (type.toLowerCase()) {
      case 'creature':
      case 'npc':
      case 'monster':
        _showCreatureDetails(context, ref, id, nameSearch);
        break;
      case 'location':
      case 'poi':
      case 'room':
        _showLocationDetails(context, ref, id, nameSearch);
        break;
      case 'fact':
        _showFactDetails(context, ref, id, nameSearch);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tipo de link desconhecido: $type')),
        );
    }
  }

  void _showCreatureDetails(
    BuildContext context,
    WidgetRef ref,
    String? id,
    String? nameSearch,
  ) {
    final creatures = ref.read(creaturesProvider(adventureId));
    try {
      final creature = creatures.firstWhere(
        (c) => id != null ? c.id == id : c.name == nameSearch,
      );

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

  void _showLocationDetails(
    BuildContext context,
    WidgetRef ref,
    String? id,
    String? nameSearch,
  ) {
    final pois = ref.read(pointsOfInterestProvider(adventureId));
    final locations = ref.read(locationsProvider(adventureId));

    try {
      if (id != null) {
        try {
          final poi = pois.firstWhere((p) => p.id == id);
          _displayPoi(context, poi);
          return;
        } catch (_) {
          final loc = locations.firstWhere((l) => l.id == id);
          _displayLocation(context, loc);
          return;
        }
      }

      if (nameSearch != null) {
        if (nameSearch.startsWith('#')) {
          final numPart = nameSearch.split(' ').first.substring(1);
          final num = int.tryParse(numPart);
          if (num != null) {
            final poi = pois.firstWhere((p) => p.number == num);
            _displayPoi(context, poi);
            return;
          }
        }

        try {
          final poi = pois.firstWhere((p) => p.name == nameSearch);
          _displayPoi(context, poi);
          return;
        } catch (_) {}

        final loc = locations.firstWhere((l) => l.name == nameSearch);
        _displayLocation(context, loc);
        return;
      }
    } catch (_) {}

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local não encontrado')));
  }

  void _showFactDetails(
    BuildContext context,
    WidgetRef ref,
    String? id,
    String? nameSearch,
  ) {
    final facts = ref.read(factsProvider(adventureId));
    try {
      final fact = facts.firstWhere(
        (f) => id != null ? f.id == id : f.content == nameSearch,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.secondary),
              const SizedBox(width: 8),
              Text('Fato / Rumor'),
            ],
          ),
          content: Text(fact.content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fato não encontrado')));
    }
  }

  void _displayPoi(BuildContext context, PointOfInterest poi) {
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
  }

  void _displayLocation(BuildContext context, Location loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.map, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(loc.name),
          ],
        ),
        content: Text(loc.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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
