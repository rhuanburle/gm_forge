import 'package:uuid/uuid.dart';

enum SessionStatus { prep, played, reviewed }

extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.prep:
        return 'Preparação';
      case SessionStatus.played:
        return 'Jogada';
      case SessionStatus.reviewed:
        return 'Revisada';
    }
  }
}

class Session {
  final String id;
  final String adventureId;
  final String name;
  final DateTime date;
  final SessionStatus status;
  final int number;
  final String strongStart;
  final List<String> scenes;
  final List<String> secrets;
  final List<String> fantasticLocations;
  final List<String> npcs;
  final List<String> monsters;
  final List<String> treasures;
  final String recap;

  const Session({
    required this.id,
    required this.adventureId,
    required this.name,
    required this.date,
    this.status = SessionStatus.prep,
    this.number = 1,
    this.strongStart = '',
    this.scenes = const [],
    this.secrets = const [],
    this.fantasticLocations = const [],
    this.npcs = const [],
    this.monsters = const [],
    this.treasures = const [],
    this.recap = '',
  });

  factory Session.create({
    required String adventureId,
    required String name,
    DateTime? date,
    SessionStatus status = SessionStatus.prep,
    int number = 1,
    String strongStart = '',
    List<String> scenes = const [],
    List<String> secrets = const [],
    List<String> fantasticLocations = const [],
    List<String> npcs = const [],
    List<String> monsters = const [],
    List<String> treasures = const [],
    String recap = '',
  }) {
    return Session(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: name,
      date: date ?? DateTime.now(),
      status: status,
      number: number,
      strongStart: strongStart,
      scenes: scenes,
      secrets: secrets,
      fantasticLocations: fantasticLocations,
      npcs: npcs,
      monsters: monsters,
      treasures: treasures,
      recap: recap,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'name': name,
    'date': date.toIso8601String(),
    'status': status.index,
    'number': number,
    'strongStart': strongStart,
    'scenes': scenes,
    'secrets': secrets,
    'fantasticLocations': fantasticLocations,
    'npcs': npcs,
    'monsters': monsters,
    'treasures': treasures,
    'recap': recap,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String,
    adventureId: json['adventureId'] as String,
    name: json['name'] as String,
    date: json['date'] != null
        ? DateTime.parse(json['date'] as String)
        : DateTime.now(),
    status: SessionStatus.values[json['status'] as int? ?? 0],
    number: json['number'] as int? ?? 1,
    strongStart: json['strongStart'] as String? ?? '',
    scenes:
        (json['scenes'] as List<dynamic>?)?.cast<String>() ?? const [],
    secrets:
        (json['secrets'] as List<dynamic>?)?.cast<String>() ?? const [],
    fantasticLocations:
        (json['fantasticLocations'] as List<dynamic>?)?.cast<String>() ??
        const [],
    npcs: (json['npcs'] as List<dynamic>?)?.cast<String>() ?? const [],
    monsters:
        (json['monsters'] as List<dynamic>?)?.cast<String>() ?? const [],
    treasures:
        (json['treasures'] as List<dynamic>?)?.cast<String>() ?? const [],
    recap: json['recap'] as String? ?? '',
  );

  Session copyWith({
    String? name,
    DateTime? date,
    SessionStatus? status,
    int? number,
    String? strongStart,
    List<String>? scenes,
    List<String>? secrets,
    List<String>? fantasticLocations,
    List<String>? npcs,
    List<String>? monsters,
    List<String>? treasures,
    String? recap,
  }) {
    return Session(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      date: date ?? this.date,
      status: status ?? this.status,
      number: number ?? this.number,
      strongStart: strongStart ?? this.strongStart,
      scenes: scenes ?? this.scenes,
      secrets: secrets ?? this.secrets,
      fantasticLocations: fantasticLocations ?? this.fantasticLocations,
      npcs: npcs ?? this.npcs,
      monsters: monsters ?? this.monsters,
      treasures: treasures ?? this.treasures,
      recap: recap ?? this.recap,
    );
  }
}
