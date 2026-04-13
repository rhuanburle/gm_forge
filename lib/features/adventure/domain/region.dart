import 'package:uuid/uuid.dart';

class Subhex {
  final String name;
  final String description;
  final bool isExplored;

  const Subhex({
    required this.name,
    this.description = '',
    this.isExplored = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'isExplored': isExplored,
  };

  factory Subhex.fromJson(Map<String, dynamic> json) => Subhex(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    isExplored: json['isExplored'] as bool? ?? false,
  );

  Subhex copyWith({String? name, String? description, bool? isExplored}) {
    return Subhex(
      name: name ?? this.name,
      description: description ?? this.description,
      isExplored: isExplored ?? this.isExplored,
    );
  }
}

class Region {
  final String id;
  final String campaignId;
  final String name;
  final String hexCode;
  final String terrain;
  final int dangerLevel;
  final List<String> locationIds;
  final String encounterTable;
  final List<Subhex> subhexes;

  const Region({
    required this.id,
    required this.campaignId,
    required this.name,
    this.hexCode = '',
    this.terrain = '',
    this.dangerLevel = 1,
    this.locationIds = const [],
    this.encounterTable = '',
    this.subhexes = const [],
  });

  factory Region.create({
    required String campaignId,
    required String name,
    String hexCode = '',
    String terrain = '',
    int dangerLevel = 1,
    List<String> locationIds = const [],
    String encounterTable = '',
    List<Subhex> subhexes = const [],
  }) {
    return Region(
      id: const Uuid().v4(),
      campaignId: campaignId,
      name: name,
      hexCode: hexCode,
      terrain: terrain,
      dangerLevel: dangerLevel,
      locationIds: locationIds,
      encounterTable: encounterTable,
      subhexes: subhexes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'name': name,
    'hexCode': hexCode,
    'terrain': terrain,
    'dangerLevel': dangerLevel,
    'locationIds': locationIds,
    'encounterTable': encounterTable,
    'subhexes': subhexes.map((s) => s.toJson()).toList(),
  };

  factory Region.fromJson(Map<String, dynamic> json) => Region(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String,
    name: json['name'] as String,
    hexCode: json['hexCode'] as String? ?? '',
    terrain: json['terrain'] as String? ?? '',
    dangerLevel: json['dangerLevel'] as int? ?? 1,
    locationIds:
        (json['locationIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    encounterTable: json['encounterTable'] as String? ?? '',
    subhexes: (json['subhexes'] as List<dynamic>?)
            ?.map((s) => Subhex.fromJson((s as Map).cast<String, dynamic>()))
            .toList() ??
        const [],
  );

  Region copyWith({
    String? name,
    String? hexCode,
    String? terrain,
    int? dangerLevel,
    List<String>? locationIds,
    String? encounterTable,
    List<Subhex>? subhexes,
  }) {
    return Region(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      hexCode: hexCode ?? this.hexCode,
      terrain: terrain ?? this.terrain,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      locationIds: locationIds ?? this.locationIds,
      encounterTable: encounterTable ?? this.encounterTable,
      subhexes: subhexes ?? this.subhexes,
    );
  }
}
