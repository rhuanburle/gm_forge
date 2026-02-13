import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';
import '../../../../../core/theme/app_theme.dart';

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
    this.onChanged,
  });

  final void Function(String, Map<String, dynamic>?)? onChanged;

  @override
  ConsumerState<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends ConsumerState<SmartTextField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String? _currentQuery;
  String? _currentTrigger;
  int? _currentStartIndex;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    // Removed focus listener to prevent overlay closing before tap is registered
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
      widget.onChanged?.call(text, null);
      return;
    }

    final int cursor = selection.baseOffset;

    int atIndex = -1;
    String trigger = '';

    for (int i = cursor - 1; i >= 0; i--) {
      if (text[i] == '@' || text[i] == '#' || text[i] == '!') {
        if (i == 0 ||
            text[i - 1] == ' ' ||
            text[i - 1] == '\n' ||
            text[i - 1] == '(') {
          atIndex = i;
          trigger = text[i];
          break;
        }
      }
      if (text[i] == '\n') break;
      if (cursor - i > 50) break;
    }

    if (atIndex != -1) {
      final query = text.substring(atIndex + 1, cursor);
      _showOverlay(query, trigger, atIndex);
    } else {
      _removeOverlay();
    }

    widget.onChanged?.call(text, null);
  }

  void _showOverlay(String query, String trigger, int startIndex) {
    _currentStartIndex = startIndex;
    _currentQuery = query;
    _currentTrigger = trigger;

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
    _currentStartIndex = null;
    _currentQuery = null;
    _currentTrigger = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 50),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: _SuggestionList(
                  adventureId: widget.adventureId,
                  query: _currentQuery ?? '',
                  trigger: _currentTrigger ?? '@',
                  startIndex: _currentStartIndex ?? 0,
                  onSelected: _onSuggestionSelected,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSuggestionSelected(
    String name,
    String type,
    String id,
    int startIndex,
  ) {
    final text = _controller.text;
    final selection = _controller.selection;
    int cursor = selection.baseOffset;

    // Recovery if cursor is invalid but we have a valid startIndex
    if (cursor < 0 || cursor < startIndex) {
      cursor = text.length;
    }

    final String replacement = '[$name]($type:$id) ';
    final newText = text.replaceRange(startIndex, cursor, replacement);

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: startIndex + replacement.length,
    );

    _removeOverlay();
    widget.onChanged?.call(newText, null);
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
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.link, size: 20),
                onPressed: () => _insertTrigger('@'),
                tooltip: 'Vincular Personagem (@)',
              ),
              IconButton(
                icon: const Icon(Icons.place, size: 20),
                onPressed: () => _insertTrigger('#'),
                tooltip: 'Vincular Local (#)',
              ),
              IconButton(
                icon: const Icon(Icons.lightbulb, size: 20),
                onPressed: () => _insertTrigger('!'),
                tooltip: 'Vincular/Criar Fato (!)',
              ),
            ],
          ),
        ),
        maxLines: widget.maxLines,
      ),
    );
  }

  void _insertTrigger(String char) {
    final text = _controller.text;
    final selection = _controller.selection;
    int cursor = selection.isValid ? selection.baseOffset : text.length;

    final newText = text.replaceRange(cursor, cursor, char);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: cursor + 1);
    _focusNode.requestFocus();
  }
}

class _SuggestionList extends ConsumerWidget {
  final String adventureId;
  final String query;
  final String trigger;
  final int startIndex;
  final Function(String name, String type, String id, int startIndex)
  onSelected;

  const _SuggestionList({
    required this.adventureId,
    required this.query,
    required this.trigger,
    required this.startIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowerQuery = query.toLowerCase();

    if (trigger == '@') {
      final creatures = ref.watch(creaturesProvider(adventureId));
      final filteredCreatures = creatures
          .where((c) => c.name.toLowerCase().contains(lowerQuery))
          .toList();

      if (filteredCreatures.isEmpty) return _emptyState();

      return ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          const _Header('Criaturas & NPCs'),
          ...filteredCreatures.map(
            (c) => ListTile(
              dense: true,
              leading: Icon(
                c.type == CreatureType.npc ? Icons.person : Icons.pets,
                size: 16,
              ),
              title: Text(c.name),
              onTap: () => onSelected(c.name, 'Creature', c.id, startIndex),
            ),
          ),
        ],
      );
    } else if (trigger == '#') {
      final pois = ref.watch(pointsOfInterestProvider(adventureId));
      final locations = ref.watch(locationsProvider(adventureId));

      final filteredPois = pois
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerQuery) ||
                p.number.toString().contains(lowerQuery),
          )
          .toList();

      final filteredLocations = locations
          .where((l) => l.name.toLowerCase().contains(lowerQuery))
          .toList();

      if (filteredPois.isEmpty && filteredLocations.isEmpty)
        return _emptyState();

      return ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          if (filteredLocations.isNotEmpty) ...[
            const _Header('Zonas / Locais'),
            ...filteredLocations.map(
              (l) => ListTile(
                dense: true,
                leading: const Icon(Icons.map, size: 16),
                title: Text(l.name),
                onTap: () => onSelected(l.name, 'Location', l.id, startIndex),
              ),
            ),
          ],
          if (filteredPois.isNotEmpty) ...[
            const _Header('Pontos de Interesse'),
            ...filteredPois.map(
              (p) => ListTile(
                dense: true,
                leading: const Icon(Icons.place, size: 16),
                title: Text('#${p.number} ${p.name}'),
                onTap: () => onSelected(
                  '#${p.number} ${p.name}',
                  'Location',
                  p.id,
                  startIndex,
                ),
              ),
            ),
          ],
        ],
      );
    } else if (trigger == '!') {
      final facts = ref.watch(factsProvider(adventureId));
      final filteredFacts = facts
          .where((f) => f.content.toLowerCase().contains(lowerQuery))
          .toList();

      final showCreate =
          query.isNotEmpty &&
          !facts.any((f) => f.content.toLowerCase() == lowerQuery);

      if (filteredFacts.isEmpty && !showCreate) return _emptyState();

      return ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          if (showCreate)
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle, color: AppTheme.primary),
              title: Text('Criar fato: "$query"'),
              onTap: () async {
                final db = ref.read(hiveDatabaseProvider);
                final newFact = Fact.create(
                  adventureId: adventureId,
                  content: query,
                );
                await db.saveFact(newFact);
                onSelected(newFact.content, 'Fact', newFact.id, startIndex);
              },
            ),
          if (filteredFacts.isNotEmpty) ...[
            const _Header('Fatos & Rumores'),
            ...filteredFacts.map(
              (f) => ListTile(
                dense: true,
                leading: const Icon(Icons.lightbulb_outline, size: 16),
                title: Text(f.content),
                onTap: () => onSelected(f.content, 'Fact', f.id, startIndex),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Nenhuma correspondência encontrada.'),
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
