import 'package:uuid/uuid.dart';

class Legend {
  final String id;
  final String adventureId;
  final String text;
  final bool isTrue;
  final String? source;
  final String diceResult;
  final String? relatedCreatureId;
  final String? relatedLocationId;

  const Legend({
    required this.id,
    required this.adventureId,
    required this.text,
    required this.isTrue,
    this.source,
    required this.diceResult,
    this.relatedCreatureId,
    this.relatedLocationId,
  });

  factory Legend.create({
    required String adventureId,
    required String text,
    required bool isTrue,
    String? source,
    required String diceResult,
    String? relatedCreatureId,
    String? relatedLocationId,
  }) {
    return Legend(
      id: const Uuid().v4(),
      adventureId: adventureId,
      text: text,
      isTrue: isTrue,
      source: source,
      diceResult: diceResult,
      relatedCreatureId: relatedCreatureId,
      relatedLocationId: relatedLocationId,
    );
  }

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
