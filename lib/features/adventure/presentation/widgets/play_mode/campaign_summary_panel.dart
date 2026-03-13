import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';
import 'creature_detail_dialog.dart';

class CampaignSummaryPanel extends ConsumerWidget {
  final String campaignId;

  const CampaignSummaryPanel({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pcs = ref.watch(playerCharactersProvider(campaignId));
    final creatures = ref.watch(campaignCreaturesProvider(campaignId));
    final items = ref.watch(campaignItemsProvider(campaignId));
    final factions = ref.watch(campaignFactionsProvider(campaignId));

    if (pcs.isEmpty && creatures.isEmpty && items.isEmpty && factions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text(
          'Elementos da Campanha',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        children: [
          // Player Characters
          if (pcs.isNotEmpty) ...[
            const _SubSectionHeader(icon: Icons.person, title: 'Personagens dos Jogadores'),
            const SizedBox(height: 4),
            ...pcs.map((pc) => _PcRow(pc: pc)),
            const SizedBox(height: 12),
          ],

          // Factions with objectives
          if (factions.isNotEmpty) ...[
            const _SubSectionHeader(icon: Icons.groups, title: 'Facções'),
            const SizedBox(height: 4),
            ...factions.take(5).map((f) => _FactionRow(faction: f)),
            if (factions.length > 5)
              _MoreIndicator(count: factions.length - 5, label: 'facções'),
            const SizedBox(height: 12),
          ],

          // Campaign-level NPCs
          if (creatures.isNotEmpty) ...[
            const _SubSectionHeader(icon: Icons.person_outline, title: 'NPCs da Campanha'),
            const SizedBox(height: 4),
            ...creatures.take(5).map((c) => _CreatureRow(creature: c, campaignId: campaignId)),
            if (creatures.length > 5)
              _MoreIndicator(count: creatures.length - 5, label: 'NPCs'),
            const SizedBox(height: 12),
          ],

          // Campaign-level items
          if (items.isNotEmpty) ...[
            const _SubSectionHeader(icon: Icons.category_outlined, title: 'Itens da Campanha'),
            const SizedBox(height: 4),
            ...items.take(5).map((i) => _ItemRow(item: i)),
            if (items.length > 5)
              _MoreIndicator(count: items.length - 5, label: 'itens'),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-section header
// ---------------------------------------------------------------------------

class _SubSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SubSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.secondary),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PC row with key stats
// ---------------------------------------------------------------------------

class _PcRow extends StatelessWidget {
  final PlayerCharacter pc;
  const _PcRow({required this.pc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => _showPcPopup(context, pc),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 12, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pc.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pc.level > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Nv ${pc.level}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              if (pc.characterClass.isNotEmpty || pc.species.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [pc.species, pc.characterClass]
                        .where((s) => s.isNotEmpty)
                        .join(' - '),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (pc.criticalData.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    pc.criticalData,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPcPopup(BuildContext context, PlayerCharacter pc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(pc.name)),
            if (pc.level > 0)
              Chip(
                label: Text('Nv ${pc.level}'),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pc.playerName.isNotEmpty) ...[
                _detailRow('Jogador', pc.playerName),
                const SizedBox(height: 8),
              ],
              if (pc.species.isNotEmpty) ...[
                _detailRow('Espécie', pc.species),
                const SizedBox(height: 8),
              ],
              if (pc.characterClass.isNotEmpty) ...[
                _detailRow('Classe', pc.characterClass),
                const SizedBox(height: 8),
              ],
              if (pc.origin.isNotEmpty) ...[
                _detailRow('Origem', pc.origin),
                const SizedBox(height: 8),
              ],
              if (pc.criticalData.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Dados Críticos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pc.criticalData,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
              if (pc.backstory.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Backstory',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  pc.backstory,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
              if (pc.notes.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Notas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(pc.notes, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Faction row with objective progress
// ---------------------------------------------------------------------------

class _FactionRow extends StatelessWidget {
  final Faction faction;
  const _FactionRow({required this.faction});

  @override
  Widget build(BuildContext context) {
    final isFront = faction.type == FactionType.front;
    final color = isFront ? AppTheme.warning : AppTheme.accent;
    final activeObjective = faction.objectives.isNotEmpty
        ? faction.objectives.first
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isFront ? Icons.warning : Icons.groups,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              faction.name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (activeObjective != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                value: activeObjective.maxProgress > 0
                    ? activeObjective.currentProgress / activeObjective.maxProgress
                    : 0,
                backgroundColor: AppTheme.textMuted.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${activeObjective.currentProgress}/${activeObjective.maxProgress}',
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Creature row (tappable)
// ---------------------------------------------------------------------------

class _CreatureRow extends StatelessWidget {
  final Creature creature;
  final String campaignId;
  const _CreatureRow({required this.creature, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => CreatureDetailDialog.show(
          context,
          creature: creature,
          adventureId: campaignId,
        ),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            Icon(
              creature.type == CreatureType.monster ? Icons.pets : Icons.person_outline,
              size: 12,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                creature.name,
                style: const TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item row
// ---------------------------------------------------------------------------

class _ItemRow extends StatelessWidget {
  final Item item;
  const _ItemRow({required this.item});

  IconData get _icon {
    switch (item.type) {
      case ItemType.weapon:
        return Icons.gavel;
      case ItemType.armor:
        return Icons.shield;
      case ItemType.potion:
        return Icons.science;
      case ItemType.scroll:
        return Icons.description;
      case ItemType.artifact:
        return Icons.auto_awesome;
      case ItemType.misc:
        return Icons.inventory_2;
    }
  }

  Color get _rarityColor {
    switch (item.rarity) {
      case ItemRarity.common:
        return AppTheme.textMuted;
      case ItemRarity.uncommon:
        return AppTheme.success;
      case ItemRarity.rare:
        return AppTheme.info;
      case ItemRarity.veryRare:
        return AppTheme.npc;
      case ItemRarity.legendary:
        return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(_icon, size: 12, color: _rarityColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _rarityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              item.rarity.displayName,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: _rarityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More indicator
// ---------------------------------------------------------------------------

class _MoreIndicator extends StatelessWidget {
  final int count;
  final String label;
  const _MoreIndicator({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        '+ $count outros $label',
        style: const TextStyle(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
