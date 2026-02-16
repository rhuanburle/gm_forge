import 'package:uuid/uuid.dart';

enum CreatureType { monster, npc }

extension CreatureTypeExtension on CreatureType {
  String get displayName {
    switch (this) {
      case CreatureType.monster:
        return 'Monstro';
      case CreatureType.npc:
        return 'NPC';
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
  final String? location;
  final String stats;
  final String? imagePath;

  const Creature({
    required this.id,
    required this.adventureId,
    required this.name,
    this.type = CreatureType.monster,
    required this.description,
    required this.motivation,
    required this.losingBehavior,
    this.location,
    this.stats = '',
    this.imagePath,
  });

  factory Creature.create({
    required String adventureId,
    required String name,
    CreatureType type = CreatureType.monster,
    required String description,
    required String motivation,
    required String losingBehavior,
    String? location,
    String stats = '',
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
      location: location,
      stats: stats,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'name': name,
    'type': type.index,
    'description': description,
    'motivation': motivation,
    'losingBehavior': losingBehavior,
    'location': location,
    'stats': stats,
    'imagePath': imagePath,
  };

  factory Creature.fromJson(Map<String, dynamic> json) => Creature(
    id: json['id'] as String,
    adventureId: json['adventureId'] as String,
    name: json['name'] as String,
    type: CreatureType.values[json['type'] as int? ?? 0],
    description: json['description'] as String,
    motivation: json['motivation'] as String,
    losingBehavior: json['losingBehavior'] as String,
    location: json['location'] as String?,
    stats: json['stats'] as String? ?? '',
    imagePath: json['imagePath'] as String?,
  );

  Creature copyWith({
    String? name,
    CreatureType? type,
    String? description,
    String? motivation,
    String? losingBehavior,
    String? location,
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
      location: location ?? this.location,
      stats: stats ?? this.stats,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
