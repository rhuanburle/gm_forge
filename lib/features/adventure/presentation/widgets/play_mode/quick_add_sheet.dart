import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/adventure_providers.dart';
import '../../../domain/domain.dart';

/// Bottom sheet for quickly adding NPCs, Items, Notes, or Facts during play.
class QuickAddSheet extends ConsumerStatefulWidget {
  final String adventureId;
  final String campaignId;

  const QuickAddSheet({
    super.key,
    required this.adventureId,
    required this.campaignId,
  });

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late final VoidCallback _tabListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabListener = () {
      if (!_tabController.indexIsChanging) {
        _nameController.clear();
        _descController.clear();
      }
    };
    _tabController.addListener(_tabListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String get _currentTabLabel {
    switch (_tabController.index) {
      case 0:
        return 'NPC';
      case 1:
        return 'Item';
      case 2:
        return 'Nota';
      case 3:
        return 'Segredo';
      default:
        return '';
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final desc = _descController.text.trim();
    final db = ref.read(hiveDatabaseProvider);

    switch (_tabController.index) {
      case 0: // NPC
        final creature = Creature.create(
          campaignId: widget.campaignId,
          adventureId: widget.adventureId,
          name: name,
          type: CreatureType.npc,
          description: desc,
          motivation: '',
          losingBehavior: '',
        );
        await db.saveCreature(creature);
        ref.invalidate(creaturesProvider(widget.adventureId));
        break;
      case 1: // Item
        final item = Item.create(
          campaignId: widget.campaignId,
          adventureId: widget.adventureId,
          name: name,
          description: desc,
        );
        await db.saveItem(item);
        ref.invalidate(itemsProvider(widget.adventureId));
        break;
      case 2: // Note (saved as session entry / scratchpad note)
        final fact = Fact.create(
          campaignId: widget.campaignId,
          adventureId: widget.adventureId,
          content: '$name${desc.isNotEmpty ? ': $desc' : ''}',
          isSecret: false,
        );
        await db.saveFact(fact);
        ref.invalidate(factsProvider(widget.adventureId));
        break;
      case 3: // Secret Fact
        final fact = Fact.create(
          campaignId: widget.campaignId,
          adventureId: widget.adventureId,
          content: '$name${desc.isNotEmpty ? ': $desc' : ''}',
          isSecret: true,
        );
        await db.saveFact(fact);
        ref.invalidate(factsProvider(widget.adventureId));
        break;
    }

    ref.markUnsynced();

    if (mounted) {
      AppSnackBar.success(context, '$_currentTabLabel adicionado: $name');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 320,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Adicionar Rápido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.secondary,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(icon: Icon(Icons.person, size: 18), text: 'NPC'),
                Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'Item'),
                Tab(icon: Icon(Icons.note_add, size: 18), text: 'Nota'),
                Tab(icon: Icon(Icons.lock, size: 18), text: 'Segredo'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome / Título',
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        isDense: true,
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
