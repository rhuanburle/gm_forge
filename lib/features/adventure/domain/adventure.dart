import 'package:uuid/uuid.dart';

class Adventure {
  final String id;
  final String name;
  final String description;

  final String conceptWhat;
  final String conceptConflict;
  final List<String> conceptSecondaryConflicts;

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isComplete;

  final List<String> tags;
  final String? campaignId;
  final String? nextAdventureHint;
  final String? dungeonMapPath;
  final String? sessionNotes;

  const Adventure({
    required this.id,
    required this.name,
    required this.description,
    required this.conceptWhat,
    required this.conceptConflict,
    this.conceptSecondaryConflicts = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isComplete = false,
    this.tags = const [],
    this.campaignId,
    this.nextAdventureHint,
    this.dungeonMapPath,
    this.sessionNotes,
  });

  factory Adventure.create({
    required String name,
    required String description,
    required String conceptWhat,
    required String conceptConflict,
    List<String> conceptSecondaryConflicts = const [],
    String? campaignId,
    String? nextAdventureHint,
    String? dungeonMapPath,
    String? sessionNotes,
  }) {
    return Adventure(
      id: const Uuid().v4(),
      name: name,
      description: description,
      conceptWhat: conceptWhat,
      conceptConflict: conceptConflict,
      conceptSecondaryConflicts: conceptSecondaryConflicts,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      campaignId: campaignId,
      nextAdventureHint: nextAdventureHint,
      dungeonMapPath: dungeonMapPath,
      sessionNotes: sessionNotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'conceptWhat': conceptWhat,
    'conceptConflict': conceptConflict,
    'conceptSecondaryConflicts': conceptSecondaryConflicts,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isComplete': isComplete,
    'tags': tags,
    'campaignId': campaignId,
    'nextAdventureHint': nextAdventureHint,
    'dungeonMapPath': dungeonMapPath,
    'sessionNotes': sessionNotes,
  };

  factory Adventure.fromJson(Map<String, dynamic> json) => Adventure(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    conceptWhat: json['conceptWhat'] as String,
    conceptConflict: json['conceptConflict'] as String,
    conceptSecondaryConflicts:
        (json['conceptSecondaryConflicts'] as List<dynamic>?)?.cast<String>() ??
        [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isComplete: json['isComplete'] as bool? ?? false,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    campaignId: json['campaignId'] as String?,
    nextAdventureHint: json['nextAdventureHint'] as String?,
    dungeonMapPath: json['dungeonMapPath'] as String?,
    sessionNotes: json['sessionNotes'] as String?,
  );

  Adventure copyWith({
    String? name,
    String? description,
    String? conceptWhat,
    String? conceptConflict,
    List<String>? conceptSecondaryConflicts,
    bool? isComplete,
    List<String>? tags,
    String? campaignId,
    bool clearCampaignId = false,
    String? nextAdventureHint,
    String? dungeonMapPath,
    String? sessionNotes,
    DateTime? updatedAt,
  }) => Adventure(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    conceptWhat: conceptWhat ?? this.conceptWhat,
    conceptConflict: conceptConflict ?? this.conceptConflict,
    conceptSecondaryConflicts:
        conceptSecondaryConflicts ?? this.conceptSecondaryConflicts,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isComplete: isComplete ?? this.isComplete,
    tags: tags ?? this.tags,
    campaignId: clearCampaignId ? null : (campaignId ?? this.campaignId),
    nextAdventureHint: nextAdventureHint ?? this.nextAdventureHint,
    dungeonMapPath: dungeonMapPath ?? this.dungeonMapPath,
    sessionNotes: sessionNotes ?? this.sessionNotes,
  );
}
