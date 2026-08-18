import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/sync/unsynced_changes_provider.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../application/adventure_providers.dart';
import '../../../../domain/domain.dart';
import '../widgets/section_header.dart';

/// Round-1 minimal CRUD for Escalations and Sidebars.
/// Goal: let the user create / edit / delete entries that drive the
/// GM Shield's reminders panel. Not exhaustive — bundle import remains
/// the recommended bulk path.
class StructureTab extends ConsumerWidget {
  final String adventureId;

  const StructureTab({super.key, required this.adventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventure = ref.watch(adventureProvider(adventureId));
    final escalations = ref.watch(escalationsProvider(adventureId));
    final sidebars = ref.watch(sidebarsProvider(adventureId));

    if (adventure == null) {
      return const Center(child: Text('Aventura não encontrada'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.timer,
            title: 'Contagens / Escalações',
            subtitle:
                'Sequências de eventos que escalam durante o jogo. Útil para mistérios, horror e timers.',
          ),
          const SizedBox(height: 12),
          if (escalations.isEmpty)
            _emptyHint('Nenhuma escalação. Toque em + para criar.')
          else
            ...escalations.map((e) => _escalationCard(context, ref, e, adventure)),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => _editEscalation(context, ref, adventure, null),
              icon: const Icon(Icons.add),
              label: const Text('Nova Escalação'),
            ),
          ),
          const SizedBox(height: 32),

          const SectionHeader(
            icon: Icons.menu_book,
            title: 'Caixas Laterais / Handouts',
            subtitle:
                'Lore, regras locais, cartas — surgem no Escudo do Mestre conforme o contexto.',
          ),
          const SizedBox(height: 12),
          if (sidebars.isEmpty)
            _emptyHint('Nenhuma caixa. Toque em + para criar.')
          else
            ...sidebars.map((s) => _sidebarCard(context, ref, s, adventure)),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => _editSidebar(context, ref, adventure, null),
              icon: const Icon(Icons.add),
              label: const Text('Nova Caixa'),
            ),
          ),
          const SizedBox(height: 32),

