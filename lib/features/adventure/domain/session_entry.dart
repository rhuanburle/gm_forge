import 'package:uuid/uuid.dart';

enum SessionEntryType {
  combat(displayName: 'Combate', icon: '⚔️'),
  discovery(displayName: 'Descoberta', icon: '💎'),
  narrative(displayName: 'Narrativa', icon: '📖'),
  note(displayName: 'Anotação', icon: '📝');

  final String displayName;
  final String icon;

  const SessionEntryType({required this.displayName, required this.icon});

  factory SessionEntryType.fromString(String value) {
    return SessionEntryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionEntryType.note,
    );
  }
}

class SessionEntry {
  final String id;
  final String adventureId;
  final String text;
  final SessionEntryType entryType;
  final DateTime timestamp;
  final String? turnLabel;
  final DateTime createdAt;

  const SessionEntry({
    required this.id,
    required this.adventureId,
    required this.text,
    required this.entryType,
    required this.timestamp,
    this.turnLabel,
    required this.createdAt,
  });

  factory SessionEntry.create({
    required String adventureId,
    required String text,
    required SessionEntryType entryType,
    String? turnLabel,
  }) {
    final now = DateTime.now();
    return SessionEntry(
      id: const Uuid().v4(),
      adventureId: adventureId,
      text: text,
      entryType: entryType,
      timestamp: now,
      turnLabel: turnLabel,
      createdAt: now,
    );
  }

  SessionEntry copyWith({
    String? id,
    String? adventureId,
    String? text,
    SessionEntryType? entryType,
    DateTime? timestamp,
    String? turnLabel,
    DateTime? createdAt,
  }) {
    return SessionEntry(
      id: id ?? this.id,
      adventureId: adventureId ?? this.adventureId,
      text: text ?? this.text,
      entryType: entryType ?? this.entryType,
      timestamp: timestamp ?? this.timestamp,
      turnLabel: turnLabel ?? this.turnLabel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adventureId': adventureId,
      'text': text,
      'entryType': entryType.name,
      'timestamp': timestamp.toIso8601String(),
      'turnLabel': turnLabel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SessionEntry.fromJson(Map<String, dynamic> json) {
    return SessionEntry(
      id: json['id'] as String,
      adventureId: json['adventureId'] as String,
      text: json['text'] as String,
      entryType: SessionEntryType.fromString(
        json['entryType'] as String? ?? '',
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      turnLabel: json['turnLabel'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
