import 'package:uuid/uuid.dart';

/// Creature or NPC with motivations and behaviors
///
/// Unlike typical stat blocks, creatures in Adventure Sites have:
/// - Clear motivations (what they want)
/// - Reactive behaviors (what they do when losing)
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
  String id;
  String adventureId;
  String name;
  CreatureType type;
  String description;

  /// What the creature wants (food, gold, to be left alone, etc.)
  String motivation;

  /// What they do if losing (flee, negotiate, call reinforcements)
  String losingBehavior;

  /// Where they are located (room number or area)
  String? location;

  /// Combat stats or game mechanics (system agnostic)
  String stats;

  /// Image path for the creature (URL or local path)
  String? imagePath;

  Creature({
    String? id,
    required this.adventureId,
    required this.name,
    this.type = CreatureType.monster,
    required this.description,
    required this.motivation,
    required this.losingBehavior,
    this.location,
    this.stats = '',
    this.imagePath,
  }) : id = id ?? const Uuid().v4();

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
