import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../smart_text_renderer.dart';
import '../smart_text_field.dart';

class EditableSmartText extends ConsumerStatefulWidget {
  final String text;
  final String adventureId;
  final String label;
  final Function(String) onSave;
  final TextStyle? style;
  final bool multiline;

  const EditableSmartText({
    super.key,
    required this.text,
    required this.adventureId,
    required this.label,
    required this.onSave,
    this.style,
    this.multiline = true,
  });

  @override
  ConsumerState<EditableSmartText> createState() => _EditableSmartTextState();
}

class _EditableSmartTextState extends ConsumerState<EditableSmartText> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant EditableSmartText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_isEditing) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.text;
    });
  }

  void _save() {
    widget.onSave(_controller.text);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancel() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SmartTextField(
              controller: _controller,
              adventureId: widget.adventureId,
              label: widget.label,
              maxLines: widget.multiline ? 5 : 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancelar'),
                onPressed: _cancel,
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Salvar'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: _startEditing,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmartTextRenderer(
              text: widget.text,
              adventureId: widget.adventureId,
              style: widget.style,
            ),
            if (widget.text.isEmpty)
              Text(
                'Clique para editar...',
                style: (widget.style ?? const TextStyle()).copyWith(
                  color: Colors.grey.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
