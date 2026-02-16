import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/widgets/play_mode/scene_lenses.dart';

class ActiveAdventureState {
  final String? currentLocationId;
  final Set<String> revealedRumors;
  final Map<String, int> monsterHp;
  final List<String> eventLog;
  final SceneLens currentLens;

  const ActiveAdventureState({
    this.currentLocationId,
    this.revealedRumors = const {},
    this.monsterHp = const {},
    this.eventLog = const [],
    this.currentLens = SceneLens.narrative,
  });

  ActiveAdventureState copyWith({
    String? currentLocationId,
    Set<String>? revealedRumors,
    Map<String, int>? monsterHp,
    List<String>? eventLog,
    SceneLens? currentLens,
  }) {
    return ActiveAdventureState(
      currentLocationId: currentLocationId ?? this.currentLocationId,
      revealedRumors: revealedRumors ?? this.revealedRumors,
      monsterHp: monsterHp ?? this.monsterHp,
      eventLog: eventLog ?? this.eventLog,
      currentLens: currentLens ?? this.currentLens,
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
