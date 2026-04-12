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

enum CreatureStatus { alive, dead, missing, captured }

extension CreatureStatusExtension on CreatureStatus {
  String get displayName {
    switch (this) {
      case CreatureStatus.alive:
        return "Vivo";
      case CreatureStatus.dead:
        return "Morto";
      case CreatureStatus.missing:
        return "Desaparecido";
      case CreatureStatus.captured:
        return "Capturado";
    }
  }

  String get icon {
    switch (this) {
      case CreatureStatus.alive:
        return "💚";
      case CreatureStatus.dead:
        return "💀";
      case CreatureStatus.missing:
        return "❓";
      case CreatureStatus.captured:
        return "⛓️";
    }
  }
}

enum CreatureDisposition { ally, neutral, hostile, unknown }

extension CreatureDispositionExtension on CreatureDisposition {
  String get displayName {
    switch (this) {
      case CreatureDisposition.ally:
        return "Aliado";
      case CreatureDisposition.neutral:
        return "Neutro";
      case CreatureDisposition.hostile:
        return "Hostil";
      case CreatureDisposition.unknown:
        return "Desconhecido";
    }
  }

  String get icon {
    switch (this) {
      case CreatureDisposition.ally:
        return "🤝";
      case CreatureDisposition.neutral:
        return "😐";
      case CreatureDisposition.hostile:
        return "⚔️";
      case CreatureDisposition.unknown:
        return "❔";
    }
  }
}

class Creature {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String name;
  final CreatureType type;
  final String description;
  final String motivation;
  final String losingBehavior;
  final List<String> locationIds;
  final String stats;
  final String? imagePath;
  final String roleplayNotes;
  final List<String> conversationTopics;
  final CreatureStatus status;
  final CreatureDisposition disposition;
  final String? currentLocationId;
  final List<String> tags;
  final List<String> notes;

  /// Legacy field — preserved from old data where location was free-text.
  /// Read-only: NOT written to toJson(). Used during migration only.
  final String? legacyLocation;

  const Creature({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.name,
    this.type = CreatureType.monster,
    required this.description,
    required this.motivation,
    required this.losingBehavior,
    this.locationIds = const [],
    this.stats = "",
    this.imagePath,
    this.roleplayNotes = '',
    this.conversationTopics = const [],
    this.status = CreatureStatus.alive,
    this.disposition = CreatureDisposition.unknown,
    this.currentLocationId,
    this.tags = const [],
    this.notes = const [],
    this.legacyLocation,
  });

  factory Creature.create({
    required String campaignId,
    String? adventureId,
    required String name,
    CreatureType type = CreatureType.monster,
    required String description,
    required String motivation,
    required String losingBehavior,
    List<String> locationIds = const [],
    String stats = "",
    String? imagePath,
    String roleplayNotes = '',
    List<String> conversationTopics = const [],
    CreatureStatus status = CreatureStatus.alive,
    CreatureDisposition disposition = CreatureDisposition.unknown,
    String? currentLocationId,
    List<String> tags = const [],
    List<String> notes = const [],
  }) {
    return Creature(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      name: name,
      type: type,
      description: description,
      motivation: motivation,
      losingBehavior: losingBehavior,
      locationIds: locationIds,
      stats: stats,
      imagePath: imagePath,
      roleplayNotes: roleplayNotes,
      conversationTopics: conversationTopics,
      status: status,
      disposition: disposition,
      currentLocationId: currentLocationId,
      tags: tags,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "campaignId": campaignId,
    "adventureId": adventureId,
    "name": name,
    "type": type.index,
    "description": description,
    "motivation": motivation,
    "losingBehavior": losingBehavior,
    "locationIds": locationIds,
    "stats": stats,
    "imagePath": imagePath,
    "roleplayNotes": roleplayNotes,
    "conversationTopics": conversationTopics,
    "status": status.index,
    "disposition": disposition.index,
    "currentLocationId": currentLocationId,
    "tags": tags,
    "notes": notes,
  };

  factory Creature.fromJson(Map<String, dynamic> json) => Creature(
    id: json["id"] as String,
    campaignId: json["campaignId"] as String? ?? json["adventureId"] as String, // Fallback for migration
    adventureId: json["adventureId"] as String?,
    name: json["name"] as String,
    type: CreatureType.values[json["type"] as int? ?? 0],
    description: json["description"] as String? ?? '',
    motivation: json["motivation"] as String? ?? '',
    losingBehavior: json["losingBehavior"] as String? ?? '',
    locationIds:
        (json["locationIds"] as List<dynamic>?)?.cast<String>() ?? const [],
    stats: json["stats"] as String? ?? "",
    imagePath: json["imagePath"] as String?,
    roleplayNotes: json["roleplayNotes"] as String? ?? '',
    conversationTopics:
        (json["conversationTopics"] as List<dynamic>?)?.cast<String>() ?? const [],
    status: CreatureStatus.values[json["status"] as int? ?? 0],
    disposition: CreatureDisposition.values[json["disposition"] as int? ?? 3],
    currentLocationId: json["currentLocationId"] as String?,
    tags: (json["tags"] as List<dynamic>?)?.cast<String>() ?? const [],
    notes: (json["notes"] as List<dynamic>?)?.cast<String>() ?? const [],
    // Preserve the old free-text "location" field for migration purposes
    legacyLocation: json["location"] as String?,
  );

  Creature copyWith({
    String? campaignId,
    String? adventureId,
    bool clearAdventureId = false,
    String? name,
    CreatureType? type,
    String? description,
    String? motivation,
    String? losingBehavior,
    List<String>? locationIds,
    String? stats,
    String? imagePath,
    bool clearImagePath = false,
    String? roleplayNotes,
    List<String>? conversationTopics,
    CreatureStatus? status,
    CreatureDisposition? disposition,
    String? currentLocationId,
    bool clearCurrentLocation = false,
    List<String>? tags,
    List<String>? notes,
  }) {
    return Creature(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      motivation: motivation ?? this.motivation,
      losingBehavior: losingBehavior ?? this.losingBehavior,
      locationIds: locationIds ?? this.locationIds,
      stats: stats ?? this.stats,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      roleplayNotes: roleplayNotes ?? this.roleplayNotes,
      conversationTopics: conversationTopics ?? this.conversationTopics,
      status: status ?? this.status,
      disposition: disposition ?? this.disposition,
      currentLocationId: clearCurrentLocation
          ? null
          : (currentLocationId ?? this.currentLocationId),
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }
}
