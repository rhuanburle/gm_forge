import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/lore_entry.dart';

class LoreCard extends StatelessWidget {
  final LoreEntry lore;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LoreCard({
    super.key,
    required this.lore,
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
              if (lore.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lore.content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (lore.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTags(context),
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
        Icon(
          _categoryIcon(lore.category),
          color: _categoryColor(lore.category),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lore.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: lore.tags
          .map((tag) => Chip(
                label: Text(tag),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: Theme.of(context).textTheme.labelSmall,
                avatar: const Icon(Icons.label, size: 12),
              ))
          .toList(),
    );
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

  static IconData _categoryIcon(LoreCategory category) {
    switch (category) {
      case LoreCategory.deity:
        return Icons.auto_awesome;
      case LoreCategory.myth:
        return Icons.menu_book;
      case LoreCategory.history:
        return Icons.history_edu;
      case LoreCategory.geography:
        return Icons.public;
      case LoreCategory.custom:
        return Icons.article;
    }
  }

  static Color _categoryColor(LoreCategory category) {
    switch (category) {
      case LoreCategory.deity:
        return AppTheme.secondary;
      case LoreCategory.myth:
        return AppTheme.accent;
      case LoreCategory.history:
        return AppTheme.primary;
      case LoreCategory.geography:
        return AppTheme.success;
      case LoreCategory.custom:
        return AppTheme.textSecondary;
    }
  }
}
