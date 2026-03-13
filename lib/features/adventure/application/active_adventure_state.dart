import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/widgets/play_mode/scene_lenses.dart';

class ActiveAdventureState {
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
    this.currentLocationId,
    this.revealedRumors = const {},
    this.revealedFacts = const {},
    this.monsterHp = const {},
    this.eventLog = const [],
    this.currentLens = SceneLens.narrative,
    this.locationNotes = const {},
  });

  ActiveAdventureState copyWith({
    String? currentLocationId,
    Set<String>? revealedRumors,
    Set<String>? revealedFacts,
    Map<String, int>? monsterHp,
    List<String>? eventLog,
    SceneLens? currentLens,
    Map<String, String>? locationNotes,
  }) {
    return ActiveAdventureState(
      currentLocationId: currentLocationId ?? this.currentLocationId,
      revealedRumors: revealedRumors ?? this.revealedRumors,
      revealedFacts: revealedFacts ?? this.revealedFacts,
      monsterHp: monsterHp ?? this.monsterHp,
      eventLog: eventLog ?? this.eventLog,
      currentLens: currentLens ?? this.currentLens,
      locationNotes: locationNotes ?? this.locationNotes,
    );
  }
}

class ActiveAdventureNotifier extends Notifier<ActiveAdventureState> {
  @override
  ActiveAdventureState build() {
    return const ActiveAdventureState();
  }

  void setLens(SceneLens lens) {
    if (state.currentLens != lens) {
      state = state.copyWith(currentLens: lens);
    }
  }

  void setLocation(String locationId) {
    if (state.currentLocationId != locationId) {
      state = state.copyWith(currentLocationId: locationId);
      logEvent('Mudou para o local: $locationId');
    }
  }

  void revealRumor(String rumorId) {
    if (!state.revealedRumors.contains(rumorId)) {
      state = state.copyWith(
        revealedRumors: {...state.revealedRumors, rumorId},
      );
      logEvent('Rumor revelado!');
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
  }

  void updateMonsterHp(String creatureId, int newHp) {
    final newMap = Map<String, int>.from(state.monsterHp);
    newMap[creatureId] = newHp;
    state = state.copyWith(monsterHp: newMap);
    logEvent('Criatura $creatureId agora tem $newHp PV');
  }

  void logEvent(String message) {
    final timestamp = DateTime.now().toString().substring(11, 16);
    state = state.copyWith(
      eventLog: [...state.eventLog, '[$timestamp] $message'],
    );
  }

  void clear() {
    state = const ActiveAdventureState();
  }
}

final activeAdventureProvider =
    NotifierProvider<ActiveAdventureNotifier, ActiveAdventureState>(
      ActiveAdventureNotifier.new,
    );
