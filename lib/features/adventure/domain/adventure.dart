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
  final Map<String, String> locationNotes;

  /// Short bullet reminders surfaced in the GM Shield play mode.
  /// Not exported in player-facing handouts.
  final List<String> gmReminders;

  /// Free-text tag for RPG system ("Vaesen", "Dragonbane", "OSR", "custom").
  /// Read by the AI prompts to style output.
  final String? system;

  /// Free-form list of named outcomes ("Final 1: A Estrela Cai",
  /// "Catástrofe: Cornelius queima a vila", etc).
  final List<String> endings;

  const Adventure({
    required this.id,
    required this.name,
    required this.description,
    this.conceptWhat = '',
    this.conceptConflict = '',
    this.conceptSecondaryConflicts = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isComplete = false,
    this.tags = const [],
    this.campaignId,
    this.nextAdventureHint,
    this.dungeonMapPath,
    this.sessionNotes,
    this.locationNotes = const {},
    this.gmReminders = const [],
    this.system,
    this.endings = const [],
  });

  factory Adventure.create({
    required String name,
    required String description,
    String conceptWhat = '',
    String conceptConflict = '',
    List<String> conceptSecondaryConflicts = const [],
    String? campaignId,
    String? nextAdventureHint,
    String? dungeonMapPath,
    String? sessionNotes,
    Map<String, String> locationNotes = const {},
    List<String> gmReminders = const [],
    String? system,
    List<String> endings = const [],
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
      locationNotes: locationNotes,
      gmReminders: gmReminders,
      system: system,
      endings: endings,
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
    'locationNotes': locationNotes,
    'gmReminders': gmReminders,
    'system': system,
    'endings': endings,
  };

  factory Adventure.fromJson(Map<String, dynamic> json) => Adventure(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    conceptWhat: json['conceptWhat'] as String? ?? '',
    conceptConflict: json['conceptConflict'] as String? ?? '',
    conceptSecondaryConflicts:
        (json['conceptSecondaryConflicts'] as List<dynamic>?)?.cast<String>() ??
        const [],
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
        : DateTime.now(),
    isComplete: json['isComplete'] as bool? ?? false,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    campaignId: json['campaignId'] as String?,
    nextAdventureHint: json['nextAdventureHint'] as String?,
    dungeonMapPath: json['dungeonMapPath'] as String?,
    sessionNotes: json['sessionNotes'] as String?,
    locationNotes: (json['locationNotes'] as Map<dynamic, dynamic>?)?.cast<String, String>() ?? const {},
    gmReminders:
        (json['gmReminders'] as List<dynamic>?)?.cast<String>() ?? const [],
    system: json['system'] as String?,
    endings: (json['endings'] as List<dynamic>?)?.cast<String>() ?? const [],
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
    bool clearDungeonMapPath = false,
    String? sessionNotes,
    Map<String, String>? locationNotes,
    List<String>? gmReminders,
    String? system,
    bool clearSystem = false,
    List<String>? endings,
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
    dungeonMapPath: clearDungeonMapPath ? null : (dungeonMapPath ?? this.dungeonMapPath),
    sessionNotes: sessionNotes ?? this.sessionNotes,
    locationNotes: locationNotes ?? this.locationNotes,
    gmReminders: gmReminders ?? this.gmReminders,
    system: clearSystem ? null : (system ?? this.system),
    endings: endings ?? this.endings,
  );
}
