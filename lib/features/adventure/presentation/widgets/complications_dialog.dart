import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/ai/ai_prompts.dart";
import "../../../../core/ai/ai_providers.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/sync/unsynced_changes_provider.dart";
import "../../application/adventure_providers.dart";
import "../../domain/domain.dart";

class ComplicationsDialog extends ConsumerStatefulWidget {
  final String adventureId;

  const ComplicationsDialog({super.key, required this.adventureId});

  @override
  ConsumerState<ComplicationsDialog> createState() =>
      _ComplicationsDialogState();
}

class _ComplicationsDialogState extends ConsumerState<ComplicationsDialog> {
  bool _loading = true;
  String? _errorMessage;
  String _resultText = "";

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(geminiServiceProvider);
      if (service == null) throw Exception("IA não configurada");

      final adventure = ref.read(adventureProvider(widget.adventureId));
      final creatures = ref.read(creaturesProvider(widget.adventureId));
      final locations = ref.read(locationsProvider(widget.adventureId));
      final legends = ref.read(legendsProvider(widget.adventureId));

      final prompt = AiPrompts.buildComplicationPrompt(
        adventureName: adventure?.name ?? "",
        conceptConflict: adventure?.conceptConflict ?? "",
        creatureNames: creatures.map((c) => c.name).toList(),
        locationNames: locations.map((l) => l.name).toList(),
        legendTexts: legends.map((l) => l.text).toList(),
      );

      final result = await service.generateLongText(prompt);

      if (!mounted) return;
      setState(() {
        _resultText = result;
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Complicações Narrativas",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
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
                          Text("Analisando a aventura..."),
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
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final sections = _parseComplications(_resultText);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in sections) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (section.suggestedType == "EVENTO")
                          OutlinedButton.icon(
                            onPressed: () => _saveAsEvent(section),
                            icon: const Icon(Icons.casino, size: 14),
                            label: const Text("Salvar como Evento"),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => _saveAsLegend(section),
                            icon: const Icon(Icons.campaign, size: 14),
                            label: const Text("Salvar como Rumor"),
                          ),
                        const SizedBox(width: 8),
                        if (section.suggestedType == "EVENTO")
                          TextButton.icon(
                            onPressed: () => _saveAsLegend(section),
                            icon: const Icon(Icons.campaign, size: 14),
                            label: const Text("Como Rumor"),
                          )
                        else
                          TextButton.icon(
                            onPressed: () => _saveAsEvent(section),
                            icon: const Icon(Icons.casino, size: 14),
                            label: const Text("Como Evento"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveAsEvent(_ComplicationSection section) async {
    final db = ref.read(hiveDatabaseProvider);
    final event = RandomEvent.create(
      adventureId: widget.adventureId,
      diceRange: "—",
      eventType: EventType.environment,
      description: section.title,
      impact: section.body,
    );
    await db.saveRandomEvent(event);
    ref.invalidate(randomEventsProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Salvo como Evento!"),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _saveAsLegend(_ComplicationSection section) async {
    final db = ref.read(hiveDatabaseProvider);
    final legend = Legend.create(
      adventureId: widget.adventureId,
      text: "${section.title}\n${section.body}",
      isTrue: true,
      diceResult: "—",
    );
    await db.saveLegend(legend);
    ref.invalidate(legendsProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Salvo como Rumor!"),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  List<_ComplicationSection> _parseComplications(String text) {
    final sections = <_ComplicationSection>[];
    final blocks = text.split("---");

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      final lines = trimmed.split("\n");
      String title = "";
      final bodyLines = <String>[];
      String suggestedType = "EVENTO";

      for (final line in lines) {
        final clean = line.trim();
        if (clean.startsWith("## ")) {
          title = clean.replaceFirst("## ", "").trim();
        } else if (clean.toLowerCase().contains("tipo sugerido")) {
          if (clean.toUpperCase().contains("RUMOR")) {
            suggestedType = "RUMOR";
          }
        } else if (clean.isNotEmpty) {
          bodyLines.add(
            clean
                .replaceAll("**O que acontece:**", "")
                .replaceAll("**Impacto na mesa:**", "\n💥 ")
                .trim(),
          );
        }
      }

      if (title.isNotEmpty || bodyLines.isNotEmpty) {
        sections.add(
          _ComplicationSection(
            title: title.isEmpty ? "Complicação" : title,
            body: bodyLines.join("\n"),
            suggestedType: suggestedType,
          ),
        );
      }
    }

    return sections;
  }
}

class _ComplicationSection {
  final String title;
  final String body;
  final String suggestedType;

  const _ComplicationSection({
    required this.title,
    required this.body,
    required this.suggestedType,
  });
}
