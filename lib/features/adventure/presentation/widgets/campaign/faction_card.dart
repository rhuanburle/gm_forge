import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/faction.dart';

class FactionCard extends StatefulWidget {
  final Faction faction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FactionCard({
    super.key,
    required this.faction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FactionCard> createState() => _FactionCardState();
}

class _FactionCardState extends State<FactionCard> {
  bool _isExpanded = false;

  Faction get faction => widget.faction;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildPowerIndicator(context),
              if (faction.objectives.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildObjectives(context),
              ],
              if (faction.type == FactionType.front &&
                  (_hasExpandableContent)) ...[
                const SizedBox(height: 8),
                _buildExpandableSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasExpandableContent =>
      faction.allies.isNotEmpty ||
      faction.enemies.isNotEmpty ||
      faction.dangers.isNotEmpty;

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          faction.type == FactionType.front
              ? Icons.warning_amber
              : Icons.groups,
          color: faction.type == FactionType.front
              ? AppTheme.warning
              : AppTheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            faction.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildTypeBadge(context),
        const SizedBox(width: 4),
        _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    final isFront = faction.type == FactionType.front;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isFront ? AppTheme.warning : AppTheme.primary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isFront ? AppTheme.warning : AppTheme.primary)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        faction.type.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isFront ? AppTheme.warning : AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPowerIndicator(BuildContext context) {
    final color = _powerColor(faction.powerLevel);
    return Row(
      children: [
        Text(
          'Poder:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(FactionPower.values.length, (index) {
          final filled = index <= faction.powerLevel.index;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(
              filled ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: filled ? color : AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          faction.powerLevel.displayName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _powerColor(FactionPower power) {
    switch (power) {
      case FactionPower.weak:
        return AppTheme.textMuted;
      case FactionPower.moderate:
        return AppTheme.info;
      case FactionPower.strong:
        return AppTheme.warning;
      case FactionPower.dominant:
        return AppTheme.error;
    }
  }

  Widget _buildObjectives(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objetivos',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ...faction.objectives.map((obj) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                obj.text,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: obj.maxProgress > 0
                            ? obj.currentProgress / obj.maxProgress
                            : 0,
                        minHeight: 6,
                        backgroundColor:
                            AppTheme.surfaceLight.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor(obj.currentProgress, obj.maxProgress),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${obj.currentProgress}/${obj.maxProgress}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _progressColor(int current, int max) {
    if (max == 0) return AppTheme.textMuted;
    final ratio = current / max;
    if (ratio >= 0.8) return AppTheme.error;
    if (ratio >= 0.5) return AppTheme.warning;
    return AppTheme.success;
  }

  Widget _buildExpandableSection(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                _isExpanded ? 'Menos detalhes' : 'Mais detalhes',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          if (faction.allies.isNotEmpty)
            _buildStringList(context, 'Aliados', faction.allies, Icons.handshake),
          if (faction.enemies.isNotEmpty)
            _buildStringList(
                context, 'Inimigos', faction.enemies, Icons.shield),
          if (faction.dangers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Perigos',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...faction.dangers.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.dangerous, size: 14, color: AppTheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (d.imminentDisaster.isNotEmpty)
                          Text(
                            d.imminentDisaster,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ],
    );
  }

  Widget _buildStringList(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label: Text(item),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      iconSize: 20,
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'edit') {
          widget.onEdit?.call();
        } else if (value == 'delete') {
          widget.onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: AppTheme.error, size: 18),
              SizedBox(width: 8),
              Text('Excluir'),
            ],
          ),
        ),
      ],
    );
  }
}
