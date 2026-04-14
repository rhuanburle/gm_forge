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
  final String recap;
  final List<String> stars;
  final List<String> wishes;

  const Session({
    required this.id,
    required this.adventureId,
    required this.name,
    required this.date,
    this.status = SessionStatus.prep,
    this.number = 1,
    this.strongStart = '',
    this.recap = '',
    this.stars = const [],
    this.wishes = const [],
  });

  factory Session.create({
    required String adventureId,
    required String name,
    DateTime? date,
    SessionStatus status = SessionStatus.prep,
    int number = 1,
    String strongStart = '',
    String recap = '',
    List<String> stars = const [],
    List<String> wishes = const [],
  }) {
    return Session(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: name,
      date: date ?? DateTime.now(),
      status: status,
      number: number,
      strongStart: strongStart,
      recap: recap,
      stars: stars,
      wishes: wishes,
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
    'recap': recap,
    'stars': stars,
    'wishes': wishes,
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
    recap: json['recap'] as String? ?? '',
    stars: (json['stars'] as List<dynamic>?)?.cast<String>() ?? const [],
    wishes: (json['wishes'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  Session copyWith({
    String? name,
    DateTime? date,
    SessionStatus? status,
    int? number,
    String? strongStart,
    String? recap,
    List<String>? stars,
    List<String>? wishes,
  }) {
    return Session(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      date: date ?? this.date,
      status: status ?? this.status,
      number: number ?? this.number,
      strongStart: strongStart ?? this.strongStart,
      recap: recap ?? this.recap,
      stars: stars ?? this.stars,
      wishes: wishes ?? this.wishes,
    );
  }
}