          const SectionHeader(
            icon: Icons.psychology_alt,
            title: 'Lembretes do Mestre (Aventura)',
            subtitle:
                'Bullets curtos visíveis SÓ no Escudo do Mestre. Não aparecem em handouts.',
          ),
          const SizedBox(height: 12),
          _GmRemindersEditor(adventureId: adventureId),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppTheme.textMuted,
          ),
        ),
      );

  Widget _escalationCard(
    BuildContext context,
    WidgetRef ref,
    Escalation esc,
    Adventure adventure,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.timer, color: AppTheme.error),
        title: Text(esc.title),
        subtitle: Text(
          '${esc.steps.where((s) => s.fired).length}/${esc.steps.length} disparados'
          '${esc.description != null && esc.description!.isNotEmpty ? ' • ${esc.description}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editEscalation(context, ref, adventure, esc),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppTheme.error),
              onPressed: () async {
                await ref.read(hiveDatabaseProvider).deleteEscalation(esc.id);
                ref.invalidate(escalationsProvider(adventureId));
                ref.read(unsyncedChangesProvider.notifier).state = true;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarCard(
    BuildContext context,
    WidgetRef ref,
    Sidebar sb,
    Adventure adventure,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          sb.playerFacing ? Icons.menu_book : Icons.bookmark,
          color: AppTheme.accent,
        ),
        title: Text(sb.title),
        subtitle: Text(
          '${sb.kind}${sb.playerFacing ? ' • visível aos jogadores' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editSidebar(context, ref, adventure, sb),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppTheme.error),
              onPressed: () async {
                await ref.read(hiveDatabaseProvider).deleteSidebar(sb.id);
                ref.invalidate(sidebarsProvider(adventureId));
                ref.read(unsyncedChangesProvider.notifier).state = true;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEscalation(
    BuildContext context,
    WidgetRef ref,
    Adventure adventure,
    Escalation? existing,
  ) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final outcomeCtrl =
        TextEditingController(text: existing?.defaultOutcome ?? '');
    final stepsCtrl = TextEditingController(
      text: (existing?.steps ?? const [])
          .map((s) => s.label)
          .join('\n'),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nova Escalação' : 'Editar Escalação'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stepsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Passos (um por linha)',
                  hintText: '1ª aparição\nVelas explodem\nRitual quase pronto',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: outcomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resultado padrão (Catástrofe)',
                  hintText: 'O que acontece se os PJs nunca intervirem',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // Read fields, then dispose the controllers (all return paths below).
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final outcome = outcomeCtrl.text.trim();
    final stepsText = stepsCtrl.text;
    titleCtrl.dispose();
    descCtrl.dispose();
    outcomeCtrl.dispose();
    stepsCtrl.dispose();

    if (saved != true) return;
    if (title.isEmpty) return;

    final steps = stepsText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
      final old = existing?.steps.firstWhere(
        (s) => s.label == l,
        orElse: () => const EscalationStep(label: ''),
      );
      return EscalationStep(
        label: l,
        trigger: old?.trigger,
        effect: old?.effect,
        fired: old?.fired ?? false,
      );
    }).toList();

    final db = ref.read(hiveDatabaseProvider);
    final esc = existing == null
        ? Escalation.create(
            campaignId: adventure.campaignId ?? adventureId,
            adventureId: adventureId,
            title: title,
            description: desc.isEmpty ? null : desc,
            defaultOutcome: outcome.isEmpty ? null : outcome,
            steps: steps,
          )
        : existing.copyWith(
            title: title,
            description: desc.isEmpty ? null : desc,
            clearDescription: desc.isEmpty,
            defaultOutcome: outcome.isEmpty ? null : outcome,
            clearDefaultOutcome: outcome.isEmpty,
            steps: steps,
          );
    await db.saveEscalation(esc);
    ref.invalidate(escalationsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }

  Future<void> _editSidebar(
    BuildContext context,
    WidgetRef ref,
    Adventure adventure,
    Sidebar? existing,
  ) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    String kind = existing?.kind ?? 'lore';
    bool playerFacing = existing?.playerFacing ?? false;

    final pois = ref.read(pointsOfInterestProvider(adventureId));
    String? attachedPoiId = existing?.attachedPoiId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Nova Caixa' : 'Editar Caixa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      kSidebarKinds.contains(kind) ? kind : '__custom__',
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    ...kSidebarKinds.map(
                      (k) => DropdownMenuItem(value: k, child: Text(k)),
                    ),
                    const DropdownMenuItem(
                      value: '__custom__',
                      child: Text('Outro…'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      if (v == '__custom__') {
                        // Sentinel not in kSidebarKinds → reveals custom field.
                        kind = '';
                      } else {
                        kind = v;
                      }
                    });
                  },
                ),
                if (!kSidebarKinds.contains(kind)) ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tipo customizado',
                    ),
                    onChanged: (v) =>
                        setState(() => kind = v.trim().isEmpty ? 'lore' : v.trim()),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo (markdown leve)',
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Visível aos jogadores'),
                  subtitle: const Text(
                    'Mostra botão "Tela Cheia" no Escudo do Mestre',
                  ),
                  value: playerFacing,
                  onChanged: (v) => setState(() => playerFacing = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: attachedPoiId,
                  decoration: const InputDecoration(
                    labelText: 'Anexar a POI (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nenhum (aventura toda)'),
                    ),
                    ...pois.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text('${p.number}. ${p.name}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => attachedPoiId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text;
    titleCtrl.dispose();
    bodyCtrl.dispose();

    if (saved != true) return;
    if (title.isEmpty) return;

    final resolvedKind = kind.trim().isEmpty ? 'lore' : kind.trim();
    final db = ref.read(hiveDatabaseProvider);
    final sb = existing == null
        ? Sidebar.create(
            campaignId: adventure.campaignId ?? adventureId,
            adventureId: adventureId,
            attachedPoiId: attachedPoiId,
            title: title,
            body: body,
            kind: resolvedKind,
            playerFacing: playerFacing,
          )
        : existing.copyWith(
            title: title,
            body: body,
            kind: resolvedKind,
            playerFacing: playerFacing,
            attachedPoiId: attachedPoiId,
            clearAttachedPoiId: attachedPoiId == null,
          );
    await db.saveSidebar(sb);
    ref.invalidate(sidebarsProvider(adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
  }
}

class _GmRemindersEditor extends ConsumerStatefulWidget {
  final String adventureId;
  const _GmRemindersEditor({required this.adventureId});

  @override
  ConsumerState<_GmRemindersEditor> createState() => _GmRemindersEditorState();
}

class _GmRemindersEditorState extends ConsumerState<_GmRemindersEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    if (adventure == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...adventure.gmReminders.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Text('• ', style: TextStyle(color: AppTheme.warning)),
                Expanded(child: Text(entry.value)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () async {
                    final next = List<String>.from(adventure.gmReminders)
                      ..removeAt(entry.key);
                    await ref
                        .read(hiveDatabaseProvider)
                        .saveAdventure(adventure.copyWith(gmReminders: next));
                    ref.invalidate(adventureProvider(widget.adventureId));
                    ref.read(unsyncedChangesProvider.notifier).state = true;
                  },
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'Novo lembrete...',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final text = _ctrl.text.trim();
                if (text.isEmpty) return;
                final next = List<String>.from(adventure.gmReminders)
                  ..add(text);
                await ref
                    .read(hiveDatabaseProvider)
                    .saveAdventure(adventure.copyWith(gmReminders: next));
                _ctrl.clear();
                ref.invalidate(adventureProvider(widget.adventureId));
                ref.read(unsyncedChangesProvider.notifier).state = true;
              },
            ),
          ],
        ),
      ],
    );
  }
}
