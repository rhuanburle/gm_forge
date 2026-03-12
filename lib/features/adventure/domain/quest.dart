import 'package:uuid/uuid.dart';

enum QuestStatus { notStarted, inProgress, completed, failed }

extension QuestStatusExtension on QuestStatus {
  String get displayName {
    switch (this) {
      case QuestStatus.notStarted:
        return 'Não Iniciada';
      case QuestStatus.inProgress:
        return 'Em Progresso';
      case QuestStatus.completed:
        return 'Concluída';
      case QuestStatus.failed:
        return 'Fracassada';
    }
  }
}

class QuestObjective {
  final String text;
  final bool isComplete;

  const QuestObjective({required this.text, this.isComplete = false});

  Map<String, dynamic> toJson() => {
    'text': text,
    'isComplete': isComplete,
  };

  factory QuestObjective.fromJson(Map<String, dynamic> json) =>
      QuestObjective(
        text: json['text'] as String? ?? '',
        isComplete: json['isComplete'] as bool? ?? false,
      );

  QuestObjective copyWith({String? text, bool? isComplete}) {
    return QuestObjective(
      text: text ?? this.text,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class Quest {
  final String id;
  final String adventureId;
  final String name;
  final String description;
  final QuestStatus status;
  final String? giverCreatureId;
  final List<QuestObjective> objectives;
  final String rewardDescription;
  final List<String> relatedLocationIds;

  const Quest({
    required this.id,
    required this.adventureId,
    required this.name,
    this.description = '',
    this.status = QuestStatus.notStarted,
    this.giverCreatureId,
    this.objectives = const [],
    this.rewardDescription = '',
    this.relatedLocationIds = const [],
  });

  factory Quest.create({
    required String adventureId,
    required String name,
    String description = '',
    QuestStatus status = QuestStatus.notStarted,
    String? giverCreatureId,
    List<QuestObjective> objectives = const [],
    String rewardDescription = '',
    List<String> relatedLocationIds = const [],
  }) {
    return Quest(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: name,
      description: description,
      status: status,
      giverCreatureId: giverCreatureId,
      objectives: objectives,
      rewardDescription: rewardDescription,
      relatedLocationIds: relatedLocationIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'name': name,
    'description': description,
    'status': status.index,
    'giverCreatureId': giverCreatureId,
    'objectives': objectives.map((o) => o.toJson()).toList(),
    'rewardDescription': rewardDescription,
    'relatedLocationIds': relatedLocationIds,
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json['id'] as String,
    adventureId: json['adventureId'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    status: QuestStatus.values[json['status'] as int? ?? 0],
    giverCreatureId: json['giverCreatureId'] as String?,
    objectives: (json['objectives'] as List<dynamic>?)
            ?.map((o) => QuestObjective.fromJson(o as Map<String, dynamic>))
            .toList() ??
        const [],
    rewardDescription: json['rewardDescription'] as String? ?? '',
    relatedLocationIds:
        (json['relatedLocationIds'] as List<dynamic>?)?.cast<String>() ??
        const [],
  );

  Quest copyWith({
    String? name,
    String? description,
    QuestStatus? status,
    String? giverCreatureId,
    bool clearGiver = false,
    List<QuestObjective>? objectives,
    String? rewardDescription,
    List<String>? relatedLocationIds,
  }) {
    return Quest(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      giverCreatureId:
          clearGiver ? null : (giverCreatureId ?? this.giverCreatureId),
      objectives: objectives ?? this.objectives,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      relatedLocationIds: relatedLocationIds ?? this.relatedLocationIds,
    );
  }
}
