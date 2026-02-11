import 'package:uuid/uuid.dart';

/// Main Adventure entity - the "Adventure Site"
///
/// An adventure is not a linear sequence of scenes, but a
/// static ecosystem that comes alive through player interaction.
class Adventure {
  String id;
  String name;
  String description;

  // === The Seed (Central Concept) ===

  /// What is the location? (e.g., submerged temple, abandoned space station)
  String conceptWhat;

  /// What's happening there now? (e.g., two factions fighting for an artifact)
  String conceptConflict;

  // === Metadata ===

  DateTime createdAt;
  DateTime updatedAt;

  /// Is this adventure complete/ready to run?
  bool isComplete;

  // === Campaign Links ===

  /// Tags for organization
  List<String> tags;

  /// The campaign this adventure belongs to (optional)
  String? campaignId;

  /// Narrative hook leading to the next adventure (The "Ponta Solta")
  String? nextAdventureHint;

  /// Path to the dungeon/map image representing all locations
  String? dungeonMapPath;

  Adventure({
    String? id,
    required this.name,
    required this.description,
    required this.conceptWhat,
    required this.conceptConflict,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isComplete = false,
    List<String>? tags,
    this.campaignId,
    this.nextAdventureHint,
    this.dungeonMapPath,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       tags = tags ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'conceptWhat': conceptWhat,
    'conceptConflict': conceptConflict,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isComplete': isComplete,
    'tags': tags,
    'campaignId': campaignId,
    'nextAdventureHint': nextAdventureHint,
    'dungeonMapPath': dungeonMapPath,
  };

  factory Adventure.fromJson(Map<String, dynamic> json) => Adventure(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    conceptWhat: json['conceptWhat'] as String,
    conceptConflict: json['conceptConflict'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isComplete: json['isComplete'] as bool? ?? false,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    campaignId: json['campaignId'] as String?,
    nextAdventureHint: json['nextAdventureHint'] as String?,
    dungeonMapPath: json['dungeonMapPath'] as String?,
  );

  Adventure copyWith({
    String? name,
    String? description,
    String? conceptWhat,
    String? conceptConflict,
    bool? isComplete,
    List<String>? tags,
    String? campaignId,
    String? nextAdventureHint,
    String? dungeonMapPath,
  }) => Adventure(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    conceptWhat: conceptWhat ?? this.conceptWhat,
    conceptConflict: conceptConflict ?? this.conceptConflict,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isComplete: isComplete ?? this.isComplete,
    tags: tags ?? this.tags,
    campaignId: campaignId ?? this.campaignId,
    nextAdventureHint: nextAdventureHint ?? this.nextAdventureHint,
    dungeonMapPath: dungeonMapPath ?? this.dungeonMapPath,
  );
}
