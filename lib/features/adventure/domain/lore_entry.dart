import 'package:uuid/uuid.dart';

enum LoreCategory { deity, myth, history, geography, custom }

extension LoreCategoryExtension on LoreCategory {
  String get displayName {
    switch (this) {
      case LoreCategory.deity:
        return 'Divindade';
      case LoreCategory.myth:
        return 'Mito';
      case LoreCategory.history:
        return 'História';
      case LoreCategory.geography:
        return 'Geografia';
      case LoreCategory.custom:
        return 'Personalizado';
    }
  }
}

class LoreEntry {
  final String id;
  final String campaignId;
  final String title;
  final String content;
  final LoreCategory category;
  final List<String> tags;

  const LoreEntry({
    required this.id,
    required this.campaignId,
    required this.title,
    this.content = '',
    this.category = LoreCategory.custom,
    this.tags = const [],
  });

  factory LoreEntry.create({
    required String campaignId,
    required String title,
    String content = '',
    LoreCategory category = LoreCategory.custom,
    List<String> tags = const [],
  }) {
    return LoreEntry(
      id: const Uuid().v4(),
      campaignId: campaignId,
      title: title,
      content: content,
      category: category,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'title': title,
    'content': content,
    'category': category.index,
    'tags': tags,
  };

  factory LoreEntry.fromJson(Map<String, dynamic> json) => LoreEntry(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String,
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    category: LoreCategory.values[json['category'] as int? ?? 4],
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  LoreEntry copyWith({
    String? title,
    String? content,
    LoreCategory? category,
    List<String>? tags,
  }) {
    return LoreEntry(
      id: id,
      campaignId: campaignId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}
