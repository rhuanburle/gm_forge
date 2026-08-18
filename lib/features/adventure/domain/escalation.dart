import 'package:uuid/uuid.dart';

/// Ordered sequence of escalating events that fire during play.
///
/// Generic enough for any system: mystery countdowns (Vaesen),
/// recurring-threat tables (Dragonbane "Morte Branca aparece"),
/// OSR doom timers. The default outcome is what happens if the PCs
/// never intervene and every step fires.
class Escalation {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String title;
  final String? description;
  final List<EscalationStep> steps;
  final String? defaultOutcome;
  final int currentStepIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Escalation({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.title,
    this.description,
    this.steps = const [],
    this.defaultOutcome,
    this.currentStepIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Escalation.create({
    required String campaignId,
    String? adventureId,
    required String title,
    String? description,
    List<EscalationStep> steps = const [],
    String? defaultOutcome,
  }) {
    final now = DateTime.now();
    return Escalation(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      title: title,
      description: description,
      steps: steps,
      defaultOutcome: defaultOutcome,
      currentStepIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'adventureId': adventureId,
    'title': title,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'defaultOutcome': defaultOutcome,
    'currentStepIndex': currentStepIndex,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Escalation.fromJson(Map<String, dynamic> json) => Escalation(
    id: json['id'] as String,
    campaignId:
        json['campaignId'] as String? ?? json['adventureId'] as String? ?? '',
    adventureId: json['adventureId'] as String?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    steps: (json['steps'] as List<dynamic>?)
            ?.map((e) => EscalationStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [],
    defaultOutcome: json['defaultOutcome'] as String?,
    currentStepIndex: json['currentStepIndex'] as int? ?? 0,
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
        : DateTime.now(),
  );

  Escalation copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    List<EscalationStep>? steps,
    String? defaultOutcome,
    bool clearDefaultOutcome = false,
    int? currentStepIndex,
    String? adventureId,
    bool clearAdventureId = false,
    DateTime? updatedAt,
  }) {
    return Escalation(
      id: id,
      campaignId: campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      steps: steps ?? this.steps,
      defaultOutcome: clearDefaultOutcome
          ? null
          : (defaultOutcome ?? this.defaultOutcome),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class EscalationStep {
  final String label;
  final String? trigger;
  final String? effect;
  final bool fired;

  const EscalationStep({
    required this.label,
    this.trigger,
    this.effect,
    this.fired = false,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'trigger': trigger,
    'effect': effect,
    'fired': fired,
  };

  factory EscalationStep.fromJson(Map<String, dynamic> json) => EscalationStep(
    label: json['label'] as String? ?? '',
    trigger: json['trigger'] as String?,
    effect: json['effect'] as String?,
    fired: json['fired'] as bool? ?? false,
  );

  EscalationStep copyWith({
    String? label,
    String? trigger,
    bool clearTrigger = false,
    String? effect,
    bool clearEffect = false,
    bool? fired,
  }) {
    return EscalationStep(
      label: label ?? this.label,
      trigger: clearTrigger ? null : (trigger ?? this.trigger),
      effect: clearEffect ? null : (effect ?? this.effect),
      fired: fired ?? this.fired,
    );
  }
}
