import 'package:uuid/uuid.dart';

/// Purpose types for Points of Interest
enum RoomPurpose {
  rest, // Safe area for players to recuperate
  danger, // Combat or hazard
  puzzle, // Mental challenge
  narrative, // Story/lore discovery
}

extension RoomPurposeExtension on RoomPurpose {
  String get displayName {
    switch (this) {
      case RoomPurpose.rest:
        return 'DESCANSO';
      case RoomPurpose.danger:
        return 'PERIGO';
      case RoomPurpose.puzzle:
        return 'ENIGMA';
      case RoomPurpose.narrative:
        return 'NARRATIVA';
    }
  }
}

/// A Point of Interest (room/location) on the adventure map
///
/// Each room follows the description pattern:
/// 1. First Impression (senses) - what they feel/hear/smell immediately
/// 2. The Obvious - what's impossible to miss
/// 3. The Detail - what's discovered on investigation
class PointOfInterest {
  String id;
  String adventureId;

  /// Room number on the map
  int number;

  String name;

  /// Room purpose (rest, danger, puzzle, narrative)
  RoomPurpose purpose;

  /// What players sense immediately (smell, sound, temperature)
  String firstImpression;

  /// What's impossible not to see
  String obvious;

  /// What's discovered on investigation (treasures, traps)
  String detail;

  /// Connected room numbers (for non-linear navigation)
  List<int> connections;

  /// Loot or rewards found in the room
  String treasure;

  /// IDs of Creatures/NPCs in this location
  List<String> creatureIds;

  /// Image path for the location (URL or local path)
  String? imagePath;

  /// The Zone/Area this POI belongs to (optional)
  String? locationId;

  PointOfInterest({
    String? id,
    required this.adventureId,
    required this.number,
    required this.name,
    this.purpose = RoomPurpose.narrative,
    required this.firstImpression,
    required this.obvious,
    required this.detail,
    List<int>? connections,
    this.treasure = '',
    List<String>? creatureIds,
    this.imagePath,
    this.locationId,
  }) : id = id ?? const Uuid().v4(),
       connections = connections ?? [],
       creatureIds = creatureIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'number': number,
    'name': name,
    'purpose': purpose.index,
    'firstImpression': firstImpression,
    'obvious': obvious,
    'detail': detail,
    'connections': connections,
    'treasure': treasure,
    'creatureIds': creatureIds,
    'imagePath': imagePath,
    'locationId': locationId,
  };

  factory PointOfInterest.fromJson(Map<String, dynamic> json) =>
      PointOfInterest(
        id: json['id'] as String,
        adventureId: json['adventureId'] as String,
        number: json['number'] as int,
        name: json['name'] as String,
        purpose: RoomPurpose.values[json['purpose'] as int],
        firstImpression: json['firstImpression'] as String,
        obvious: json['obvious'] as String,
        detail: json['detail'] as String,
        connections: (json['connections'] as List<dynamic>?)?.cast<int>() ?? [],
        treasure: json['treasure'] as String? ?? '',
        creatureIds:
            (json['creatureIds'] as List<dynamic>?)?.cast<String>() ?? [],
        imagePath: json['imagePath'] as String?,
        locationId: json['locationId'] as String?,
      );

  PointOfInterest copyWith({
    String? name,
    int? number,
    RoomPurpose? purpose,
    String? firstImpression,
    String? obvious,
    String? detail,
    List<int>? connections,
    String? treasure,
    List<String>? creatureIds,
    String? imagePath,
    String? locationId,
  }) {
    return PointOfInterest(
      id: id,
      adventureId: adventureId,
      number: number ?? this.number,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      firstImpression: firstImpression ?? this.firstImpression,
      obvious: obvious ?? this.obvious,
      detail: detail ?? this.detail,
      connections: connections ?? this.connections,
      treasure: treasure ?? this.treasure,
      creatureIds: creatureIds ?? this.creatureIds,
      imagePath: imagePath ?? this.imagePath,
      locationId: locationId ?? this.locationId,
    );
  }
}
