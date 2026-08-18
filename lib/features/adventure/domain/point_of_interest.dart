import 'package:uuid/uuid.dart';

/// Suggested purpose values for POIs. Free-text — any string accepted.
/// Old enum-indexed values map here (see _legacyPurposeFromIndex).
const kPurposeSuggestions = <String>[
  'descanso',
  'perigo',
  'enigma',
  'narrativa',
  'social',
  'investigação',
  'viagem',
];

const _legacyPurposes = <String>['descanso', 'perigo', 'enigma', 'narrativa'];

String _legacyPurposeFromIndex(int i) =>
    (i >= 0 && i < _legacyPurposes.length) ? _legacyPurposes[i] : 'narrativa';

class PointOfInterest {
  final String id;
  final String campaignId;
  final String? adventureId;
  final int number;
  final String name;

  /// Free-text purpose tag. See [kPurposeSuggestions]. AI or user may set
  /// any value to match the system being played.
  final String purpose;
  final String firstImpression;
  final String obvious;
  final String detail;
  final List<int> connections;
  final String treasure;
  final List<String> creatureIds;
  final String? imagePath;
  final String? locationId;
  final bool isVisited;

  /// Short bullets surfaced in the GM Shield when this POI is active.
  final List<String> gmReminders;

  /// Sidebar IDs to surface when this POI is active in play mode.
  final List<String> sidebarIds;

  const PointOfInterest({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.number,
    required this.name,
    this.purpose = 'narrativa',
    required this.firstImpression,
    required this.obvious,
    required this.detail,
    this.connections = const [],
    this.treasure = '',
    this.creatureIds = const [],
    this.imagePath,
    this.locationId,
    this.isVisited = false,
    this.gmReminders = const [],
    this.sidebarIds = const [],
  });

  factory PointOfInterest.create({
    required String campaignId,
    String? adventureId,
    required int number,
    required String name,
    String purpose = 'narrativa',
    required String firstImpression,
    required String obvious,
    required String detail,
    List<int> connections = const [],
    String treasure = '',
    List<String> creatureIds = const [],
    String? imagePath,
    String? locationId,
    bool isVisited = false,
    List<String> gmReminders = const [],
    List<String> sidebarIds = const [],
  }) {
    return PointOfInterest(
      id: const Uuid().v4(),
      campaignId: campaignId,
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
      gmReminders: gmReminders,
      sidebarIds: sidebarIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'adventureId': adventureId,
    'number': number,
    'name': name,
    'purpose': purpose,
    'firstImpression': firstImpression,
    'obvious': obvious,
    'detail': detail,
    'connections': connections,
    'treasure': treasure,
    'creatureIds': creatureIds,
    'imagePath': imagePath,
    'locationId': locationId,
    'isVisited': isVisited,
    'gmReminders': gmReminders,
    'sidebarIds': sidebarIds,
  };

  factory PointOfInterest.fromJson(Map<String, dynamic> json) =>
      PointOfInterest(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String? ?? json['adventureId'] as String,
        adventureId: json['adventureId'] as String?,
        number: json['number'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        purpose: switch (json['purpose']) {
          int i => _legacyPurposeFromIndex(i),
          String s when s.isNotEmpty => s,
          _ => 'narrativa',
        },
        firstImpression: json['firstImpression'] as String? ?? '',
        obvious: json['obvious'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        connections: (json['connections'] as List<dynamic>?)?.cast<int>() ?? [],
        treasure: json['treasure'] as String? ?? '',
        creatureIds:
            (json['creatureIds'] as List<dynamic>?)?.cast<String>() ?? [],
        imagePath: json['imagePath'] as String?,
        locationId: json['locationId'] as String?,
        isVisited: json['isVisited'] as bool? ?? false,
        gmReminders:
            (json['gmReminders'] as List<dynamic>?)?.cast<String>() ?? const [],
        sidebarIds:
            (json['sidebarIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  PointOfInterest copyWith({
    String? name,
    int? number,
    String? purpose,
    String? firstImpression,
    String? obvious,
    String? detail,
    List<int>? connections,
    String? treasure,
    List<String>? creatureIds,
    String? imagePath,
    bool clearImagePath = false,
    String? locationId,
    bool? isVisited,
    String? adventureId,
    bool clearAdventureId = false,
    List<String>? gmReminders,
    List<String>? sidebarIds,
  }) {
    return PointOfInterest(
      id: id,
      campaignId: campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      number: number ?? this.number,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      firstImpression: firstImpression ?? this.firstImpression,
      obvious: obvious ?? this.obvious,
      detail: detail ?? this.detail,
      connections: connections ?? this.connections,
      treasure: treasure ?? this.treasure,
      creatureIds: creatureIds ?? this.creatureIds,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      locationId: locationId ?? this.locationId,
      isVisited: isVisited ?? this.isVisited,
      gmReminders: gmReminders ?? this.gmReminders,
      sidebarIds: sidebarIds ?? this.sidebarIds,
    );
  }
}
