import 'package:uuid/uuid.dart';

class Legend {
  String id;
  String adventureId;
  String text;
  bool isTrue;
  String? source;
  String diceResult;
  String? relatedCreatureId;
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
