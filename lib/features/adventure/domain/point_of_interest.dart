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
  final String id;
  final String adventureId;
  final int number;
  final String name;
  final RoomPurpose purpose;
  final String firstImpression;
  final String obvious;
  final String detail;
  final List<int> connections;
  final String treasure;
  final List<String> creatureIds;
  final String? imagePath;
  final String? locationId;
  final bool isVisited;

  const PointOfInterest({
    required this.id,
    required this.adventureId,
    required this.number,
    required this.name,
    this.purpose = RoomPurpose.narrative,
    required this.firstImpression,
    required this.obvious,
    required this.detail,
    this.connections = const [],
    this.treasure = '',
    this.creatureIds = const [],
    this.imagePath,
    this.locationId,
    this.isVisited = false,
  });

  factory PointOfInterest.create({
    required String adventureId,
    required int number,
    required String name,
    RoomPurpose purpose = RoomPurpose.narrative,
    required String firstImpression,
    required String obvious,
    required String detail,
    List<int> connections = const [],
    String treasure = '',
    List<String> creatureIds = const [],
    String? imagePath,
    String? locationId,
    bool isVisited = false,
  }) {
    return PointOfInterest(
      id: const Uuid().v4(),
      adventureId: adventureId,
      number: number,
      name: name,
      purpose: purpose,
      firstImpression: firstImpression,
      obvious: obvious,
      detail: detail,
      connections: connections,
      treasure: treasure,
      creatureIds: creatureIds,
      imagePath: imagePath,
      locationId: locationId,
      isVisited: isVisited,
    );
  }

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
    'isVisited': isVisited,
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
        isVisited: json['isVisited'] as bool? ?? false,
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
    bool? isVisited,
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
      isVisited: isVisited ?? this.isVisited,
    );
  }
}
