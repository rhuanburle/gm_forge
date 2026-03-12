import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/region.dart';

class RegionCard extends StatelessWidget {
  final Region region;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RegionCard({
    super.key,
    required this.region,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildDetails(context),
              const SizedBox(height: 8),
              _buildDangerLevel(context),
              if (region.subhexes.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildSubhexCount(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (region.hexCode.isNotEmpty) ...[
          _buildHexBadge(context),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            region.name,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildHexBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        region.hexCode,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.info,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Row(
      children: [
        if (region.terrain.isNotEmpty) ...[
          const Icon(Icons.terrain, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              region.terrain,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDangerLevel(BuildContext context) {
    final level = region.dangerLevel.clamp(1, 5);
    return Row(
      children: [
        Text(
          'Perigo:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(5, (index) {
          final filled = index < level;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              filled ? Icons.warning_rounded : Icons.circle_outlined,
              size: filled ? 14 : 10,
              color: filled
                  ? _dangerColor(level)
                  : AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          _dangerLabel(level),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _dangerColor(level),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubhexCount(BuildContext context) {
    final explored =
        region.subhexes.where((s) => s.isExplored).length;
    return Row(
      children: [
        const Icon(Icons.hexagon_outlined, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          '$explored/${region.subhexes.length} sub-hexes explorados',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Color _dangerColor(int level) {
    if (level <= 1) return AppTheme.success;
    if (level == 2) return AppTheme.info;
    if (level == 3) return AppTheme.warning;
    if (level == 4) return AppTheme.accent;
    return AppTheme.error;
  }

  String _dangerLabel(int level) {
    switch (level) {
      case 1:
        return 'Seguro';
      case 2:
        return 'Baixo';
      case 3:
        return 'Moderado';
      case 4:
        return 'Alto';
      case 5:
        return 'Mortal';
      default:
        return '';
    }
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      iconSize: 20,
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          onDelete?.call();
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
