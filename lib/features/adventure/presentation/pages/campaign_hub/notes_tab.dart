import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          icon: Icons.gavel,
          title: 'Regras Rápidas (Referência)',
          onAdd: () => _showAddRuleDialog(context),
        ),
        if (rules.isEmpty)
          _emptyState(context, 'Nenhuma regra de referência adicionada.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                child: ListTile(
                  dense: true,
                  title: Text(rule.title),
                  subtitle: Text(
                    '${rule.category} • ${rule.content}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditRuleDialog(context, rule);
                      } else if (value == 'delete') {
                        _confirmDelete(
                          context,
                          title: 'Excluir Regra',
                          message: 'Deseja excluir "${rule.title}"?',
                          onConfirm: () async {
                            await ref
                                .read(hiveDatabaseProvider)
                                .deleteQuickRule(rule.id);
                            ref.invalidate(quickRulesProvider(campaignId));
                            _markUnsynced();
                          },
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
    final titleController = TextEditingController(text: rule?.title);
    final contentController = TextEditingController(text: rule?.content);
    final categoryController = TextEditingController(text: rule?.category ?? 'Geral');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rule == null ? 'Nova Regra' : 'Editar Regra'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'ex: Combate, Condições, DC',
                ),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Conteúdo/Efeito'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final db = ref.read(hiveDatabaseProvider);
              if (rule == null) {
                final newRule = QuickRule.create(
                  campaignId: campaignId,
                  title: titleController.text,
                  content: contentController.text,
                  category: categoryController.text,
                );
                await db.saveQuickRule(newRule);
              } else {
                final updated = rule.copyWith(
                  title: titleController.text,
                  content: contentController.text,
                  category: categoryController.text,
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
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onAdd,
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
