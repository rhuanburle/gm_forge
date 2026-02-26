import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/ai/ai_prompts.dart";
import "../../../../core/ai/ai_providers.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/sync/unsynced_changes_provider.dart";
import "../../application/adventure_providers.dart";
import "../../domain/domain.dart";

class NpcKnowledgeDialog extends ConsumerStatefulWidget {
  final String adventureId;
  final Creature creature;

  const NpcKnowledgeDialog({
    super.key,
    required this.adventureId,
    required this.creature,
  });

  @override
  ConsumerState<NpcKnowledgeDialog> createState() => _NpcKnowledgeDialogState();
}

class _NpcKnowledgeDialogState extends ConsumerState<NpcKnowledgeDialog> {
  bool _loading = true;
  String? _errorMessage;
  List<_GeneratedFact> _facts = [];

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _facts = [];
    });

    try {
      final service = ref.read(geminiServiceProvider);
      if (service == null) throw Exception("IA não configurada");

      final adventure = ref.read(adventureProvider(widget.adventureId));
      final creatures = ref.read(creaturesProvider(widget.adventureId));
      final locations = ref.read(locationsProvider(widget.adventureId));
      final legends = ref.read(legendsProvider(widget.adventureId));

      final prompt = AiPrompts.buildNpcKnowledgePrompt(
        npcName: widget.creature.name,
        npcDescription: widget.creature.description,
        npcMotivation: widget.creature.motivation,
        conceptConflict: adventure?.conceptConflict ?? "",
        creatureNames: creatures
            .where((c) => c.id != widget.creature.id)
            .map((c) => c.name)
            .toList(),
        locationNames: locations.map((l) => l.name).toList(),
        legendTexts: legends.map((l) => l.text).toList(),
      );

      final json = await service.generateStructured(prompt);

      final factsJson = json["facts"] as List<dynamic>? ?? [];
      final parsed = factsJson.map((f) {
        final data = f as Map<String, dynamic>;
        return _GeneratedFact(
          content: data["content"] as String? ?? "",
          isReliable: data["isReliable"] as bool? ?? true,
          selected: true,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _facts = parsed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "O que ${widget.creature.name} sabe?",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                        ),
                        Text(
                          "Conhecimento gerado a partir da lore",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (!_loading)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: "Regenerar",
                      onPressed: _generate,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Interrogando o NPC... 🧠"),
                        ],
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _generate,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Tentar novamente"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildFactsList(),
            ),
            if (!_loading && _errorMessage == null && _facts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "${_facts.where((f) => f.selected).length} selecionados",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveSelected,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text("Salvar Selecionados"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _facts.length,
      itemBuilder: (context, index) {
        final fact = _facts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: fact.selected ? null : Colors.grey.withValues(alpha: 0.05),
          child: CheckboxListTile(
            value: fact.selected,
            onChanged: (v) {
              setState(() {
                _facts[index] = fact.copyWith(selected: v ?? false);
              });
            },
            title: Text(
              fact.content,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: fact.selected ? null : Colors.grey,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    fact.isReliable ? Icons.verified : Icons.warning_amber,
                    size: 14,
                    color: fact.isReliable ? AppTheme.success : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fact.isReliable ? "Confiável" : "Duvidoso",
                    style: TextStyle(
                      fontSize: 11,
                      color: fact.isReliable ? AppTheme.success : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }

  Future<void> _saveSelected() async {
    final selectedFacts = _facts.where((f) => f.selected).toList();
    if (selectedFacts.isEmpty) return;

    final db = ref.read(hiveDatabaseProvider);

    for (final fact in selectedFacts) {
      final domainFact = Fact.create(
        adventureId: widget.adventureId,
        content: fact.content,
        sourceId: widget.creature.id,
        isSecret: !fact.isReliable,
        tags: ["npc-knowledge", widget.creature.name.toLowerCase()],
      );
      await db.saveFact(domainFact);
    }

    ref.invalidate(factsProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${selectedFacts.length} fatos salvos para ${widget.creature.name}!",
        ),
        backgroundColor: AppTheme.success,
      ),
    );

    Navigator.pop(context);
  }
}

class _GeneratedFact {
  final String content;
  final bool isReliable;
  final bool selected;

  const _GeneratedFact({
    required this.content,
    required this.isReliable,
    required this.selected,
  });

  _GeneratedFact copyWith({bool? selected}) {
    return _GeneratedFact(
      content: content,
      isReliable: isReliable,
      selected: selected ?? this.selected,
    );
  }
}
