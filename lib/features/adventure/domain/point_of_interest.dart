import 'package:uuid/uuid.dart';

enum RoomPurpose { rest, danger, puzzle, narrative }

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

class PointOfInterest {
  String id;
  String adventureId;
  int number;
  String name;
  RoomPurpose purpose;
  String firstImpression;
  String obvious;
  String detail;
  List<int> connections;
  String treasure;
  List<String> creatureIds;
  String? imagePath;
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
