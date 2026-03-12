import 'package:uuid/uuid.dart';

enum NoteCategory { sessionPrep, worldbuilding, plotHooks, rules, misc }

extension NoteCategoryExtension on NoteCategory {
  String get displayName {
    switch (this) {
      case NoteCategory.sessionPrep:
        return 'Preparação de Sessão';
      case NoteCategory.worldbuilding:
        return 'Construção de Mundo';
      case NoteCategory.plotHooks:
        return 'Ganchos de Trama';
      case NoteCategory.rules:
        return 'Regras';
      case NoteCategory.misc:
        return 'Diversos';
    }
  }
}

class Note {
  final String id;
  final String campaignId;
  final String title;
  final String content;
  final NoteCategory category;
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.campaignId,
    required this.title,
    this.content = '',
    this.category = NoteCategory.misc,
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.create({
    required String campaignId,
    required String title,
    String content = '',
    NoteCategory category = NoteCategory.misc,
    List<String> tags = const [],
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    return Note(
      id: const Uuid().v4(),
      campaignId: campaignId,
      title: title,
      content: content,
      category: category,
      tags: tags,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'title': title,
    'content': content,
    'category': category.index,
    'tags': tags,
    'isPinned': isPinned,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String,
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    category: NoteCategory.values[json['category'] as int? ?? 4],
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    isPinned: json['isPinned'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
  );

  Note copyWith({
    String? title,
    String? content,
    NoteCategory? category,
    List<String>? tags,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      campaignId: campaignId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
