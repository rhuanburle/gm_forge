import "package:uuid/uuid.dart";

enum CreatureType { monster, npc }

extension CreatureTypeExtension on CreatureType {
  String get displayName {
    switch (this) {
      case CreatureType.monster:
        return "Monstro";
      case CreatureType.npc:
        return "NPC";
    }
  }
}

class Creature {
  final String id;
  final String adventureId;
  final String name;
  final CreatureType type;
  final String description;
  final String motivation;
  final String losingBehavior;
  final List<String> locationIds;
  final String stats;
  final String? imagePath;

  /// Legacy field — preserved from old data where location was free-text.
  /// Read-only: NOT written to toJson(). Used during migration only.
  final String? legacyLocation;

  const Creature({
    required this.id,
    required this.adventureId,
    required this.name,
    this.type = CreatureType.monster,
    required this.description,
    required this.motivation,
    required this.losingBehavior,
    this.locationIds = const [],
    this.stats = "",
    this.imagePath,
    this.legacyLocation,
  });

  factory Creature.create({
    required String adventureId,
    required String name,
    CreatureType type = CreatureType.monster,
    required String description,
    required String motivation,
    required String losingBehavior,
    List<String> locationIds = const [],
    String stats = "",
    String? imagePath,
  }) {
    return Creature(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: name,
      type: type,
      description: description,
      motivation: motivation,
      losingBehavior: losingBehavior,
      locationIds: locationIds,
      stats: stats,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "adventureId": adventureId,
    "name": name,
    "type": type.index,
    "description": description,
    "motivation": motivation,
    "losingBehavior": losingBehavior,
    "locationIds": locationIds,
    "stats": stats,
    "imagePath": imagePath,
  };

  factory Creature.fromJson(Map<String, dynamic> json) => Creature(
    id: json["id"] as String,
    adventureId: json["adventureId"] as String,
    name: json["name"] as String,
    type: CreatureType.values[json["type"] as int? ?? 0],
    description: json["description"] as String,
    motivation: json["motivation"] as String,
    losingBehavior: json["losingBehavior"] as String,
    locationIds:
        (json["locationIds"] as List<dynamic>?)?.cast<String>() ?? const [],
    stats: json["stats"] as String? ?? "",
    imagePath: json["imagePath"] as String?,
    // Preserve the old free-text "location" field for migration purposes
    legacyLocation: json["location"] as String?,
  );

  Creature copyWith({
    String? name,
    CreatureType? type,
    String? description,
    String? motivation,
    String? losingBehavior,
    List<String>? locationIds,
    String? stats,
    String? imagePath,
  }) {
    return Creature(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      motivation: motivation ?? this.motivation,
      losingBehavior: losingBehavior ?? this.losingBehavior,
      locationIds: locationIds ?? this.locationIds,
      stats: stats ?? this.stats,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
