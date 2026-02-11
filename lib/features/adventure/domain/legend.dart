import 'package:uuid/uuid.dart';

/// Legend/Rumor that players hear about an adventure site
///
/// The 2d6 rumor table should have:
/// - ~70% true rumors (real hints about dangers/treasures)
/// - ~30% false rumors (for tension and surprise)
class Legend {
  String id;
  String adventureId;

  /// The rumor text players will hear
  String text;

  /// Whether this rumor is true or false/exaggerated
  bool isTrue;

  /// Source of the rumor (tavern keeper, old map, etc.)
  String? source;

  /// Dice roll that triggers this rumor (e.g., "2", "7", "12")
  String diceResult;

  /// Optional link to a specific Creature/NPC ID
  String? relatedCreatureId;

  /// Optional link to a specific PointOfInterest ID (Location)
  String? relatedLocationId;

  Legend({
    String? id,
    required this.adventureId,
    required this.text,
    required this.isTrue,
    this.source,
    required this.diceResult,
    this.relatedCreatureId,
    this.relatedLocationId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'text': text,
    'isTrue': isTrue,
    'source': source,
    'diceResult': diceResult,
    'relatedCreatureId': relatedCreatureId,
    'relatedLocationId': relatedLocationId,
  };

  factory Legend.fromJson(Map<String, dynamic> json) => Legend(
    id: json['id'] as String,
    adventureId: json['adventureId'] as String,
    text: json['text'] as String,
    isTrue: json['isTrue'] as bool,
    source: json['source'] as String?,
    diceResult: json['diceResult'] as String,
    relatedCreatureId: json['relatedCreatureId'] as String?,
    relatedLocationId: json['relatedLocationId'] as String?,
  );

  Legend copyWith({
    String? text,
    bool? isTrue,
    String? source,
    String? diceResult,
    String? relatedCreatureId,
    String? relatedLocationId,
  }) {
    return Legend(
      id: id,
      adventureId: adventureId,
      text: text ?? this.text,
      isTrue: isTrue ?? this.isTrue,
      source: source ?? this.source,
      diceResult: diceResult ?? this.diceResult,
      relatedCreatureId: relatedCreatureId ?? this.relatedCreatureId,
      relatedLocationId: relatedLocationId ?? this.relatedLocationId,
    );
  }
}
