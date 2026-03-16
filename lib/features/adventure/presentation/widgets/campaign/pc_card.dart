import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/smart_network_image.dart';
import '../../../domain/player_character.dart';

class PcCard extends StatelessWidget {
  final PlayerCharacter pc;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PcCard({
    super.key,
    required this.pc,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => _showDetailDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pc.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (pc.playerName.isNotEmpty)
                          Text(
                            pc.playerName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildPopupMenu(context),
                ],
              ),
              const SizedBox(height: 8),
              if (pc.characterClass.isNotEmpty || pc.level > 0)
                _buildClassBadge(context),
              if (pc.species.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pc.species,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasImage = (pc.imageUrl ?? '').isNotEmpty;
    final initial = pc.name.isNotEmpty ? pc.name[0].toUpperCase() : '?';
    if (hasImage) {
      return ClipOval(
        child: SmartNetworkImage(
          imageUrl: pc.imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.primary,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildClassBadge(BuildContext context) {
    final label = pc.characterClass.isNotEmpty
        ? '${pc.characterClass} Nv. ${pc.level}'
        : 'Nv. ${pc.level}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
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
        } else if (value == 'detail') {
          _showDetailDialog(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.visibility, color: AppTheme.secondary, size: 18),
              SizedBox(width: 8),
              Text('Ver Detalhes'),
            ],
          ),
        ),
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

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pc.name),
                  if (pc.playerName.isNotEmpty)
                    Text(
                      'Jogador: ${pc.playerName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((pc.imageUrl ?? '').isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.r8),
                  child: SmartNetworkImage(
                    imageUrl: pc.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (pc.characterClass.isNotEmpty || pc.level > 0) ...[
                _buildClassBadge(context),
                const SizedBox(height: 8),
              ],
              if (pc.species.isNotEmpty) ...[
                _detailField(context, 'Especie', pc.species),
                const SizedBox(height: 8),
              ],
              if (pc.origin.isNotEmpty) ...[
                _detailField(context, 'Origem', pc.origin),
                const SizedBox(height: 8),
              ],
              if (pc.backstory.isNotEmpty) ...[
                _detailField(context, 'Historia', pc.backstory),
                const SizedBox(height: 8),
              ],
              if (pc.criticalData.isNotEmpty) ...[
                _detailField(context, 'Dados Criticos', pc.criticalData),
                const SizedBox(height: 8),
              ],
              if (pc.notes.isNotEmpty)
                _detailField(context, 'Notas', pc.notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit!();
              },
              child: const Text('Editar'),
            ),
          if (onDelete != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete!();
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
