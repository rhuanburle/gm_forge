import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/creature.dart';
import '../../application/adventure_providers.dart';

class SmartTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String adventureId;
  final String label;
  final String? hint;
  final int maxLines;
  final IconData? prefixIcon;

  const SmartTextField({
    super.key,
    this.controller,
    required this.adventureId,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  ConsumerState<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends ConsumerState<SmartTextField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String? _currentQuery;
  int? _monitorStartIndex;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.isCollapsed == false) {
      _removeOverlay();
      return;
    }

    final int cursor = selection.baseOffset;

    // Find the nearest '@' before the cursor
    int atIndex = -1;
    for (int i = cursor - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      // Stop if we hit a space or newline (optional: allow spaces in names?)
      // For now, let's allow spaces to support "Rei Goblin", but maybe limit the lookback?
      // A common pattern is to stop at newlines or if too far back.
      if (text[i] == '\n') break;
    }

    if (atIndex != -1) {
      final query = text.substring(atIndex + 1, cursor);
      _showOverlay(query, atIndex);
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay(String query, int startIndex) {
    _monitorStartIndex = startIndex;
    _currentQuery = query;

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _monitorStartIndex = null;
    _currentQuery = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 300, // Fixed width for now
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 50), // Offset below the field
            // Ideally we want to position it near the cursor, but that's complex without specialized packages.
            // For now, let's position it below the text field.
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: _SuggestionList(
                  adventureId: widget.adventureId,
                  query: _currentQuery ?? '',
                  onSelected: _onSuggestionSelected,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSuggestionSelected(String name, String type, String id) {
    if (_monitorStartIndex == null) return;

    final text = _controller.text;
    final selection = _controller.selection;
    final int cursor = selection.baseOffset;

    // Replace @query with [Name](Type:ID)
    final String replacement = '[$name]($type:$id) ';

    final newText = text.replaceRange(_monitorStartIndex!, cursor, replacement);

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: _monitorStartIndex! + replacement.length,
    );

    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon)
              : null,
          suffixIcon: IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              // Manual trigger logic could go here
              final text = _controller.text;
              final selection = _controller.selection;
              int cursor = selection.isValid
                  ? selection.baseOffset
                  : text.length;

              // Insert '@' and trigger logic
              final newText = text.replaceRange(cursor, cursor, '@');
              _controller.text = newText;
              _controller.selection = TextSelection.collapsed(
                offset: cursor + 1,
              );
              _focusNode.requestFocus();
              // The listener will pick it up
            },
            tooltip: 'Inserir Link (@)',
          ),
        ),
        maxLines: widget.maxLines,
      ),
    );
  }
}

class _SuggestionList extends ConsumerWidget {
  final String adventureId;
  final String query;
  final Function(String name, String type, String id) onSelected;

  const _SuggestionList({
    required this.adventureId,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatures = ref.watch(creaturesProvider(adventureId));
    final pois = ref.watch(pointsOfInterestProvider(adventureId));

    final lowerQuery = query.toLowerCase();

    final filteredCreatures = creatures
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
    final filteredPois = pois
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();

    if (filteredCreatures.isEmpty && filteredPois.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nenhuma correspondência encontrada.'),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        if (filteredCreatures.isNotEmpty) ...[
          const _Header('Criaturas & NPCs'),
          ...filteredCreatures.map(
            (c) => ListTile(
              dense: true,
              leading: Icon(
                c.type == CreatureType.npc ? Icons.person : Icons.pets,
                size: 16,
              ),
              title: Text(c.name),
              onTap: () => onSelected(c.name, 'Creature', c.id),
            ),
          ),
        ],
        if (filteredPois.isNotEmpty) ...[
          const _Header('Locais'),
          ...filteredPois.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(Icons.place, size: 16),
              title: Text('#${p.number} ${p.name}'),
              onTap: () =>
                  onSelected('#${p.number} ${p.name}', 'Location', p.id),
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).highlightColor.withValues(alpha: 0.1),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
