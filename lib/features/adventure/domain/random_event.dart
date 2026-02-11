import 'package:uuid/uuid.dart';

/// Event types for the random event table
enum EventType {
  patrol, // Enemies find player tracks
  environment, // Environmental change (torch dies, floor shakes)
  sound, // Distant hint of what's coming
  calm, // Time for players to plan
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.patrol:
        return 'PATRULHA';
      case EventType.environment:
        return 'AMBIENTE';
      case EventType.sound:
        return 'SOM';
      case EventType.calm:
        return 'CALMA';
    }
  }
}

/// Random Event for the "pulse" of the adventure site
///
/// Rolled every X turns to keep the site feeling alive:
/// 1: Patrol - enemies find player tracks
/// 2: Environment change - torch dies, door locks
/// 3: Distant sound - hint without immediate combat
/// 4-6: Calm - time for planning
class RandomEvent {
  String id;
  String adventureId;

  /// Dice range that triggers this event (e.g., "1", "2", "4-6")
  String diceRange;

  /// Event type
  EventType eventType;

  /// Event description
  String description;

  /// Impact on the game
  String impact;

  RandomEvent({
    String? id,
    required this.adventureId,
    required this.diceRange,
    this.eventType = EventType.calm,
    required this.description,
    required this.impact,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'diceRange': diceRange,
    'eventType': eventType.index,
    'description': description,
    'impact': impact,
  };

  factory RandomEvent.fromJson(Map<String, dynamic> json) => RandomEvent(
    id: json['id'] as String,
    adventureId: json['adventureId'] as String,
    diceRange: json['diceRange'] as String,
    eventType: EventType.values[json['eventType'] as int],
    description: json['description'] as String,
    impact: json['impact'] as String,
  );

  RandomEvent copyWith({
    String? diceRange,
    EventType? eventType,
    String? description,
    String? impact,
  }) {
    return RandomEvent(
      id: id,
      adventureId: adventureId,
      diceRange: diceRange ?? this.diceRange,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      impact: impact ?? this.impact,
    );
  }
}
