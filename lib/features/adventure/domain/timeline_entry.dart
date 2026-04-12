import 'package:uuid/uuid.dart';

enum TimelineEntryType { session, worldEvent, upcoming }

extension TimelineEntryTypeExtension on TimelineEntryType {
  String get displayName {
    switch (this) {
      case TimelineEntryType.session:
        return 'Sessão';
      case TimelineEntryType.worldEvent:
        return 'Evento';
      case TimelineEntryType.upcoming:
        return 'Futuro';
    }
  }
}

class TimelineEntry {
  final String id;
  final String campaignId;
  final int day;
  final String title;
  final String description;
  final TimelineEntryType type;
  final int? sessionNumber;
  final DateTime createdAt;

  const TimelineEntry({
    required this.id,
    required this.campaignId,
    required this.day,
    required this.title,
    this.description = '',
    this.type = TimelineEntryType.worldEvent,
    this.sessionNumber,
    required this.createdAt,
  });

  factory TimelineEntry.create({
    required String campaignId,
    required int day,
    required String title,
    String description = '',
    TimelineEntryType type = TimelineEntryType.worldEvent,
    int? sessionNumber,
  }) {
    return TimelineEntry(
      id: const Uuid().v4(),
      campaignId: campaignId,
      day: day,
      title: title,
      description: description,
      type: type,
      sessionNumber: sessionNumber,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'day': day,
    'title': title,
    'description': description,
    'type': type.index,
    'sessionNumber': sessionNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String,
    day: json['day'] as int,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    type: TimelineEntryType.values.elementAtOrNull(json['type'] as int? ?? 1) ??
        TimelineEntryType.worldEvent,
    sessionNumber: json['sessionNumber'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  TimelineEntry copyWith({
    int? day,
    String? title,
    String? description,
    TimelineEntryType? type,
    int? sessionNumber,
    bool clearSessionNumber = false,
  }) {
    return TimelineEntry(
      id: id,
      campaignId: campaignId,
      day: day ?? this.day,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      sessionNumber: clearSessionNumber ? null : (sessionNumber ?? this.sessionNumber),
      createdAt: createdAt,
    );
  }
}
