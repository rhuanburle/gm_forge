import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../core/utils/json_download.dart';
import '../../../../../core/widgets/import_json_dialog.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

class NotesTab extends ConsumerStatefulWidget {
  final String campaignId;

  const NotesTab({super.key, required this.campaignId});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  String get campaignId => widget.campaignId;

  void _markUnsynced() {
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider(campaignId));
    final quickRules = ref.watch(quickRulesProvider(campaignId));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildNotesSection(context, notes),
        const SizedBox(height: 24),
        _buildQuickRulesSection(context, quickRules),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Notas
  // ---------------------------------------------------------------------------

  Widget _buildNotesSection(BuildContext context, List<Note> notes) {
    // Sort: pinned first, then by updatedAt descending
    final sorted = List<Note>.from(notes)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    // Group by category
    final grouped = <NoteCategory, List<Note>>{};
    for (final note in sorted) {
      grouped.putIfAbsent(note.category, () => []).add(note);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.note_alt,
          title: 'Notas',
          onAdd: () => _showAddNoteDialog(context),
        ),
        if (notes.isEmpty)
          _emptyState(context, 'Nenhuma nota adicionada.')
        else
          ...grouped.entries.map((group) {
            return ExpansionTile(
              leading: Icon(
                Icons.folder_outlined,
                color: AppTheme.secondary,
                size: 20,
              ),
              title: Text(
                '${group.key.displayName} (${group.value.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              initiallyExpanded: true,
              children: group.value
                  .map((note) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: _noteCard(context, note),
                      ))
                  .toList(),
            );
          }),
      ],
    );
  }

  Widget _noteCard(BuildContext context, Note note) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: note.isPinned
            ? const Icon(Icons.push_pin, color: AppTheme.warning, size: 18)
            : const Icon(Icons.note, color: AppTheme.textMuted, size: 18),
        title: Text(
          note.title,
          style: Theme.of(context).textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          iconSize: 20,
          onSelected: (value) {
            if (value == 'edit') {
              _showEditNoteDialog(context, note);
            } else if (value == 'pin') {
              _togglePinNote(note);
            } else if (value == 'delete') {
              _confirmDelete(
                context,
                title: 'Excluir Nota',
                message:
                    'Tem certeza que deseja excluir "${note.title}"?',
                onConfirm: () async {
                  await ref.read(hiveDatabaseProvider).deleteNote(note.id);
                  ref.invalidate(notesProvider(campaignId));
                  _markUnsynced();
                },
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(note.isPinned ? 'Desafixar' : 'Fixar'),
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
        ),
      ),
    );
  }

  Future<void> _togglePinNote(Note note) async {
    final updated = note.copyWith(isPinned: !note.isPinned);
    await ref.read(hiveDatabaseProvider).saveNote(updated);
    ref.invalidate(notesProvider(campaignId));
    _markUnsynced();
  }

  // ---------------------------------------------------------------------------
  // Note Dialog
  // ---------------------------------------------------------------------------

  void _showAddNoteDialog(BuildContext context) {
    _showNoteFormDialog(context, null);
  }

  void _showEditNoteDialog(BuildContext context, Note note) {
    _showNoteFormDialog(context, note);
  }

  void _showNoteFormDialog(BuildContext context, Note? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl =
        TextEditingController(text: existing?.content ?? '');
    final tagsCtrl =
        TextEditingController(text: existing?.tags.join(', ') ?? '');
    NoteCategory selectedCategory =
        existing?.category ?? NoteCategory.misc;
    bool isPinned = existing?.isPinned ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
              Text(existing == null ? 'Nova Nota' : 'Editar Nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Titulo *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<NoteCategory>(
                  initialValue: selectedCategory,
                  decoration:
                      const InputDecoration(labelText: 'Categoria'),
                  items: NoteCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Conteudo'),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (separadas por virgula)',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Fixar nota'),
                  value: isPinned,
                  activeThumbColor: AppTheme.warning,
                  onChanged: (v) {
                    setDialogState(() => isPinned = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final tags = tagsCtrl.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                final db = ref.read(hiveDatabaseProvider);

                if (existing != null) {
                  final updated = existing.copyWith(
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                    isPinned: isPinned,
                  );
                  await db.saveNote(updated);
                } else {
                  final note = Note.create(
                    campaignId: campaignId,
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                    isPinned: isPinned,
                  );
                  await db.saveNote(note);
                }

                ref.invalidate(notesProvider(campaignId));
                _markUnsynced();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Regras Rapidas
  // ---------------------------------------------------------------------------

  Widget _buildQuickRulesSection(
      BuildContext context, List<QuickRule> rules) {
    // Group by category to render category headers
    final grouped = <String, List<QuickRule>>{};
    for (final rule in rules) {
      grouped.putIfAbsent(rule.category, () => []).add(rule);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.shield_outlined,
          title: 'Escudo do Mestre',
          onAdd: () => _showAddRuleDialog(context),
          onImport: () => _showImportRuleDialog(context),
          onExport: rules.isEmpty ? null : () => _exportRulesAsJson(context, rules),
          onClearAll: rules.isEmpty ? null : () => _confirmDelete(
            context,
            title: 'Apagar todos os cards',
            message: 'Isso removerá todos os ${rules.length} cards do Escudo. Essa ação não pode ser desfeita.',
            onConfirm: () async {
              await ref.read(hiveDatabaseProvider).deleteAllQuickRules(campaignId);
              ref.invalidate(quickRulesProvider(campaignId));
              _markUnsynced();
            },
          ),
        ),
        if (rules.isEmpty)
          _emptyState(context, 'Nenhuma regra adicionada.\nCrie cards de referência rápida para usar durante a sessão.')
        else
          ...grouped.entries.map((group) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.key.isNotEmpty && group.key != 'Geral') ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(
                    group.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 4),
              _RuleCardGrid(
                rules: group.value,
                onEdit: (r) => _showEditRuleDialog(context, r),
                onDelete: (r) => _confirmDelete(
                  context,
                  title: 'Excluir Card',
                  message: 'Deseja excluir "${r.title}"?',
                  onConfirm: () async {
                    await ref.read(hiveDatabaseProvider).deleteQuickRule(r.id);
                    ref.invalidate(quickRulesProvider(campaignId));
                    _markUnsynced();
                  },
                ),
              ),
            ],
          )),
      ],
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    _showRuleFormDialog(context, null);
  }

  void _showEditRuleDialog(BuildContext context, QuickRule rule) {
    _showRuleFormDialog(context, rule);
  }

  void _showRuleFormDialog(BuildContext context, QuickRule? rule) {
    final titleCtrl = TextEditingController(text: rule?.title ?? '');
    final contentCtrl = TextEditingController(text: rule?.content ?? '');
    final categoryCtrl = TextEditingController(text: rule?.category ?? 'Geral');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rule == null ? 'Novo Card de Referência' : 'Editar Card'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título do card *',
                    hintText: 'ex: Condições, Combate — Ações, DCs',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Grupo (opcional)',
                    hintText: 'ex: Combate, Magia, Geral',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Tooltip(
                      message: 'Negrito — selecione o texto e clique',
                      child: InkWell(
                        onTap: () {
                          final sel = contentCtrl.selection;
                          if (sel.isValid && sel.start != sel.end) {
                            final t = contentCtrl.text;
                            final before = t.substring(0, sel.start);
                            final selected = t.substring(sel.start, sel.end);
                            final after = t.substring(sel.end);
                            contentCtrl.value = TextEditingValue(
                              text: '$before**$selected**$after',
                              selection: TextSelection.collapsed(
                                offset: sel.end + 4,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.textMuted.withValues(alpha: 0.35),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'B',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    hintText: 'Use quebras de linha para organizar.\nex:\nAtaque = Ação\nMover = Movimento\nAparar = Reação',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 10,
                  minLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 6),
                Text(
                  'Dica: use **texto** para negrito. Selecione e clique B.',
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final db = ref.read(hiveDatabaseProvider);
              if (rule == null) {
                final newRule = QuickRule.create(
                  campaignId: campaignId,
                  title: title,
                  content: contentCtrl.text,
                  category: categoryCtrl.text.trim().isEmpty ? 'Geral' : categoryCtrl.text.trim(),
                );
                await db.saveQuickRule(newRule);
              } else {
                final updated = rule.copyWith(
                  title: title,
                  content: contentCtrl.text,
                  category: categoryCtrl.text.trim().isEmpty ? 'Geral' : categoryCtrl.text.trim(),
                );
                await db.saveQuickRule(updated);
              }
              ref.invalidate(quickRulesProvider(campaignId));
              _markUnsynced();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  void _exportRulesAsJson(BuildContext context, List<QuickRule> rules) {
    final exportList = rules
        .map((r) => {
              'title': r.title,
              'category': r.category,
              'content': r.content,
              'order': r.order,
            })
        .toList();

    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(exportList);
    const filename = 'escudo_do_mestre.json';

    if (kIsWeb) {
      downloadJsonFile(jsonString, filename);
      AppSnackBar.success(context, 'Download iniciado: $filename');
    } else {
      Clipboard.setData(ClipboardData(text: jsonString));
      _showExportDialog(context, jsonString);
    }
  }

  void _showExportDialog(BuildContext context, String jsonString) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Escudo do Mestre'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JSON copiado para a área de transferência. Você também pode visualizá-lo abaixo:',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surfaceLight),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              if (ctx.mounted) {
                AppSnackBar.success(ctx, 'JSON copiado!');
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onAdd,
    VoidCallback? onImport,
    VoidCallback? onExport,
    VoidCallback? onClearAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          if (onClearAll != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              tooltip: 'Apagar todos os cards',
              color: AppTheme.error,
              onPressed: onClearAll,
            ),
          if (onExport != null)
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 18),
              tooltip: kIsWeb ? 'Baixar JSON' : 'Exportar JSON',
              color: AppTheme.textMuted,
              onPressed: onExport,
            ),
          if (onImport != null)
            IconButton(
              icon: const Icon(Icons.upload_file, size: 18),
              tooltip: 'Importar via JSON',
              color: AppTheme.textMuted,
              onPressed: onImport,
            ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showImportRuleDialog(BuildContext context) {
    Future<void> saveRule(Map<String, dynamic> json) async {
      json['id'] = const Uuid().v4();
      json['campaignId'] = campaignId;
      json['order'] = json['order'] ?? 0;
      final rule = QuickRule.fromJson(json);
      await ref.read(hiveDatabaseProvider).saveQuickRule(rule);
    }

    showImportJsonDialog(
      context: context,
      title: 'Importar Cards do Escudo',
      exampleJson: '''[
  {
    "title": "Ações em Combate",
    "category": "Combate",
    "content": "Atacar, Conjurar, Dash (2x mov)\\nDesviar, Ajudar, Esconder, Item"
  },
  {
    "title": "Condições",
    "category": "Combate",
    "content": "Agarrado: vel 0\\nCego: ataque com desv\\nAtordoado: não age"
  }
]''',
      legend: 'Aceita um único objeto { } ou uma lista [ ] com vários cards.\n'
          'category: agrupa os cards (ex: "Combate", "Magia", "Geral")\n'
          'content: use \\n para quebras de linha',
      onImport: (json) async {
        try {
          await saveRule(json);
          ref.invalidate(quickRulesProvider(campaignId));
          _markUnsynced();
          if (context.mounted) {
            AppSnackBar.success(context, '"${json['title'] ?? 'Card'}" importado!');
          }
        } catch (e) {
          if (context.mounted) AppSnackBar.error(context, 'Erro ao importar: $e');
        }
      },
      onImportList: (items) async {
        int count = 0;
        for (final json in items) {
          try {
            await saveRule(json);
            count++;
          } catch (_) {}
        }
        ref.invalidate(quickRulesProvider(campaignId));
        _markUnsynced();
        if (context.mounted) {
          AppSnackBar.success(context, '$count card(s) importado(s)!');
        }
      },
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
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
}

// ---------------------------------------------------------------------------
// Grid de cards do escudo
// ---------------------------------------------------------------------------

/// Parses `**bold**` markers and returns a [Text.rich] that inherits the
/// theme font (DefaultTextStyle) while applying [base] style overrides.
Widget _richContent(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  int last = 0;
  for (final m in RegExp(r'\*\*(.+?)\*\*').allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(
      text: m.group(1),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last)));
  }
  return Text.rich(TextSpan(children: spans), style: base);
}

class _RuleCardGrid extends StatelessWidget {
  final List<QuickRule> rules;
  final ValueChanged<QuickRule> onEdit;
  final ValueChanged<QuickRule> onDelete;

  const _RuleCardGrid({required this.rules, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 3 : 2;
        final cardWidth = (constraints.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rules
              .map((rule) => SizedBox(
                    width: cardWidth,
                    child: _RuleCard(
                      rule: rule,
                      onEdit: () => onEdit(rule),
                      onDelete: () => onDelete(rule),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _RuleCard extends StatelessWidget {
  final QuickRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({required this.rule, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.r12),
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rule.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 16, color: AppTheme.textMuted),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 15), SizedBox(width: 8), Text('Editar')]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 15, color: AppTheme.error), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: AppTheme.error))]),
                      ),
                    ],
                  ),
                ],
              ),
              if (rule.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 6),
                _richContent(
                  rule.content,
                  (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.55,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
