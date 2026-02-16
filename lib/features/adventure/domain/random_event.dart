import 'package:uuid/uuid.dart';

enum EventType { patrol, environment, sound, calm }

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

class RandomEvent {
  final String id;
  final String adventureId;
  final String diceRange;
  final EventType eventType;
  final String description;
  final String impact;

  const RandomEvent({
    required this.id,
    required this.adventureId,
    required this.diceRange,
    this.eventType = EventType.calm,
    required this.description,
    required this.impact,
  });

  factory RandomEvent.create({
    required String adventureId,
    required String diceRange,
    EventType eventType = EventType.calm,
    required String description,
    required String impact,
  }) {
    return RandomEvent(
      id: const Uuid().v4(),
      adventureId: adventureId,
      diceRange: diceRange,
      eventType: eventType,
      description: description,
      impact: impact,
    );
  }

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
