import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/sync/unsynced_changes_provider.dart";
import "../../application/adventure_generator.dart";
import "../../application/adventure_providers.dart";
import "../../domain/domain.dart";

class AdventureGeneratorPage extends ConsumerStatefulWidget {
  final String adventureId;

  const AdventureGeneratorPage({super.key, required this.adventureId});

  @override
  ConsumerState<AdventureGeneratorPage> createState() =>
      _AdventureGeneratorPageState();
}

enum _WizardStep { config, loading, preview }

class _AdventureGeneratorPageState
    extends ConsumerState<AdventureGeneratorPage> {
  _WizardStep _step = _WizardStep.config;
  GeneratedAdventure? _generated;
  String? _errorMessage;
  String _loadingMessage = "Preparando o pergaminho...";

  // Toggles for what to generate
  bool _genLocations = true;
  bool _genCreatures = true;
  bool _genLegends = true;
  bool _genEvents = true;

  // Track which items to keep (all true by default)
  late Map<String, bool> _keepItems;

  @override
  Widget build(BuildContext context) {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    if (adventure == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Gerar Aventura")),
        body: const Center(child: Text("Aventura não encontrada")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text("Gerar Aventura com IA"),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          _WizardStep.config => _buildConfigStep(adventure),
          _WizardStep.loading => _buildLoadingStep(),
          _WizardStep.preview => _buildPreviewStep(adventure),
        },
      ),
    );
  }

  Widget _buildConfigStep(Adventure adventure) {
    final hasConcept =
        adventure.conceptWhat.isNotEmpty &&
        adventure.conceptConflict.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Conceito da Aventura",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!hasConcept)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: AppTheme.error, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Preencha o Conceito (O quê + Conflito) na aba Conceito antes de gerar.",
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _InfoField(
                      label: "O quê / Onde",
                      value: adventure.conceptWhat,
                    ),
                    const SizedBox(height: 8),
                    _InfoField(
                      label: "Conflito Central",
                      value: adventure.conceptConflict,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        "O que gerar?",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _genLocations,
                    onChanged: (v) => setState(() => _genLocations = v ?? true),
                    title: const Text("📍 Locais & Pontos de Interesse"),
                    subtitle: const Text("2-3 locais com 3-5 salas cada"),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _genCreatures,
                    onChanged: (v) => setState(() => _genCreatures = v ?? true),
                    title: const Text("🐉 Criaturas & NPCs"),
                    subtitle: const Text("3-5 com stats e motivações"),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _genLegends,
                    onChanged: (v) => setState(() => _genLegends = v ?? true),
                    title: const Text("📜 Rumores & Lendas"),
                    subtitle: const Text("4-6 mix de verdade e mentira"),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _genEvents,
                    onChanged: (v) => setState(() => _genEvents = v ?? true),
                    title: const Text("🎲 Eventos Aleatórios"),
                    subtitle: const Text("4-6 encontros e eventos"),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: FilledButton.icon(
              onPressed: hasConcept ? () => _startGeneration(adventure) : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Gerar Aventura Completa"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 32),
          Text(
            _loadingMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Isso pode levar alguns segundos...",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(Adventure adventure) {
    final gen = _generated;
    if (gen == null) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${gen.totalItems} itens gerados. Revise e confirme.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: _saveSelected,
                icon: const Icon(Icons.save, size: 16),
                label: const Text("Salvar Selecionados"),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gen.locations.isNotEmpty)
                  _PreviewSection(
                    title: "📍 Locais (${gen.locations.length})",
                    children: gen.locations.map((l) {
                      final locPois = gen.pois
                          .where((p) => p.locationId == l.id)
                          .toList();
                      return _PreviewCard(
                        key: ValueKey(l.id),
                        id: l.id,
                        title: l.name,
                        subtitle: l.description,
                        icon: Icons.map,
                        isSelected: _keepItems[l.id] ?? true,
                        onToggle: (v) => setState(() => _keepItems[l.id] = v),
                        children: locPois
                            .map(
                              (p) => _PreviewCard(
                                key: ValueKey(p.id),
                                id: p.id,
                                title: "#${p.number} ${p.name}",
                                subtitle: p.firstImpression,
                                icon: Icons.place,
                                isSelected: _keepItems[p.id] ?? true,
                                onToggle: (v) =>
                                    setState(() => _keepItems[p.id] = v),
                              ),
                            )
                            .toList(),
                      );
                    }).toList(),
                  ),
                if (gen.creatures.isNotEmpty)
                  _PreviewSection(
                    title: "🐉 Criaturas (${gen.creatures.length})",
                    children: gen.creatures
                        .map(
                          (c) => _PreviewCard(
                            key: ValueKey(c.id),
                            id: c.id,
                            title: c.name,
                            subtitle: c.description,
                            icon: c.type == CreatureType.npc
                                ? Icons.person
                                : Icons.pets,
                            isSelected: _keepItems[c.id] ?? true,
                            onToggle: (v) =>
                                setState(() => _keepItems[c.id] = v),
                          ),
                        )
                        .toList(),
                  ),
                if (gen.legends.isNotEmpty)
                  _PreviewSection(
                    title: "📜 Rumores (${gen.legends.length})",
                    children: gen.legends
                        .map(
                          (l) => _PreviewCard(
                            key: ValueKey(l.id),
                            id: l.id,
                            title: l.isTrue ? "✅ Verdade" : "❌ Falso",
                            subtitle: l.text,
                            icon: Icons.campaign,
                            isSelected: _keepItems[l.id] ?? true,
                            onToggle: (v) =>
                                setState(() => _keepItems[l.id] = v),
                          ),
                        )
                        .toList(),
                  ),
                if (gen.events.isNotEmpty)
                  _PreviewSection(
                    title: "🎲 Eventos (${gen.events.length})",
                    children: gen.events
                        .map(
                          (e) => _PreviewCard(
                            key: ValueKey(e.id),
                            id: e.id,
                            title:
                                "[${e.diceRange}] ${e.eventType.displayName}",
                            subtitle: e.description,
                            icon: Icons.casino,
                            isSelected: _keepItems[e.id] ?? true,
                            onToggle: (v) =>
                                setState(() => _keepItems[e.id] = v),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startGeneration(Adventure adventure) async {
    setState(() {
      _step = _WizardStep.loading;
      _errorMessage = null;
    });

    // Animate loading messages
    _animateMessages();

    try {
      final generator = ref.read(adventureGeneratorProvider);
      final result = await generator.generate(
        adventureId: widget.adventureId,
        adventureName: adventure.name,
        conceptWhat: adventure.conceptWhat,
        conceptConflict: adventure.conceptConflict,
      );

      if (!mounted) return;

      _keepItems = {};
      for (final l in result.locations) {
        _keepItems[l.id] = true;
      }
      for (final p in result.pois) {
        _keepItems[p.id] = true;
      }
      for (final c in result.creatures) {
        _keepItems[c.id] = true;
      }
      for (final l in result.legends) {
        _keepItems[l.id] = true;
      }
      for (final e in result.events) {
        _keepItems[e.id] = true;
      }

      setState(() {
        _generated = result;
        _step = _WizardStep.preview;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _WizardStep.config;
        _errorMessage = "Erro ao gerar: $e";
      });
    }
  }

  void _animateMessages() async {
    final messages = [
      "Consultando os oráculos... 🔮",
      "Desenhando o mapa... 🗺️",
      "Criando criaturas... 🐉",
      "Tecendo rumores... 📜",
      "Preparando encontros... ⚔️",
      "Finalizando a aventura... ✨",
    ];
    for (final msg in messages) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _step != _WizardStep.loading) return;
      setState(() => _loadingMessage = msg);
    }
  }

  Future<void> _saveSelected() async {
    final gen = _generated;
    if (gen == null) return;

    final filtered = GeneratedAdventure(
      locations: gen.locations.where((l) => _keepItems[l.id] == true).toList(),
      pois: gen.pois.where((p) => _keepItems[p.id] == true).toList(),
      creatures: gen.creatures.where((c) => _keepItems[c.id] == true).toList(),
      legends: gen.legends.where((l) => _keepItems[l.id] == true).toList(),
      events: gen.events.where((e) => _keepItems[e.id] == true).toList(),
    );

    final generator = ref.read(adventureGeneratorProvider);
    await generator.saveAll(filtered);

    ref.invalidate(locationsProvider(widget.adventureId));
    ref.invalidate(pointsOfInterestProvider(widget.adventureId));
    ref.invalidate(creaturesProvider(widget.adventureId));
    ref.invalidate(legendsProvider(widget.adventureId));
    ref.invalidate(randomEventsProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${filtered.totalItems} itens salvos com sucesso!"),
        backgroundColor: AppTheme.success,
      ),
    );

    context.pop();
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreviewSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;

  const _PreviewCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onToggle,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? null : Colors.grey.withValues(alpha: 0.1),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? null : Colors.grey,
                decoration: isSelected ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? null : Colors.grey,
              ),
            ),
            trailing: Switch(
              value: isSelected,
              onChanged: (v) => onToggle(v),
              activeThumbColor: AppTheme.primary,
            ),
          ),
          if (children.isNotEmpty && isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }
}
