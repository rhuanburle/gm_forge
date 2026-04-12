import 'package:uuid/uuid.dart';

class WorldConsequence {
  final String id;
  final String campaignId;
  final String title;
  final String description;
  final String affectedArea;
  final int? sessionNumber;
  final DateTime createdAt;

  const WorldConsequence({
    required this.id,
    required this.campaignId,
    required this.title,
    this.description = '',
    this.affectedArea = '',
    this.sessionNumber,
    required this.createdAt,
  });

  factory WorldConsequence.create({
    required String campaignId,
    required String title,
    String description = '',
    String affectedArea = '',
    int? sessionNumber,
  }) {
    return WorldConsequence(
      id: const Uuid().v4(),
      campaignId: campaignId,
      title: title,
      description: description,
      affectedArea: affectedArea,
      sessionNumber: sessionNumber,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'title': title,
    'description': description,
    'affectedArea': affectedArea,
    'sessionNumber': sessionNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WorldConsequence.fromJson(Map<String, dynamic> json) =>
      WorldConsequence(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        affectedArea: json['affectedArea'] as String? ?? '',
        sessionNumber: json['sessionNumber'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  WorldConsequence copyWith({
    String? title,
    String? description,
    String? affectedArea,
    int? sessionNumber,
    bool clearSessionNumber = false,
  }) {
    return WorldConsequence(
      id: id,
      campaignId: campaignId,
      title: title ?? this.title,
      description: description ?? this.description,
      affectedArea: affectedArea ?? this.affectedArea,
      sessionNumber:
          clearSessionNumber ? null : (sessionNumber ?? this.sessionNumber),
      createdAt: createdAt,
    );
  }
}
