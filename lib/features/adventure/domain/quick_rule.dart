import 'package:uuid/uuid.dart';

class QuickRule {
  final String id;
  final String campaignId;
  final String title;
  final String content;
  final String category;
  final int order;

  const QuickRule({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.content,
    this.category = 'Geral',
    this.order = 0,
  });

  factory QuickRule.create({
    required String campaignId,
    required String title,
    required String content,
    String category = 'Geral',
    int order = 0,
  }) {
    return QuickRule(
      id: const Uuid().v4(),
      campaignId: campaignId,
      title: title,
      content: content,
      category: category,
      order: order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'title': title,
    'content': content,
    'category': category,
    'order': order,
  };

  factory QuickRule.fromJson(Map<String, dynamic> json) => QuickRule(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    category: json['category'] as String? ?? 'Geral',
    order: json['order'] as int? ?? 0,
  );

  QuickRule copyWith({
    String? title,
    String? content,
    String? category,
    int? order,
  }) => QuickRule(
    id: id,
    campaignId: campaignId,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category ?? this.category,
    order: order ?? this.order,
  );
}
