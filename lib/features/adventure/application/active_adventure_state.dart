import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../presentation/widgets/play_mode/scene_lenses.dart';

// ---------------------------------------------------------------------------
// Tracker item — generic counter or checkbox for dungeon turns, resources, etc.
// ---------------------------------------------------------------------------

enum TrackerItemType { counter, checkbox }

class TrackerItem {
  final String id;
  final String label;
  final TrackerItemType type;
  final int value; // counter: current value; checkbox: 0 or 1
  final int maxValue; // counter: max (0 = unlimited); checkbox: ignored
  final int alertEvery; // counter only: flash alert every N increments (0 = off)

  const TrackerItem({
    required this.id,
    required this.label,
    this.type = TrackerItemType.counter,
    this.value = 0,
    this.maxValue = 0,
    this.alertEvery = 0,
  });

  factory TrackerItem.create({
    required String label,
    TrackerItemType type = TrackerItemType.counter,
    int value = 0,
    int maxValue = 0,
    int alertEvery = 0,
  }) {
    return TrackerItem(
      id: const Uuid().v4(),
      label: label,
      type: type,
      value: value,
      maxValue: maxValue,
      alertEvery: alertEvery,
    );
  }

  TrackerItem copyWith({
    String? label,
    int? value,
    int? maxValue,
    int? alertEvery,
  }) {
    return TrackerItem(
      id: id,
      label: label ?? this.label,
      type: type,
      value: value ?? this.value,
      maxValue: maxValue ?? this.maxValue,
      alertEvery: alertEvery ?? this.alertEvery,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.index,
    'value': value,
    'maxValue': maxValue,
    'alertEvery': alertEvery,
  };

  factory TrackerItem.fromJson(Map<String, dynamic> json) => TrackerItem(
    id: json['id'] as String,
    label: json['label'] as String,
    type: TrackerItemType.values[json['type'] as int? ?? 0],
    value: json['value'] as int? ?? 0,
    maxValue: json['maxValue'] as int? ?? 0,
    alertEvery: json['alertEvery'] as int? ?? 0,
  );
}

// ---------------------------------------------------------------------------
// Active Adventure State
// ---------------------------------------------------------------------------

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
  /// Currently active session ID (links session log entries to a session)
  final String? activeSessionId;
  /// Configurable tracker items (counters, checkboxes) for exploration/travel
  final List<TrackerItem> trackerItems;
  /// Creature IDs pinned by the GM for quick access
  final Set<String> pinnedCreatureIds;
  /// Free-form scratchpad for quick notes during play
  final String scratchpad;
  /// Group march order text
  final String marchOrder;
  /// Group watch order text
  final String watchOrder;

  const ActiveAdventureState({
    this.adventureId,
    this.currentLocationId,
    this.revealedRumors = const {},
    this.revealedFacts = const {},
    this.monsterHp = const {},
    this.eventLog = const [],
    this.currentLens = SceneLens.narrative,
    this.locationNotes = const {},
    this.activeSessionId,
    this.trackerItems = const [],
    this.pinnedCreatureIds = const {},
    this.scratchpad = '',
    this.marchOrder = '',
    this.watchOrder = '',
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
    String? activeSessionId,
    bool clearActiveSessionId = false,
    List<TrackerItem>? trackerItems,
    Set<String>? pinnedCreatureIds,
    String? scratchpad,
    String? marchOrder,
    String? watchOrder,
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
      activeSessionId: clearActiveSessionId ? null : (activeSessionId ?? this.activeSessionId),
      trackerItems: trackerItems ?? this.trackerItems,
      pinnedCreatureIds: pinnedCreatureIds ?? this.pinnedCreatureIds,
      scratchpad: scratchpad ?? this.scratchpad,
      marchOrder: marchOrder ?? this.marchOrder,
      watchOrder: watchOrder ?? this.watchOrder,
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
    'activeSessionId': activeSessionId,
    'trackerItems': trackerItems.map((t) => t.toJson()).toList(),
    'pinnedCreatureIds': pinnedCreatureIds.toList(),
    'scratchpad': scratchpad,
    'marchOrder': marchOrder,
    'watchOrder': watchOrder,
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
      activeSessionId: json['activeSessionId'] as String?,
      trackerItems: (json['trackerItems'] as List<dynamic>?)
              ?.map((t) => TrackerItem.fromJson(Map<String, dynamic>.from(t as Map)))
              .toList() ??
          const [],
      pinnedCreatureIds: (json['pinnedCreatureIds'] as List<dynamic>?)
              ?.cast<String>()
              .toSet() ??
          const {},
      scratchpad: json['scratchpad'] as String? ?? '',
      marchOrder: json['marchOrder'] as String? ?? '',
      watchOrder: json['watchOrder'] as String? ?? '',
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

  void setActiveSession(String? sessionId) {
    if (sessionId == null) {
      state = state.copyWith(clearActiveSessionId: true);
    } else {
      state = state.copyWith(activeSessionId: sessionId);
    }
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

  // ── Tracker ──

  void addTrackerItem(TrackerItem item) {
    state = state.copyWith(
      trackerItems: [...state.trackerItems, item],
    );
    _persist();
  }

  void updateTrackerItem(String itemId, {int? value, String? label, int? maxValue, int? alertEvery}) {
    final items = state.trackerItems.map((t) {
      if (t.id != itemId) return t;
      return t.copyWith(
        value: value,
        label: label,
        maxValue: maxValue,
        alertEvery: alertEvery,
      );
    }).toList();
    state = state.copyWith(trackerItems: items);
    _persist();
  }

  void removeTrackerItem(String itemId) {
    state = state.copyWith(
      trackerItems: state.trackerItems.where((t) => t.id != itemId).toList(),
    );
    _persist();
  }

  void resetAllTrackers() {
    final items = state.trackerItems.map((t) => t.copyWith(value: 0)).toList();
    state = state.copyWith(trackerItems: items);
    _persist();
  }

  // ── Pinned Creatures ──

  void togglePinCreature(String creatureId) {
    final pinned = {...state.pinnedCreatureIds};
    if (pinned.contains(creatureId)) {
      pinned.remove(creatureId);
    } else {
      pinned.add(creatureId);
    }
    state = state.copyWith(pinnedCreatureIds: pinned);
    _persist();
  }

  bool isCreaturePinned(String creatureId) =>
      state.pinnedCreatureIds.contains(creatureId);

  // ── Scratchpad & Orders ──

  void updateScratchpad(String text) {
    state = state.copyWith(scratchpad: text);
    _persist();
  }

  void updateMarchOrder(String text) {
    state = state.copyWith(marchOrder: text);
    _persist();
  }

  void updateWatchOrder(String text) {
    state = state.copyWith(watchOrder: text);
    _persist();
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
