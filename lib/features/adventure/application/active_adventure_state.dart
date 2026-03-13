import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../presentation/widgets/play_mode/scene_lenses.dart';

class ActiveAdventureState {
  final String? adventureId;
  final String? currentLocationId;
  final Set<String> revealedRumors;
  /// IDs of facts that have been revealed to players during play
  final Set<String> revealedFacts;
  final Map<String, int> monsterHp;
  final List<String> eventLog;
  final SceneLens currentLens;
  /// Session-scoped GM notes per location (locationId -> note text)
  final Map<String, String> locationNotes;

  const ActiveAdventureState({
    this.adventureId,
    this.currentLocationId,
    this.revealedRumors = const {},
    this.revealedFacts = const {},
    this.monsterHp = const {},
    this.eventLog = const [],
    this.currentLens = SceneLens.narrative,
    this.locationNotes = const {},
  });

  ActiveAdventureState copyWith({
    String? adventureId,
    String? currentLocationId,
    Set<String>? revealedRumors,
    Set<String>? revealedFacts,
    Map<String, int>? monsterHp,
    List<String>? eventLog,
    SceneLens? currentLens,
    Map<String, String>? locationNotes,
  }) {
    return ActiveAdventureState(
      adventureId: adventureId ?? this.adventureId,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      revealedRumors: revealedRumors ?? this.revealedRumors,
      revealedFacts: revealedFacts ?? this.revealedFacts,
      monsterHp: monsterHp ?? this.monsterHp,
      eventLog: eventLog ?? this.eventLog,
      currentLens: currentLens ?? this.currentLens,
      locationNotes: locationNotes ?? this.locationNotes,
    );
  }

  /// Serialize to JSON for persistence
  Map<String, dynamic> toJson() => {
    'adventureId': adventureId,
    'currentLocationId': currentLocationId,
    'revealedRumors': revealedRumors.toList(),
    'revealedFacts': revealedFacts.toList(),
    'monsterHp': monsterHp,
    'eventLog': eventLog,
    'currentLens': currentLens.index,
    'locationNotes': locationNotes,
  };

  /// Deserialize from JSON
  factory ActiveAdventureState.fromJson(Map<String, dynamic> json) {
    return ActiveAdventureState(
      adventureId: json['adventureId'] as String?,
      currentLocationId: json['currentLocationId'] as String?,
      revealedRumors: (json['revealedRumors'] as List<dynamic>?)
              ?.cast<String>()
              .toSet() ??
          const {},
      revealedFacts: (json['revealedFacts'] as List<dynamic>?)
              ?.cast<String>()
              .toSet() ??
          const {},
      monsterHp: (json['monsterHp'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
          const {},
      eventLog:
          (json['eventLog'] as List<dynamic>?)?.cast<String>() ?? const [],
      currentLens: SceneLens.values.elementAtOrNull(
            json['currentLens'] as int? ?? 0,
          ) ??
          SceneLens.narrative,
      locationNotes:
          (json['locationNotes'] as Map<dynamic, dynamic>?)
              ?.cast<String, String>() ??
          const {},
    );
  }
}

class ActiveAdventureNotifier extends Notifier<ActiveAdventureState> {
  static const String _boxName = 'settings';
  static const String _keyPrefix = 'active_state_';

  @override
  ActiveAdventureState build() {
    return const ActiveAdventureState();
  }

  /// Load persisted state for the given adventure
  void loadForAdventure(String adventureId) {
    try {
      final box = Hive.box<dynamic>(_boxName);
      final raw = box.get('$_keyPrefix$adventureId');
      if (raw != null) {
        final data = Map<String, dynamic>.from(raw as Map);
        state = ActiveAdventureState.fromJson(data);
        return;
      }
    } catch (_) {
      // Fallback to empty state
    }
    state = ActiveAdventureState(adventureId: adventureId);
  }

  /// Persist current state to Hive
  void _persist() {
    if (state.adventureId == null) return;
    try {
      final box = Hive.box<dynamic>(_boxName);
      box.put('$_keyPrefix${state.adventureId}', state.toJson());
    } catch (_) {
      // Best-effort persistence
    }
  }

  void setLens(SceneLens lens) {
    if (state.currentLens != lens) {
      state = state.copyWith(currentLens: lens);
      _persist();
    }
  }

  void setLocation(String locationId) {
    if (state.currentLocationId != locationId) {
      state = state.copyWith(currentLocationId: locationId);
      logEvent('Mudou para o local: $locationId');
      _persist();
    }
  }

  void revealRumor(String rumorId) {
    if (!state.revealedRumors.contains(rumorId)) {
      state = state.copyWith(
        revealedRumors: {...state.revealedRumors, rumorId},
      );
      logEvent('Rumor revelado!');
      _persist();
    }
  }

  void toggleFactRevealed(String factId) {
    final revealed = {...state.revealedFacts};
    if (revealed.contains(factId)) {
      revealed.remove(factId);
    } else {
      revealed.add(factId);
    }
    state = state.copyWith(revealedFacts: revealed);
    _persist();
  }

  bool isFactRevealed(String factId) => state.revealedFacts.contains(factId);

  void updateLocationNote(String locationId, String note) {
    final notes = Map<String, String>.from(state.locationNotes);
    if (note.trim().isEmpty) {
      notes.remove(locationId);
    } else {
      notes[locationId] = note;
    }
    state = state.copyWith(locationNotes: notes);
    _persist();
  }

  void updateMonsterHp(String creatureId, int newHp) {
    final newMap = Map<String, int>.from(state.monsterHp);
    newMap[creatureId] = newHp;
    state = state.copyWith(monsterHp: newMap);
    _persist();
  }

  void logEvent(String message) {
    final timestamp = DateTime.now().toString().substring(11, 16);
    state = state.copyWith(
      eventLog: [...state.eventLog, '[$timestamp] $message'],
    );
    // Don't persist on every log event to avoid excessive writes
  }

  /// Clear runtime state but keep persisted data
  void clear() {
    _persist(); // Save before clearing
    state = const ActiveAdventureState();
  }

  /// Completely wipe persisted state for an adventure
  void clearPersisted(String adventureId) {
    try {
      final box = Hive.box<dynamic>(_boxName);
      box.delete('$_keyPrefix$adventureId');
    } catch (_) {}
    state = const ActiveAdventureState();
  }
}

final activeAdventureProvider =
    NotifierProvider<ActiveAdventureNotifier, ActiveAdventureState>(
      ActiveAdventureNotifier.new,
    );
