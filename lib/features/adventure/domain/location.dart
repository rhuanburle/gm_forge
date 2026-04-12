import "package:uuid/uuid.dart";

enum LocationStatus { intact, damaged, destroyed, occupied, liberated, hidden }

extension LocationStatusExtension on LocationStatus {
  String get displayName {
    switch (this) {
      case LocationStatus.intact:
        return "Intacto";
      case LocationStatus.damaged:
        return "Danificado";
      case LocationStatus.destroyed:
        return "Destruído";
      case LocationStatus.occupied:
        return "Ocupado";
      case LocationStatus.liberated:
        return "Liberado";
      case LocationStatus.hidden:
        return "Oculto";
    }
  }

  String get icon {
    switch (this) {
      case LocationStatus.intact:
        return "🏛️";
      case LocationStatus.damaged:
        return "🔨";
      case LocationStatus.destroyed:
        return "💥";
      case LocationStatus.occupied:
        return "🚩";
      case LocationStatus.liberated:
        return "🕊️";
      case LocationStatus.hidden:
        return "🫥";
    }
  }
}

class Location {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String name;
  final String description;
  final String? imagePath;
  final String? parentLocationId;
  final List<String> creatureIds;
  final List<String> scenicEncounters;
  final LocationStatus status;
  final List<String> tags;
  final List<String> notes;

  const Location({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.name,
    this.description = "",
    this.imagePath,
    this.parentLocationId,
    this.creatureIds = const [],
    this.scenicEncounters = const [],
    this.status = LocationStatus.intact,
    this.tags = const [],
    this.notes = const [],
  });

  factory Location.create({
    required String campaignId,
    String? adventureId,
    required String name,
    String description = "",
    String? imagePath,
    String? parentLocationId,
    List<String> creatureIds = const [],
    List<String> scenicEncounters = const [],
    LocationStatus status = LocationStatus.intact,
    List<String> tags = const [],
    List<String> notes = const [],
  }) {
    return Location(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      name: name,
      description: description,
      imagePath: imagePath,
      parentLocationId: parentLocationId,
      creatureIds: creatureIds,
      scenicEncounters: scenicEncounters,
      status: status,
      tags: tags,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "campaignId": campaignId,
    "adventureId": adventureId,
    "name": name,
    "description": description,
    "imagePath": imagePath,
    "parentLocationId": parentLocationId,
    "creatureIds": creatureIds,
    "scenicEncounters": scenicEncounters,
    "status": status.index,
    "tags": tags,
    "notes": notes,
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json["id"] as String,
    campaignId: json["campaignId"] as String? ?? json["adventureId"] as String, // Fallback for migration
    adventureId: json["adventureId"] as String?,
    name: json["name"] as String,
    description: json["description"] as String? ?? "",
    imagePath: json["imagePath"] as String?,
    parentLocationId: json["parentLocationId"] as String?,
    creatureIds:
        (json["creatureIds"] as List<dynamic>?)?.cast<String>() ?? const [],
    scenicEncounters:
        (json["scenicEncounters"] as List<dynamic>?)?.cast<String>() ?? const [],
    status: LocationStatus.values[json["status"] as int? ?? 0],
    tags: (json["tags"] as List<dynamic>?)?.cast<String>() ?? const [],
    notes: (json["notes"] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  Location copyWith({
    String? campaignId,
    String? adventureId,
    bool clearAdventureId = false,
    String? name,
    String? description,
    String? imagePath,
    bool clearImagePath = false,
    String? parentLocationId,
    List<String>? creatureIds,
    bool clearParent = false,
    List<String>? scenicEncounters,
    LocationStatus? status,
    List<String>? tags,
    List<String>? notes,
  }) {
    return Location(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      parentLocationId: clearParent
          ? null
          : (parentLocationId ?? this.parentLocationId),
      creatureIds: creatureIds ?? this.creatureIds,
      scenicEncounters: scenicEncounters ?? this.scenicEncounters,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }
}
