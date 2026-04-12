import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable filter bar with search input + tag filter chips.
///
/// Used across entity lists (creatures, locations, quests, items)
/// to provide consistent filtering UX.
class EntityFilterBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<String> availableTags;
  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onTagsChanged;
  final String hint;

  const EntityFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    this.hint = 'Buscar...',
  });

  @override
  State<EntityFilterBar> createState() => _EntityFilterBarState();
}

class _EntityFilterBarState extends State<EntityFilterBar> {
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(EntityFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller only if external query was reset (e.g. programmatically cleared)
    if (widget.searchQuery != _searchCtrl.text &&
        widget.searchQuery != oldWidget.searchQuery) {
      _searchCtrl.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      widget.onSearchChanged('');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: (v) {
            setState(() {});
            widget.onSearchChanged(v);
          },
        ),
        if (widget.availableTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tag in widget.availableTags)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: widget.selectedTags.contains(tag),
                      onSelected: (selected) {
                        final newSet = Set<String>.from(widget.selectedTags);
                        if (selected) {
                          newSet.add(tag);
                        } else {
                          newSet.remove(tag);
                        }
                        widget.onTagsChanged(newSet);
                      },
                      selectedColor:
                          AppTheme.secondary.withValues(alpha: 0.3),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (widget.selectedTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ActionChip(
                      label: const Text(
                        'Limpar',
                        style: TextStyle(fontSize: 11),
                      ),
                      avatar: const Icon(Icons.clear, size: 14),
                      onPressed: () => widget.onTagsChanged({}),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
