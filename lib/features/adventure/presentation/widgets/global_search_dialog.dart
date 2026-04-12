import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';

/// A full-adventure search dialog that indexes every entity type
/// (creatures, locations, POIs, quests, items, factions, legends, facts)
/// and lets the GM jump directly to any result.
class GlobalSearchDialog extends ConsumerStatefulWidget {
  final String adventureId;

  const GlobalSearchDialog({super.key, required this.adventureId});

  @override
  ConsumerState<GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adventureId = widget.adventureId;
    final creatures = ref.watch(creaturesProvider(adventureId));
    final locations = ref.watch(locationsProvider(adventureId));
    final pois = ref.watch(pointsOfInterestProvider(adventureId));
    final quests = ref.watch(questsProvider(adventureId));
    final items = ref.watch(itemsProvider(adventureId));
    final factions = ref.watch(factionsProvider(adventureId));
    final legends = ref.watch(legendsProvider(adventureId));
    final facts = ref.watch(factsProvider(adventureId));

    final results = _query.isEmpty
        ? <_SearchResult>[]
        : _buildResults(
            q: _query.toLowerCase(),
            creatures: creatures,
            locations: locations,
            pois: pois,
            quests: quests,
            items: items,
            factions: factions,
            legends: legends,
            facts: facts,
          );

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText:
                            'Buscar NPCs, locais, missões, itens, facções...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _query.isEmpty
                  ? _buildEmptyState()
                  : results.isEmpty
                      ? _buildNoResults()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final r = results[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    r.color.withValues(alpha: 0.2),
                                child: Icon(r.icon,
                                    size: 16, color: r.color),
                              ),
                              title: Text(
                                r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${r.category} · ${r.snippet}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontSize: 11),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                r.onTap(context);
                              },
                            );
                          },
                        ),
            ),
            if (_query.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.primaryDark.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12,
                        color: AppTheme.textMuted.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      '${results.length} resultado(s)',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Digite para buscar em toda a aventura',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Busca em nomes, descrições, tags e conteúdo',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sentiment_dissatisfied,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Nada encontrado para "$_query"',
              style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  List<_SearchResult> _buildResults({
    required String q,
    required List<Creature> creatures,
    required List<Location> locations,
    required List<PointOfInterest> pois,
    required List<Quest> quests,
    required List<Item> items,
    required List<Faction> factions,
    required List<Legend> legends,
    required List<Fact> facts,
  }) {
    final adventureId = widget.adventureId;
    final results = <_SearchResult>[];

    bool match(String? s) => s != null && s.toLowerCase().contains(q);

    for (final c in creatures) {
      if (match(c.name) ||
          match(c.description) ||
          match(c.motivation) ||
          c.tags.any((t) => t.toLowerCase().contains(q))) {
        results.add(_SearchResult(
          title: c.name,
          category:
              c.type == CreatureType.npc ? 'NPC' : 'Criatura',
          snippet: c.description.isEmpty
              ? (c.motivation.isEmpty ? '—' : c.motivation)
              : c.description,
          icon: c.type == CreatureType.npc ? Icons.person : Icons.pets,
          color: c.type == CreatureType.npc ? AppTheme.npc : AppTheme.accent,
          onTap: (ctx) => ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    for (final l in locations) {
      if (match(l.name) ||
          match(l.description) ||
          l.tags.any((t) => t.toLowerCase().contains(q))) {
        results.add(_SearchResult(
          title: l.name,
          category: 'Local',
          snippet: l.description.isEmpty ? '—' : l.description,
          icon: Icons.map,
          color: AppTheme.location,
          onTap: (ctx) =>
              ctx.push('/adventure/$adventureId/location/${l.id}'),
        ));
      }
    }

    for (final p in pois) {
      if (match(p.name) ||
          match(p.firstImpression) ||
          match(p.obvious) ||
          match(p.detail) ||
          match(p.treasure)) {
        results.add(_SearchResult(
          title: '#${p.number} ${p.name}',
          category: 'Ponto de Interesse',
          snippet: p.firstImpression.isEmpty ? p.detail : p.firstImpression,
          icon: Icons.place,
          color: AppTheme.primary,
          onTap: (ctx) => p.locationId != null
              ? ctx.push('/adventure/$adventureId/location/${p.locationId}')
              : ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    for (final q2 in quests) {
      if (match(q2.name) ||
          match(q2.description) ||
          q2.tags.any((t) => t.toLowerCase().contains(q))) {
        results.add(_SearchResult(
          title: q2.name,
          category: 'Missão · ${q2.status.displayName}',
          snippet: q2.description.isEmpty ? '—' : q2.description,
          icon: Icons.flag,
          color: AppTheme.quest,
          onTap: (ctx) => ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    for (final i in items) {
      if (match(i.name) ||
          match(i.description) ||
          match(i.mechanics) ||
          i.tags.any((t) => t.toLowerCase().contains(q))) {
        results.add(_SearchResult(
          title: i.name,
          category: 'Item · ${i.type.displayName}',
          snippet: i.description.isEmpty ? i.mechanics : i.description,
          icon: Icons.inventory_2,
          color: AppTheme.item,
          onTap: (ctx) => ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    for (final f in factions) {
      if (match(f.name) || match(f.description) || match(f.stakes)) {
        results.add(_SearchResult(
          title: f.name,
          category: 'Facção · ${f.type.displayName}',
          snippet: f.description.isEmpty ? f.stakes : f.description,
          icon: Icons.groups,
          color: AppTheme.faction,
          onTap: (ctx) => ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    for (final l in legends) {
      if (match(l.text) || match(l.source)) {
        results.add(_SearchResult(
          title: l.text.length > 50
              ? '${l.text.substring(0, 50)}...'
              : l.text,
          category: 'Rumor · ${l.isTrue ? "Verdadeiro" : "Falso"}',
          snippet: l.source ?? '—',
          icon: Icons.campaign,
          color: l.isTrue ? AppTheme.success : AppTheme.dubious,
          onTap: (ctx) => ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    for (final f in facts) {
      if (match(f.content) || f.tags.any((t) => t.toLowerCase().contains(q))) {
        results.add(_SearchResult(
          title: f.content.length > 50
              ? '${f.content.substring(0, 50)}...'
              : f.content,
          category: f.isSecret ? 'Segredo' : 'Fato',
          snippet: f.revealed ? 'Revelado' : 'Oculto',
          icon: f.isSecret ? Icons.lock : Icons.info,
          color: f.isSecret ? AppTheme.accent : AppTheme.info,
          onTap: (ctx) => ctx.push('/adventure/$adventureId'),
        ));
      }
    }

    return results;
  }
}

class _SearchResult {
  final String title;
  final String category;
  final String snippet;
  final IconData icon;
  final Color color;
  final void Function(BuildContext) onTap;

  _SearchResult({
    required this.title,
    required this.category,
    required this.snippet,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
