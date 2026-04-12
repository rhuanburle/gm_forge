import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/debouncer.dart';
import '../../../application/adventure_providers.dart';
import '../../../application/active_adventure_state.dart';
import '../../../domain/domain.dart';

// ---------------------------------------------------------------------------
// Combat participant model (persisted to Hive)
// ---------------------------------------------------------------------------

enum CombatCondition {
  blinded,
  charmed,
  deafened,
  frightened,
  grappled,
  incapacitated,
  invisible,
  paralyzed,
  petrified,
  poisoned,
  prone,
  restrained,
  stunned,
  unconscious,
  exhaustion,
  concentration,
}

extension CombatConditionExt on CombatCondition {
  String get displayName {
    switch (this) {
      case CombatCondition.blinded:
        return 'Cego';
      case CombatCondition.charmed:
        return 'Enfeitiçado';
      case CombatCondition.deafened:
        return 'Surdo';
      case CombatCondition.frightened:
        return 'Amedrontado';
      case CombatCondition.grappled:
        return 'Agarrado';
      case CombatCondition.incapacitated:
        return 'Incapacitado';
      case CombatCondition.invisible:
        return 'Invisível';
      case CombatCondition.paralyzed:
        return 'Paralisado';
      case CombatCondition.petrified:
        return 'Petrificado';
      case CombatCondition.poisoned:
        return 'Envenenado';
      case CombatCondition.prone:
        return 'Caído';
      case CombatCondition.restrained:
        return 'Impedido';
      case CombatCondition.stunned:
        return 'Atordoado';
      case CombatCondition.unconscious:
        return 'Inconsciente';
      case CombatCondition.exhaustion:
        return 'Exaustão';
      case CombatCondition.concentration:
        return 'Concentração';
    }
  }

  Color get color {
    switch (this) {
      case CombatCondition.blinded:
      case CombatCondition.deafened:
        return Colors.grey;
      case CombatCondition.charmed:
      case CombatCondition.frightened:
        return Colors.purple;
      case CombatCondition.grappled:
      case CombatCondition.restrained:
        return Colors.orange;
      case CombatCondition.incapacitated:
      case CombatCondition.paralyzed:
      case CombatCondition.stunned:
      case CombatCondition.petrified:
        return AppTheme.combat;
      case CombatCondition.invisible:
        return Colors.cyan;
      case CombatCondition.poisoned:
        return Colors.green.shade800;
      case CombatCondition.prone:
        return Colors.brown;
      case CombatCondition.unconscious:
        return Colors.red.shade900;
      case CombatCondition.exhaustion:
        return Colors.amber.shade800;
      case CombatCondition.concentration:
        return AppTheme.info;
    }
  }

  IconData get icon {
    switch (this) {
      case CombatCondition.blinded:
        return Icons.visibility_off;
      case CombatCondition.charmed:
        return Icons.favorite;
      case CombatCondition.deafened:
        return Icons.hearing_disabled;
      case CombatCondition.frightened:
        return Icons.warning_amber;
      case CombatCondition.grappled:
        return Icons.pan_tool;
      case CombatCondition.incapacitated:
        return Icons.block;
      case CombatCondition.invisible:
        return Icons.blur_on;
      case CombatCondition.paralyzed:
        return Icons.accessibility_new;
      case CombatCondition.petrified:
        return Icons.landscape;
      case CombatCondition.poisoned:
        return Icons.science;
      case CombatCondition.prone:
        return Icons.airline_seat_flat;
      case CombatCondition.restrained:
        return Icons.link;
      case CombatCondition.stunned:
        return Icons.flash_on;
      case CombatCondition.unconscious:
        return Icons.hotel;
      case CombatCondition.exhaustion:
        return Icons.battery_alert;
      case CombatCondition.concentration:
        return Icons.psychology;
    }
  }
}

class CombatParticipant {
  final String id;
  final String name;
  final int initiative;
  final int currentHp;
  final int maxHp;
  final int armorClass;
  final List<CombatCondition> conditions;
  final bool isPlayerCharacter;
  final String? creatureId;
  final String notes;

  const CombatParticipant({
    required this.id,
    required this.name,
    this.initiative = 0,
    this.currentHp = 10,
    this.maxHp = 10,
    this.armorClass = 10,
    this.conditions = const [],
    this.isPlayerCharacter = false,
    this.creatureId,
    this.notes = '',
  });

