import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveAdventureState {
  final String? currentLocationId;
  final Set<String> revealedRumors;
  final Map<String, int> monsterHp;
  final List<String> eventLog;

  const ActiveAdventureState({
    this.currentLocationId,
    this.revealedRumors = const {},
    this.monsterHp = const {},
    this.eventLog = const [],
  });

  ActiveAdventureState copyWith({
    String? currentLocationId,
    Set<String>? revealedRumors,
    Map<String, int>? monsterHp,
    List<String>? eventLog,
  }) {
    return ActiveAdventureState(
      currentLocationId: currentLocationId ?? this.currentLocationId,
      revealedRumors: revealedRumors ?? this.revealedRumors,
      monsterHp: monsterHp ?? this.monsterHp,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

class ActiveAdventureNotifier extends StateNotifier<ActiveAdventureState> {
  ActiveAdventureNotifier() : super(const ActiveAdventureState());

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
    StateNotifierProvider<ActiveAdventureNotifier, ActiveAdventureState>((ref) {
      return ActiveAdventureNotifier();
    });
