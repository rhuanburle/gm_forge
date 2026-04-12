import 'package:uuid/uuid.dart';

class Fact {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String content;
  final String? sourceId;
  final bool isSecret;
  final bool revealed;
  final DateTime? revealedAt;
  final List<String> tags;
  final DateTime createdAt;

  Fact({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.content,
    this.sourceId,
    this.isSecret = false,
    this.revealed = false,
    this.revealedAt,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'adventureId': adventureId,
      'content': content,
      'sourceId': sourceId,
      'isSecret': isSecret,
      'revealed': revealed,
      'revealedAt': revealedAt?.toIso8601String(),
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      id: json['id'] as String,
      campaignId: json['campaignId'] as String? ?? json['adventureId'] as String,
      adventureId: json['adventureId'] as String?,
      content: json['content'] as String,
      sourceId: json['sourceId'] as String?,
      isSecret: json['isSecret'] as bool? ?? false,
      revealed: json['revealed'] as bool? ?? false,
      revealedAt: json['revealedAt'] != null
          ? DateTime.tryParse(json['revealedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory Fact.create({
    required String campaignId,
    String? adventureId,
    required String content,
    String? sourceId,
    bool isSecret = false,
    List<String> tags = const [],
  }) {
    return Fact(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      content: content,
      sourceId: sourceId,
      isSecret: isSecret,
      tags: tags,
    );
  }

  Fact copyWith({
    String? content,
    String? sourceId,
    bool clearSourceId = false,
    bool? isSecret,
    bool? revealed,
    DateTime? revealedAt,
    bool clearRevealedAt = false,
    List<String>? tags,
  }) {
    return Fact(
      id: id,
      campaignId: campaignId,
      adventureId: adventureId,
      content: content ?? this.content,
      sourceId: clearSourceId ? null : (sourceId ?? this.sourceId),
      isSecret: isSecret ?? this.isSecret,
      revealed: revealed ?? this.revealed,
      revealedAt: clearRevealedAt ? null : (revealedAt ?? this.revealedAt),
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}
