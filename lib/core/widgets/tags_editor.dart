import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact editable tags widget.
///
/// Displays existing tags as chips with delete buttons and a
/// "+ Tag" action chip that opens an input dialog.
class TagsEditor extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final IconData icon;
  final String hint;

  const TagsEditor({
    super.key,
    required this.tags,
    required this.onChanged,
    this.label = 'Tags',
    this.icon = Icons.label_outline,
    this.hint = 'ex: nobreza, guilda, vila do porto',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.secondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...tags.asMap().entries.map((entry) => Chip(
                  label: Text(entry.value, style: const TextStyle(fontSize: 11)),
                  onDeleted: () {
                    final newTags = List<String>.from(tags)..removeAt(entry.key);
                    onChanged(newTags);
                  },
                  deleteIconColor: AppTheme.error,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 14),
              label: const Text('Tag', style: TextStyle(fontSize: 11)),
              onPressed: () => _showAddDialog(context),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (_) => _submit(ctx, ctrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _submit(ctx, ctrl.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext ctx, String raw) {
    final text = raw.trim().toLowerCase();
    if (text.isNotEmpty && !tags.contains(text)) {
      onChanged([...tags, text]);
    }
    Navigator.pop(ctx);
  }
}

/// Read-only tag chip row for displaying tags on cards.
class TagsDisplay extends StatelessWidget {
  final List<String> tags;
  final double fontSize;
  final VoidCallback? Function(String)? onTagTap;

  const TagsDisplay({
    super.key,
    required this.tags,
    this.fontSize = 10,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.map((tag) {
        final tap = onTagTap?.call(tag);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: GestureDetector(
            onTap: tap,
            child: Text(
              '#$tag',
              style: TextStyle(
                fontSize: fontSize,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
