import 'package:uuid/uuid.dart';

class Fact {
  final String id;
  final String adventureId;
  final String content;
  final String? sourceId;
  final bool isSecret;
  final List<String> tags;
  final DateTime createdAt;

  Fact({
    required this.id,
    required this.adventureId,
    required this.content,
    this.sourceId,
    this.isSecret = false,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adventureId': adventureId,
      'content': content,
      'sourceId': sourceId,
      'isSecret': isSecret,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      id: json['id'] as String,
      adventureId: json['adventureId'] as String,
      content: json['content'] as String,
      sourceId: json['sourceId'] as String?,
      isSecret: json['isSecret'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory Fact.create({
    required String adventureId,
    required String content,
    String? sourceId,
    bool isSecret = false,
    List<String> tags = const [],
  }) {
    return Fact(
      id: const Uuid().v4(),
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
    bool? isSecret,
    List<String>? tags,
  }) {
    return Fact(
      id: id,
      adventureId: adventureId,
      content: content ?? this.content,
      sourceId: sourceId ?? this.sourceId,
      isSecret: isSecret ?? this.isSecret,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}
