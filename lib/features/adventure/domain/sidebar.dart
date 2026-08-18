import 'package:uuid/uuid.dart';

/// Contextual reference card attached to an Adventure or POI.
///
/// Covers "caixas laterais" of any system: lore (O Kantele), house rules
/// (A Água na Mina), historical context (Arensburgo no séc XIX), and
/// player-facing handouts (carta, poema). The `kind` field is free-text
/// so each system can use its own vocabulary.
///
/// When `playerFacing` is true, the UI shows a "Mostrar aos Jogadores"
/// fullscreen button so the GM can hand it to the table.
class Sidebar {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String? attachedPoiId;
  final String? attachedCreatureId;
  final String title;
  final String body;
  final String kind;
  final bool playerFacing;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Sidebar({
    required this.id,
    required this.campaignId,
    this.adventureId,
    this.attachedPoiId,
    this.attachedCreatureId,
    required this.title,
    this.body = '',
    this.kind = 'lore',
    this.playerFacing = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sidebar.create({
    required String campaignId,
    String? adventureId,
    String? attachedPoiId,
    String? attachedCreatureId,
    required String title,
    String body = '',
    String kind = 'lore',
    bool playerFacing = false,
  }) {
    final now = DateTime.now();
    return Sidebar(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      attachedPoiId: attachedPoiId,
      attachedCreatureId: attachedCreatureId,
      title: title,
      body: body,
      kind: kind,
      playerFacing: playerFacing,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'adventureId': adventureId,
    'attachedPoiId': attachedPoiId,
    'attachedCreatureId': attachedCreatureId,
    'title': title,
    'body': body,
    'kind': kind,
    'playerFacing': playerFacing,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
    id: json['id'] as String,
    campaignId:
        json['campaignId'] as String? ?? json['adventureId'] as String? ?? '',
    adventureId: json['adventureId'] as String?,
    attachedPoiId: json['attachedPoiId'] as String?,
    attachedCreatureId: json['attachedCreatureId'] as String?,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    kind: json['kind'] as String? ?? 'lore',
    playerFacing: json['playerFacing'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
        : DateTime.now(),
  );

  Sidebar copyWith({
    String? title,
    String? body,
    String? kind,
    bool? playerFacing,
    String? attachedPoiId,
    bool clearAttachedPoiId = false,
    String? attachedCreatureId,
    bool clearAttachedCreatureId = false,
    String? adventureId,
    bool clearAdventureId = false,
    DateTime? updatedAt,
  }) {
    return Sidebar(
      id: id,
      campaignId: campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      attachedPoiId:
          clearAttachedPoiId ? null : (attachedPoiId ?? this.attachedPoiId),
      attachedCreatureId: clearAttachedCreatureId
          ? null
          : (attachedCreatureId ?? this.attachedCreatureId),
      title: title ?? this.title,
      body: body ?? this.body,
      kind: kind ?? this.kind,
      playerFacing: playerFacing ?? this.playerFacing,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Suggested kinds for the picker — accepts any string.
const kSidebarKinds = <String>[
  'lore',
  'house_rule',
  'handout',
  'read_aloud',
  'historical',
  'system_ref',
];
