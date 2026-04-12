import 'package:uuid/uuid.dart';

class PlayerCharacter {
  final String id;
  final String campaignId;
  final String name;
  final String playerName;
  final String species;
  final String characterClass;
  final String origin;
  final String backstory;
  final String criticalData;
  final String notes;
  final String? imageUrl;
  final int level;
  // Campos exclusivos do mestre
  final String gmNotes;
  final String personalArc;
  final String backstoryHooks;

  const PlayerCharacter({
    required this.id,
    required this.campaignId,
    required this.name,
    this.playerName = '',
    this.species = '',
    this.characterClass = '',
    this.origin = '',
    this.backstory = '',
    this.criticalData = '',
    this.notes = '',
    this.imageUrl,
    this.level = 1,
    this.gmNotes = '',
    this.personalArc = '',
    this.backstoryHooks = '',
  });

  factory PlayerCharacter.create({
    required String campaignId,
    required String name,
    String playerName = '',
    String species = '',
    String characterClass = '',
    String origin = '',
    String backstory = '',
    String criticalData = '',
    String notes = '',
    String? imageUrl,
    int level = 1,
    String gmNotes = '',
    String personalArc = '',
    String backstoryHooks = '',
  }) {
    return PlayerCharacter(
      id: const Uuid().v4(),
      campaignId: campaignId,
      name: name,
      playerName: playerName,
      species: species,
      characterClass: characterClass,
      origin: origin,
      backstory: backstory,
      criticalData: criticalData,
      notes: notes,
      imageUrl: imageUrl,
      level: level,
      gmNotes: gmNotes,
      personalArc: personalArc,
      backstoryHooks: backstoryHooks,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'name': name,
    'playerName': playerName,
    'species': species,
    'characterClass': characterClass,
    'origin': origin,
    'backstory': backstory,
    'criticalData': criticalData,
    'notes': notes,
    'imageUrl': imageUrl,
    'level': level,
    'gmNotes': gmNotes,
    'personalArc': personalArc,
    'backstoryHooks': backstoryHooks,
  };

  factory PlayerCharacter.fromJson(Map<String, dynamic> json) =>
      PlayerCharacter(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String,
        name: json['name'] as String,
        playerName: json['playerName'] as String? ?? '',
        species: json['species'] as String? ?? '',
        characterClass: json['characterClass'] as String? ?? '',
        origin: json['origin'] as String? ?? '',
        backstory: json['backstory'] as String? ?? '',
        criticalData: json['criticalData'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        level: json['level'] as int? ?? 1,
        gmNotes: json['gmNotes'] as String? ?? '',
        personalArc: json['personalArc'] as String? ?? '',
        backstoryHooks: json['backstoryHooks'] as String? ?? '',
      );

  PlayerCharacter copyWith({
    String? name,
    String? playerName,
    String? species,
    String? characterClass,
    String? origin,
    String? backstory,
    String? criticalData,
    String? notes,
    String? imageUrl,
    bool clearImageUrl = false,
    int? level,
    String? gmNotes,
    String? personalArc,
    String? backstoryHooks,
  }) {
    return PlayerCharacter(
      id: id,
      campaignId: campaignId,
      name: name ?? this.name,
      playerName: playerName ?? this.playerName,
      species: species ?? this.species,
      characterClass: characterClass ?? this.characterClass,
      origin: origin ?? this.origin,
      backstory: backstory ?? this.backstory,
      criticalData: criticalData ?? this.criticalData,
      notes: notes ?? this.notes,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      level: level ?? this.level,
      gmNotes: gmNotes ?? this.gmNotes,
      personalArc: personalArc ?? this.personalArc,
      backstoryHooks: backstoryHooks ?? this.backstoryHooks,
    );
  }
}
