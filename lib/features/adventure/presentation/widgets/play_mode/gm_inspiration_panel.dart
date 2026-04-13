import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

/// GM Inspiration panel — rolls random entries from editable campaign tables.
/// Tables are stored in Campaign.inspirationTables and are fully customizable.
class GmInspirationPanel extends ConsumerStatefulWidget {
  final String? campaignId;
  const GmInspirationPanel({super.key, this.campaignId});

  @override
  ConsumerState<GmInspirationPanel> createState() => _GmInspirationPanelState();
}

class _GmInspirationPanelState extends ConsumerState<GmInspirationPanel> {
  final _rng = Random();
  String? _lastResult;
  String? _lastTableName;
  List<_ChainResult>? _lastChainResult;

  List<InspirationTable> get _tables {
    if (widget.campaignId != null) {
      final campaign = ref.watch(campaignProvider(widget.campaignId!));
      if (campaign != null && campaign.inspirationTables.isNotEmpty) {
        return campaign.inspirationTables;
      }
    }
    return InspirationTable.defaults();
  }

  @override
  Widget build(BuildContext context) {
    final tables = _tables;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: const Icon(Icons.auto_fix_high, size: 16, color: AppTheme.warning),
        title: Row(
          children: [
            const Text(
              'Inspiração',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.warning,
              ),
            ),
            const Spacer(),
            if (widget.campaignId != null)
              InkWell(
                onTap: () => _showManageTablesDialog(context),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.settings, size: 14, color: AppTheme.textMuted),
                ),
              ),
          ],
        ),
        children: [
          // Roll buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...tables.map((table) => _rollButton(table)),
              // Chain roll button — rolls from all tables at once
              if (tables.length >= 2)
                OutlinedButton.icon(
                  onPressed: () => _rollChain(tables),
                  icon: const Icon(Icons.link, size: 14),
                  label: const Text('Cadeia', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppTheme.secondary,
                    side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.4)),
                  ),
                ),
            ],
          ),
          // Single result display
          if (_lastResult != null && _lastChainResult == null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lastTableName ?? '',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastResult!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          // Chain result display
          if (_lastChainResult != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROLAGEM ENCADEADA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._lastChainResult!.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.tableName}: ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning.withValues(alpha: 0.8),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r.entry,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rollButton(InspirationTable table) {
    return OutlinedButton.icon(
      onPressed: table.entries.isEmpty
          ? null
          : () {
              setState(() {
                _lastTableName = table.name;
                _lastResult =
                    table.entries[_rng.nextInt(table.entries.length)];
                _lastChainResult = null;
              });
            },
      icon: const Icon(Icons.casino, size: 14),
      label: Text(table.name, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppTheme.warning,
        side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
    );
  }

  void _rollChain(List<InspirationTable> tables) {
    final results = <_ChainResult>[];
    for (final table in tables) {
      if (table.entries.isNotEmpty) {
        results.add(_ChainResult(
          tableName: table.name,
          entry: table.entries[_rng.nextInt(table.entries.length)],
        ));
      }
    }
    setState(() {
      _lastChainResult = results;
      _lastResult = null;
      _lastTableName = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Manage tables dialog
  // ---------------------------------------------------------------------------

  void _showManageTablesDialog(BuildContext context) {
    final campaign = ref.read(campaignProvider(widget.campaignId!));
    if (campaign == null) return;

    showDialog(
      context: context,
      builder: (ctx) => _ManageTablesDialog(
        campaign: campaign,
        onSave: (tables) {
          ref.read(campaignListProvider.notifier).update(
            campaign.copyWith(
              inspirationTables: tables,
              updatedAt: DateTime.now(),
            ),
          );
          ref.read(unsyncedChangesProvider.notifier).state = true;
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manage Tables Dialog
// ---------------------------------------------------------------------------

class _ManageTablesDialog extends StatefulWidget {
  final Campaign campaign;
  final void Function(List<InspirationTable> tables) onSave;

  const _ManageTablesDialog({required this.campaign, required this.onSave});

  @override
  State<_ManageTablesDialog> createState() => _ManageTablesDialogState();
}

class _ManageTablesDialogState extends State<_ManageTablesDialog> {
  late List<InspirationTable> _tables;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _tables = List.from(widget.campaign.inspirationTables);
    if (_tables.isEmpty) {
      _tables = InspirationTable.defaults();
    }
  }

  void _save() {
    widget.onSave(_tables);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tabelas de Inspiração'),
      content: SizedBox(
        width: 500,
        height: 450,
        child: Row(
          children: [
            // Table list
            SizedBox(
              width: 160,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tables.length,
                      itemBuilder: (ctx, i) {
                        final isSelected = _selectedIndex == i;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          title: Text(
                            _tables[i].name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${_tables[i].entries.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          onTap: () => setState(() => _selectedIndex = i),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _addTable,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Nova', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      if (_selectedIndex != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16, color: AppTheme.error),
                          onPressed: () {
                            setState(() {
                              _tables.removeAt(_selectedIndex!);
                              _selectedIndex = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // Table entries editor
            Expanded(
              child: _selectedIndex != null
                  ? _buildEntriesEditor(_tables[_selectedIndex!])
                  : const Center(
                      child: Text(
                        'Selecione uma tabela',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }

  Widget _buildEntriesEditor(InspirationTable table) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  table.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 14),
                onPressed: () => _renameTable(table),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(4),
            itemCount: table.entries.length,
            itemBuilder: (ctx, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        table.entries[i],
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 12),
                        padding: EdgeInsets.zero,
                        onPressed: () => _editEntry(table, i),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 12, color: AppTheme.error),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          final entries = List<String>.from(table.entries)
                            ..removeAt(i);
                          _updateTable(table.copyWith(entries: entries));
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addEntry(table),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar entrada', style: TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  void _addTable() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Tabela'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nome da tabela'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _tables.add(InspirationTable.create(name: name));
                _selectedIndex = _tables.length - 1;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _renameTable(InspirationTable table) {
    final ctrl = TextEditingController(text: table.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear Tabela'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              _updateTable(table.copyWith(name: name));
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _addEntry(InspirationTable table) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Entrada'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Texto da entrada...'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              final entries = [...table.entries, text];
              _updateTable(table.copyWith(entries: entries));
              Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _editEntry(InspirationTable table, int index) {
    final ctrl = TextEditingController(text: table.entries[index]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Entrada'),
        content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              final entries = List<String>.from(table.entries);
              entries[index] = text;
              _updateTable(table.copyWith(entries: entries));
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _updateTable(InspirationTable updated) {
    setState(() {
      final idx = _tables.indexWhere((t) => t.id == updated.id);
      if (idx != -1) _tables[idx] = updated;
    });
  }
}

class _ChainResult {
  final String tableName;
  final String entry;

  const _ChainResult({required this.tableName, required this.entry});
}