  factory CombatParticipant.create({
    required String name,
    int initiative = 0,
    int currentHp = 10,
    int maxHp = 10,
    int armorClass = 10,
    bool isPlayerCharacter = false,
    String? creatureId,
    String notes = '',
  }) {
    return CombatParticipant(
      id: const Uuid().v4(),
      name: name,
      initiative: initiative,
      currentHp: currentHp,
      maxHp: maxHp,
      armorClass: armorClass,
      isPlayerCharacter: isPlayerCharacter,
      creatureId: creatureId,
      notes: notes,
    );
  }

  CombatParticipant copyWith({
    String? name,
    int? initiative,
    int? currentHp,
    int? maxHp,
    int? armorClass,
    List<CombatCondition>? conditions,
    bool? isPlayerCharacter,
    String? creatureId,
    String? notes,
  }) {
    return CombatParticipant(
      id: id,
      name: name ?? this.name,
      initiative: initiative ?? this.initiative,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      armorClass: armorClass ?? this.armorClass,
      conditions: conditions ?? this.conditions,
      isPlayerCharacter: isPlayerCharacter ?? this.isPlayerCharacter,
      creatureId: creatureId ?? this.creatureId,
      notes: notes ?? this.notes,
    );
  }

  bool get isDead => currentHp <= 0;
  double get hpPercent => maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0;

  Color get hpColor {
    if (hpPercent > 0.5) return AppTheme.success;
    if (hpPercent > 0.25) return AppTheme.warning;
    return AppTheme.combat;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initiative': initiative,
    'currentHp': currentHp,
    'maxHp': maxHp,
    'armorClass': armorClass,
    'conditions': conditions.map((c) => c.name).toList(),
    'isPlayerCharacter': isPlayerCharacter,
    'creatureId': creatureId,
    'notes': notes,
  };

