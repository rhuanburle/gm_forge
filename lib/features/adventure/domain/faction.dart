import 'package:uuid/uuid.dart';

enum FactionType { faction, front }

extension FactionTypeExtension on FactionType {
  String get displayName {
    switch (this) {
      case FactionType.faction:
        return 'Facção';
      case FactionType.front:
        return 'Frente';
    }
  }
}

enum FactionPower { weak, moderate, strong, dominant }

extension FactionPowerExtension on FactionPower {
  String get displayName {
    switch (this) {
      case FactionPower.weak:
        return 'Fraco';
      case FactionPower.moderate:
        return 'Moderado';
      case FactionPower.strong:
        return 'Forte';
      case FactionPower.dominant:
        return 'Dominante';
    }
  }
}

class FactionObjective {
  final String text;
  final int currentProgress;
  final int maxProgress;
  final String trigger;

  const FactionObjective({
    required this.text,
    this.currentProgress = 0,
    this.maxProgress = 5,
    this.trigger = '',
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'currentProgress': currentProgress,
    'maxProgress': maxProgress,
    'trigger': trigger,
  };

  factory FactionObjective.fromJson(Map<String, dynamic> json) =>
      FactionObjective(
        text: json['text'] as String? ?? '',
        currentProgress: json['currentProgress'] as int? ?? 0,
        maxProgress: json['maxProgress'] as int? ?? 5,
        trigger: json['trigger'] as String? ?? '',
      );

  FactionObjective copyWith({
    String? text,
    int? currentProgress,
    int? maxProgress,
    String? trigger,
  }) {
    return FactionObjective(
      text: text ?? this.text,
      currentProgress: currentProgress ?? this.currentProgress,
      maxProgress: maxProgress ?? this.maxProgress,
      trigger: trigger ?? this.trigger,
    );
  }
}

class FactionDanger {
  final String name;
  final String drive;
  final String imminentDisaster;
  final List<String> omens;

  const FactionDanger({
    required this.name,
    this.drive = '',
    this.imminentDisaster = '',
    this.omens = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'drive': drive,
    'imminentDisaster': imminentDisaster,
    'omens': omens,
  };

  factory FactionDanger.fromJson(Map<String, dynamic> json) => FactionDanger(
    name: json['name'] as String? ?? '',
    drive: json['drive'] as String? ?? '',
    imminentDisaster: json['imminentDisaster'] as String? ?? '',
    omens: (json['omens'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  FactionDanger copyWith({
    String? name,
    String? drive,
    String? imminentDisaster,
    List<String>? omens,
  }) {
    return FactionDanger(
      name: name ?? this.name,
      drive: drive ?? this.drive,
      imminentDisaster: imminentDisaster ?? this.imminentDisaster,
      omens: omens ?? this.omens,
    );
  }
}

class Faction {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String name;
  final String description;
  final FactionType type;
  final int memberCount;
  final FactionPower powerLevel;
  /// Disposição em relação ao grupo: -3 (inimigo mortal) a +3 (aliado fiel), 0 = neutro
  final int partyDisposition;
  final String? leaderCreatureId;
  final List<String> memberCreatureIds;
  final List<FactionObjective> objectives;
  final List<String> allies;
  final List<String> enemies;
  final List<String> cast;
  final String stakes;
  final List<FactionDanger> dangers;

  const Faction({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.name,
    this.description = '',
    this.type = FactionType.faction,
    this.memberCount = 0,
    this.powerLevel = FactionPower.moderate,
    this.partyDisposition = 0,
    this.leaderCreatureId,
    this.memberCreatureIds = const [],
    this.objectives = const [],
    this.allies = const [],
    this.enemies = const [],
    this.cast = const [],
    this.stakes = '',
    this.dangers = const [],
  });

  factory Faction.create({
    required String campaignId,
    String? adventureId,
    required String name,
    String description = '',
    FactionType type = FactionType.faction,
    int memberCount = 0,
    FactionPower powerLevel = FactionPower.moderate,
    int partyDisposition = 0,
    String? leaderCreatureId,
    List<String> memberCreatureIds = const [],
    List<FactionObjective> objectives = const [],
    List<String> allies = const [],
    List<String> enemies = const [],
    List<String> cast = const [],
    String stakes = '',
    List<FactionDanger> dangers = const [],
  }) {
    return Faction(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      name: name,
      description: description,
      type: type,
      memberCount: memberCount,
      powerLevel: powerLevel,
      partyDisposition: partyDisposition,
      leaderCreatureId: leaderCreatureId,
      memberCreatureIds: memberCreatureIds,
      objectives: objectives,
      allies: allies,
      enemies: enemies,
      cast: cast,
      stakes: stakes,
      dangers: dangers,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'adventureId': adventureId,
    'name': name,
    'description': description,
    'type': type.index,
    'memberCount': memberCount,
    'powerLevel': powerLevel.index,
    'partyDisposition': partyDisposition,
    'leaderCreatureId': leaderCreatureId,
    'memberCreatureIds': memberCreatureIds,
    'objectives': objectives.map((o) => o.toJson()).toList(),
    'allies': allies,
    'enemies': enemies,
    'cast': cast,
    'stakes': stakes,
    'dangers': dangers.map((d) => d.toJson()).toList(),
  };

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String,
    adventureId: json['adventureId'] as String?,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    type: FactionType.values[json['type'] as int? ?? 0],
    memberCount: json['memberCount'] as int? ?? 0,
    powerLevel: FactionPower.values[json['powerLevel'] as int? ?? 1],
    partyDisposition: json['partyDisposition'] as int? ?? 0,
    leaderCreatureId: json['leaderCreatureId'] as String?,
    memberCreatureIds:
        (json['memberCreatureIds'] as List<dynamic>?)?.cast<String>() ??
        const [],
    objectives: (json['objectives'] as List<dynamic>?)
            ?.map((o) => FactionObjective.fromJson((o as Map).cast<String, dynamic>()))
            .toList() ??
        const [],
    allies:
        (json['allies'] as List<dynamic>?)?.cast<String>() ?? const [],
    enemies:
        (json['enemies'] as List<dynamic>?)?.cast<String>() ?? const [],
    cast: (json['cast'] as List<dynamic>?)?.cast<String>() ?? const [],
    stakes: json['stakes'] as String? ?? '',
    dangers: (json['dangers'] as List<dynamic>?)
            ?.map((d) => FactionDanger.fromJson((d as Map).cast<String, dynamic>()))
            .toList() ??
        const [],
  );

  Faction copyWith({
    String? campaignId,
    String? adventureId,
    bool clearAdventureId = false,
    String? name,
    String? description,
    FactionType? type,
    int? memberCount,
    FactionPower? powerLevel,
    int? partyDisposition,
    String? leaderCreatureId,
    List<String>? memberCreatureIds,
    List<FactionObjective>? objectives,
    List<String>? allies,
    List<String>? enemies,
    List<String>? cast,
    String? stakes,
    List<FactionDanger>? dangers,
  }) {
    return Faction(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      memberCount: memberCount ?? this.memberCount,
      powerLevel: powerLevel ?? this.powerLevel,
      partyDisposition: partyDisposition ?? this.partyDisposition,
      leaderCreatureId: leaderCreatureId ?? this.leaderCreatureId,
      memberCreatureIds: memberCreatureIds ?? this.memberCreatureIds,
      objectives: objectives ?? this.objectives,
      allies: allies ?? this.allies,
      enemies: enemies ?? this.enemies,
      cast: cast ?? this.cast,
      stakes: stakes ?? this.stakes,
      dangers: dangers ?? this.dangers,
    );
  }
}