  factory CombatParticipant.fromJson(Map<String, dynamic> json) {
    return CombatParticipant(
      id: json['id'] as String,
      name: json['name'] as String,
      initiative: json['initiative'] as int? ?? 0,
      currentHp: json['currentHp'] as int? ?? 10,
      maxHp: json['maxHp'] as int? ?? 10,
      armorClass: json['armorClass'] as int? ?? 10,
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((c) {
                if (c is int) {
                  // Legacy index-based format
                  return c < CombatCondition.values.length
                      ? CombatCondition.values[c]
                      : CombatCondition.blinded;
                }
                return CombatCondition.values.firstWhere(
                  (v) => v.name == (c as String),
                  orElse: () => CombatCondition.blinded,
                );
              })
              .toList() ??
          const [],
      isPlayerCharacter: json['isPlayerCharacter'] as bool? ?? false,
      creatureId: json['creatureId'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Combat state
// ---------------------------------------------------------------------------

class CombatState {
  final List<CombatParticipant> participants;
  final int currentRound;
  final int currentTurnIndex;
  final bool isActive;

  const CombatState({
    this.participants = const [],
    this.currentRound = 1,
    this.currentTurnIndex = 0,
    this.isActive = false,
  });

  CombatParticipant? get currentParticipant =>
      participants.isNotEmpty && currentTurnIndex < participants.length
          ? participants[currentTurnIndex]
          : null;

  CombatState copyWith({
    List<CombatParticipant>? participants,
    int? currentRound,
    int? currentTurnIndex,
    bool? isActive,
  }) {
    return CombatState(
      participants: participants ?? this.participants,
      currentRound: currentRound ?? this.currentRound,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'participants': participants.map((p) => p.toJson()).toList(),
    'currentRound': currentRound,
    'currentTurnIndex': currentTurnIndex,
    'isActive': isActive,
  };

  factory CombatState.fromJson(Map<String, dynamic> json) {
    return CombatState(
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => CombatParticipant.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList() ??
          const [],
      currentRound: json['currentRound'] as int? ?? 1,
      currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class CombatNotifier extends Notifier<CombatState> {
  static const String _boxName = 'settings';
  static const String _keyPrefix = 'combat_state_';

  String? _adventureId;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  CombatState build() => const CombatState();

  /// Load persisted combat state for the given adventure
  void loadForAdventure(String adventureId) {
    _adventureId = adventureId;
    try {
      final box = Hive.box<dynamic>(_boxName);
      final raw = box.get('$_keyPrefix$adventureId');
      if (raw != null) {
        final data = Map<String, dynamic>.from(raw as Map);
        state = CombatState.fromJson(data);
        return;
      }
    } catch (_) {
      // Fallback to empty state
    }
    state = const CombatState();
  }

  void _persist() {
    if (_adventureId == null) return;
    _debouncer.run(() {
      try {
        final box = Hive.box<dynamic>(_boxName);
        box.put('$_keyPrefix$_adventureId', state.toJson());
      } catch (_) {}
    });
  }

  /// Flush pending persistence (call before leaving play mode)
  void flush() => _debouncer.flush();

  void startCombat() {
    state = state.copyWith(isActive: true, currentRound: 1, currentTurnIndex: 0);
    _sortByInitiative();
    _persist();
  }

  void endCombat() {
    state = const CombatState();
    _persistImmediate();
  }

  void _persistImmediate() {
    if (_adventureId == null) return;
    try {
      final box = Hive.box<dynamic>(_boxName);
      box.put('$_keyPrefix$_adventureId', state.toJson());
    } catch (_) {}
  }

  void addParticipant(CombatParticipant participant) {
    final list = [...state.participants, participant];
    state = state.copyWith(participants: list);
    if (state.isActive) _sortByInitiative();
    _persist();
  }

  void removeParticipant(String id) {
    final idx = state.participants.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final list = [...state.participants]..removeAt(idx);
    if (list.isEmpty) {
      state = state.copyWith(participants: list, currentTurnIndex: 0);
      _persist();
      return;
    }
    var turnIdx = state.currentTurnIndex;
    if (idx < turnIdx) {
      turnIdx = (turnIdx - 1).clamp(0, list.length - 1);
    } else if (turnIdx >= list.length) {
      turnIdx = 0;
    }
    state = state.copyWith(participants: list, currentTurnIndex: turnIdx);
    _persist();
  }

  void nextTurn() {
    if (state.participants.isEmpty) return;
    var nextIdx = state.currentTurnIndex + 1;
    var nextRound = state.currentRound;
    if (nextIdx >= state.participants.length) {
      nextIdx = 0;
      nextRound++;
    }
    state = state.copyWith(currentTurnIndex: nextIdx, currentRound: nextRound);
    _persist();
  }

  void previousTurn() {
    if (state.participants.isEmpty) return;
    var prevIdx = state.currentTurnIndex - 1;
    var prevRound = state.currentRound;
    if (prevIdx < 0) {
      prevIdx = state.participants.length - 1;
      prevRound = (prevRound - 1).clamp(1, 999);
    }
    state = state.copyWith(currentTurnIndex: prevIdx, currentRound: prevRound);
    _persist();
  }

  void updateParticipant(String id, CombatParticipant Function(CombatParticipant) updater) {
    final list = state.participants.map((p) => p.id == id ? updater(p) : p).toList();
    state = state.copyWith(participants: list);
    _persist();
  }

  void updateInitiative(String id, int initiative) {
    updateParticipant(id, (p) => p.copyWith(initiative: initiative));
    if (state.isActive) _sortByInitiative();
  }

  void updateHp(String id, int delta) {
    updateParticipant(id, (p) => p.copyWith(
      currentHp: (p.currentHp + delta).clamp(-10, p.maxHp),
    ));
  }

  void setHp(String id, int hp) {
    updateParticipant(id, (p) => p.copyWith(currentHp: hp.clamp(-10, p.maxHp)));
  }

  void toggleCondition(String id, CombatCondition condition) {
    updateParticipant(id, (p) {
      final conditions = [...p.conditions];
      if (conditions.contains(condition)) {
        conditions.remove(condition);
      } else {
        conditions.add(condition);
      }
      return p.copyWith(conditions: conditions);
    });
  }

  void _sortByInitiative() {
    final currentId = state.currentParticipant?.id;
    final sorted = [...state.participants]
      ..sort((a, b) => b.initiative.compareTo(a.initiative));
    var newIdx = 0;
    if (currentId != null) {
      final idx = sorted.indexWhere((p) => p.id == currentId);
      if (idx != -1) newIdx = idx;
    }
    state = state.copyWith(participants: sorted, currentTurnIndex: newIdx);
  }

  /// Roll d20 for NPC participants only (PCs keep their current initiative).
  void rollAllInitiatives({bool includePlayerCharacters = false}) {
    final rng = Random();
    final list = state.participants.map((p) {
      if (!includePlayerCharacters && p.isPlayerCharacter) return p;
      final roll = rng.nextInt(20) + 1;
      return p.copyWith(initiative: roll);
    }).toList();
    state = state.copyWith(participants: list);
    _sortByInitiative();
    _persist();
  }
}

final combatProvider = NotifierProvider<CombatNotifier, CombatState>(
  CombatNotifier.new,
);

// ---------------------------------------------------------------------------
// Combat tracker widget
// ---------------------------------------------------------------------------

class CombatTrackerPanel extends ConsumerStatefulWidget {
  final String adventureId;

  const CombatTrackerPanel({super.key, required this.adventureId});

  @override
  ConsumerState<CombatTrackerPanel> createState() => _CombatTrackerPanelState();
}

class _CombatTrackerPanelState extends ConsumerState<CombatTrackerPanel> {
  @override
  Widget build(BuildContext context) {
    final combat = ref.watch(combatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.shield, size: 16, color: AppTheme.combat),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tracker de Combate',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.combat,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!combat.isActive)
                TextButton.icon(
                  onPressed: () => _showAddParticipantSheet(context),
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),

        if (combat.participants.isEmpty && !combat.isActive)
          _EmptyCombatState(
            adventureId: widget.adventureId,
            onAddParticipant: () => _showAddParticipantSheet(context),
          ),

        if (combat.participants.isNotEmpty) ...[
          // Combat controls
          _CombatControls(isActive: combat.isActive),

          // Round info
          if (combat.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rodada ${combat.currentRound}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (combat.currentParticipant != null)
                    Expanded(
                      child: Text(
                        'Turno: ${combat.currentParticipant!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Participant list
          ...combat.participants.asMap().entries.map((entry) {
            final idx = entry.key;
            final participant = entry.value;
            final isCurrent = combat.isActive && idx == combat.currentTurnIndex;
            return _ParticipantCard(
              participant: participant,
              isCurrent: isCurrent,
              isActive: combat.isActive,
            );
          }),

          // Add more button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _showAddParticipantSheet(context),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar ao Combate', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
        ],

        const Divider(height: 1),
      ],
    );
  }

  void _showAddParticipantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddParticipantSheet(adventureId: widget.adventureId),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyCombatState extends ConsumerWidget {
  final String adventureId;
  final VoidCallback onAddParticipant;

  const _EmptyCombatState({required this.adventureId, required this.onAddParticipant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, size: 32, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          const Text(
            'Nenhum combate ativo',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddParticipant,
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _quickAddFromScene(ref),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: const Text('Da Cena', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: AppTheme.combat,
                    side: const BorderSide(color: AppTheme.combat),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _quickAddFromScene(WidgetRef ref) {
    final activeState = ref.read(activeAdventureProvider);
    if (activeState.currentLocationId == null) return;

    final pois = ref.read(pointsOfInterestProvider(adventureId));
    final currentPoi = pois.where((p) => p.id == activeState.currentLocationId).firstOrNull;
    if (currentPoi == null || currentPoi.creatureIds.isEmpty) return;

    final allCreatures = ref.read(creaturesProvider(adventureId));
    final combat = ref.read(combatProvider.notifier);
    final existing = ref.read(combatProvider).participants;

    for (final cid in currentPoi.creatureIds) {
      // Skip if already added
      if (existing.any((p) => p.creatureId == cid)) continue;

      final creature = allCreatures.where((c) => c.id == cid).firstOrNull;
      if (creature == null) continue;

      final maxHp = _parseHp(creature.stats);
      final ac = _parseAc(creature.stats);
      combat.addParticipant(CombatParticipant.create(
        name: creature.name,
        currentHp: maxHp,
        maxHp: maxHp,
        armorClass: ac,
        isPlayerCharacter: false,
        creatureId: creature.id,
      ));
    }

    // Also add PCs if campaign exists
    final adventure = ref.read(adventureProvider(adventureId));
    if (adventure?.campaignId != null) {
      final pcs = ref.read(playerCharactersProvider(adventure!.campaignId!));
      for (final pc in pcs) {
        if (existing.any((p) => p.name == pc.name)) continue;
        combat.addParticipant(CombatParticipant.create(
          name: pc.name,
          currentHp: 10,
          maxHp: 10,
          armorClass: 10,
          isPlayerCharacter: true,
        ));
      }
    }
  }

  static int _parseHp(String stats) {
    final regex = RegExp(r'(?:HP|PV|Vida)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    return match != null ? (int.tryParse(match.group(1) ?? '') ?? 10) : 10;
  }

  static int _parseAc(String stats) {
    final regex = RegExp(r'(?:CA|AC|Armadura)[: ]\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(stats);
    return match != null ? (int.tryParse(match.group(1) ?? '') ?? 10) : 10;
  }
}

// ---------------------------------------------------------------------------
// Combat controls (start/end/turn navigation)
// ---------------------------------------------------------------------------

class _CombatControls extends ConsumerWidget {
  final bool isActive;

  const _CombatControls({required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combat = ref.read(combatProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (!isActive) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => combat.startCombat(),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Iniciar Combate', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.combat,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => combat.rollAllInitiatives(),
              icon: const Icon(Icons.casino, size: 18),
              tooltip: 'Rolar Iniciativas NPCs (d20)',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceLight,
              ),
            ),
          ],
          if (isActive) ...[
            IconButton(
              onPressed: () => combat.previousTurn(),
              icon: const Icon(Icons.skip_previous, size: 20),
              tooltip: 'Turno Anterior',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => combat.nextTurn(),
                icon: const Icon(Icons.skip_next, size: 16),
                label: const Text('Próximo Turno', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.combat,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => combat.rollAllInitiatives(),
              icon: const Icon(Icons.casino, size: 18),
              tooltip: 'Re-rolar Iniciativas NPCs',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Encerrar Combate?'),
                    content: const Text('O tracker será limpo.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          combat.endCombat();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.combat),
                        child: const Text('Encerrar'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.stop, size: 20, color: AppTheme.combat),
              tooltip: 'Encerrar Combate',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Participant card
// ---------------------------------------------------------------------------

class _ParticipantCard extends ConsumerWidget {
  final CombatParticipant participant;
  final bool isCurrent;
  final bool isActive;

  const _ParticipantCard({
    required this.participant,
    required this.isCurrent,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combat = ref.read(combatProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.combat.withValues(alpha: 0.15)
            : participant.isDead
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? AppTheme.combat
              : participant.isDead
                  ? AppTheme.textMuted.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row: initiative, name, HP controls
            Row(
              children: [
                // Initiative badge
                GestureDetector(
                  onTap: () => _editInitiative(context, ref),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: participant.isPlayerCharacter
                          ? AppTheme.info.withValues(alpha: 0.3)
                          : AppTheme.combat.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: participant.isPlayerCharacter
                            ? AppTheme.info
                            : AppTheme.combat,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${participant.initiative}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: participant.isPlayerCharacter
                            ? AppTheme.info
                            : AppTheme.combat,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Name + type + AC
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: participant.isDead
                              ? AppTheme.textMuted
                              : null,
                          decoration: participant.isDead
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            participant.isPlayerCharacter ? 'PC' : 'NPC',
                            style: TextStyle(
                              fontSize: 9,
                              color: participant.isPlayerCharacter
                                  ? AppTheme.info
                                  : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.shield_outlined, size: 10, color: AppTheme.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            'CA ${participant.armorClass}',
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // HP controls
                IconButton(
                  icon: const Icon(Icons.remove, size: 14),
                  onPressed: () => combat.updateHp(participant.id, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  color: AppTheme.combat,
                  iconSize: 14,
                ),
                GestureDetector(
                  onTap: () => _editHp(context, ref),
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: participant.hpColor.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${participant.currentHp}/${participant.maxHp}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: participant.hpColor,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: participant.hpPercent,
                            minHeight: 3,
                            backgroundColor: AppTheme.surfaceLight,
                            valueColor: AlwaysStoppedAnimation(participant.hpColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  onPressed: () => combat.updateHp(participant.id, 1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  color: AppTheme.success,
                  iconSize: 14,
                ),

                // Remove
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () => combat.removeParticipant(participant.id),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  color: AppTheme.textMuted,
                  iconSize: 14,
                ),
              ],
            ),

            // Conditions row
            if (participant.conditions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 34),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: participant.conditions.map((c) {
                    return Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      avatar: Icon(c.icon, size: 10, color: c.color),
                      label: Text(
                        c.displayName,
                        style: TextStyle(fontSize: 9, color: c.color),
                      ),
                      deleteIcon: Icon(Icons.close, size: 10, color: c.color),
                      onDeleted: () => combat.toggleCondition(participant.id, c),
                      side: BorderSide(color: c.color.withValues(alpha: 0.5)),
                      backgroundColor: c.color.withValues(alpha: 0.1),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),

            // Condition add button
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: InkWell(
                onTap: () => _showConditionPicker(context, ref),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 10, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                      const SizedBox(width: 2),
                      Text(
                        'Condição',
                        style: TextStyle(fontSize: 9, color: AppTheme.textMuted.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editInitiative(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: '${participant.initiative}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Iniciativa - ${participant.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Iniciativa'),
          onSubmitted: (val) {
            final v = int.tryParse(val);
            if (v != null) ref.read(combatProvider.notifier).updateInitiative(participant.id, v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null) ref.read(combatProvider.notifier).updateInitiative(participant.id, v);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _editHp(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dano/Cura - ${participant.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HP atual: ${participant.currentHp}/${participant.maxHp}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Valor (negativo = dano)',
                hintText: 'Ex: -8 ou +5',
              ),
              onSubmitted: (val) {
                final v = int.tryParse(val);
                if (v != null) ref.read(combatProvider.notifier).updateHp(participant.id, v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null) ref.read(combatProvider.notifier).updateHp(participant.id, v);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.combat),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showConditionPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _ConditionPickerDialog(
        participantId: participant.id,
        currentConditions: participant.conditions,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Condition picker (stateful, no recursion)
// ---------------------------------------------------------------------------

class _ConditionPickerDialog extends ConsumerStatefulWidget {
  final String participantId;
  final List<CombatCondition> currentConditions;

  const _ConditionPickerDialog({
    required this.participantId,
    required this.currentConditions,
  });

  @override
  ConsumerState<_ConditionPickerDialog> createState() => _ConditionPickerDialogState();
}

class _ConditionPickerDialogState extends ConsumerState<_ConditionPickerDialog> {
  @override
  Widget build(BuildContext context) {
    // Watch to get live updates
    final combat = ref.watch(combatProvider);
    final participant = combat.participants.where((p) => p.id == widget.participantId).firstOrNull;
    final conditions = participant?.conditions ?? widget.currentConditions;

    return AlertDialog(
      title: Text('Condições${participant != null ? " - ${participant.name}" : ""}'),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CombatCondition.values.map((condition) {
            final active = conditions.contains(condition);
            return FilterChip(
              selected: active,
              avatar: Icon(condition.icon, size: 14, color: condition.color),
              label: Text(condition.displayName, style: const TextStyle(fontSize: 11)),
              selectedColor: condition.color.withValues(alpha: 0.2),
              checkmarkColor: condition.color,
              side: BorderSide(
                color: active ? condition.color : AppTheme.textMuted.withValues(alpha: 0.3),
              ),
              onSelected: (_) {
                ref.read(combatProvider.notifier).toggleCondition(widget.participantId, condition);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add participant bottom sheet
// ---------------------------------------------------------------------------

class _AddParticipantSheet extends ConsumerStatefulWidget {
  final String adventureId;

  const _AddParticipantSheet({required this.adventureId});

  @override
  ConsumerState<_AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends ConsumerState<_AddParticipantSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _nameController = TextEditingController();
  final _hpController = TextEditingController(text: '10');
  final _acController = TextEditingController(text: '10');
  final _initController = TextEditingController(text: '0');
  bool _isPC = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _hpController.dispose();
    _acController.dispose();
    _initController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 400,
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
              'Adicionar ao Combate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.secondary,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(text: 'Manual'),
                Tab(text: 'Da Cena'),
                Tab(text: 'PCs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildManualTab(),
                  _buildFromSceneTab(),
                  _buildFromPCsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hpController,
                  decoration: const InputDecoration(labelText: 'HP'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _acController,
                  decoration: const InputDecoration(labelText: 'CA'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _initController,
                  decoration: const InputDecoration(labelText: 'Iniciativa'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('É Jogador (PC)', style: TextStyle(fontSize: 14)),
            value: _isPC,
            onChanged: (v) => setState(() => _isPC = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addManual,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromSceneTab() {
    final activeState = ref.watch(activeAdventureProvider);
    final pois = ref.watch(pointsOfInterestProvider(widget.adventureId));
    final allCreatures = ref.watch(creaturesProvider(widget.adventureId));
    final combat = ref.watch(combatProvider);

    PointOfInterest? currentPoi;
    if (activeState.currentLocationId != null) {
      currentPoi = pois.where((p) => p.id == activeState.currentLocationId).firstOrNull;
    }

    if (currentPoi == null || currentPoi.creatureIds.isEmpty) {
      return const Center(
        child: Text('Nenhuma criatura na cena atual', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final creatures = allCreatures.where((c) => currentPoi!.creatureIds.contains(c.id)).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: creatures.length,
      itemBuilder: (context, index) {
        final creature = creatures[index];
        final alreadyAdded = combat.participants.any((p) => p.creatureId == creature.id);

        return ListTile(
          leading: Icon(
            creature.type == CreatureType.monster ? Icons.pets : Icons.person,
            color: alreadyAdded ? AppTheme.textMuted : AppTheme.combat,
          ),
          title: Text(creature.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            creature.stats.isEmpty ? 'Sem stats' : creature.stats,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: alreadyAdded
              ? const Icon(Icons.check, color: AppTheme.success, size: 18)
              : IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.combat, size: 20),
                  onPressed: () => _addCreature(creature),
                ),
          dense: true,
        );
      },
    );
  }

  Widget _buildFromPCsTab() {
    final adventure = ref.watch(adventureProvider(widget.adventureId));
    if (adventure?.campaignId == null) {
      return const Center(
        child: Text('Aventura não vinculada a campanha', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    final pcs = ref.watch(playerCharactersProvider(adventure!.campaignId!));
    final combat = ref.watch(combatProvider);

    if (pcs.isEmpty) {
      return const Center(
        child: Text('Nenhum PC na campanha', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        final alreadyAdded = combat.participants.any((p) => p.name == pc.name && p.isPlayerCharacter);

        return ListTile(
          leading: const Icon(Icons.person, color: AppTheme.info),
          title: Text(pc.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${pc.species} ${pc.characterClass} Lv${pc.level}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: alreadyAdded
              ? const Icon(Icons.check, color: AppTheme.success, size: 18)
              : IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.info, size: 20),
                  onPressed: () => _addPC(pc),
                ),
          dense: true,
        );
      },
    );
  }

  void _addManual() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final hp = int.tryParse(_hpController.text) ?? 10;
    final ac = int.tryParse(_acController.text) ?? 10;
    final init = int.tryParse(_initController.text) ?? 0;

    ref.read(combatProvider.notifier).addParticipant(
      CombatParticipant.create(
        name: name,
        currentHp: hp,
        maxHp: hp,
        armorClass: ac,
        initiative: init,
        isPlayerCharacter: _isPC,
      ),
    );

    _nameController.clear();
    Navigator.pop(context);
  }

  void _addCreature(Creature creature) {
    final maxHp = _EmptyCombatState._parseHp(creature.stats);
    final ac = _EmptyCombatState._parseAc(creature.stats);

    ref.read(combatProvider.notifier).addParticipant(
      CombatParticipant.create(
        name: creature.name,
        currentHp: maxHp,
        maxHp: maxHp,
        armorClass: ac,
        isPlayerCharacter: false,
        creatureId: creature.id,
      ),
    );
  }

  void _addPC(PlayerCharacter pc) {
    ref.read(combatProvider.notifier).addParticipant(
      CombatParticipant.create(
        name: pc.name,
        currentHp: 10,
        maxHp: 10,
        armorClass: 10,
        isPlayerCharacter: true,
      ),
    );
  }
}
