import 'package:uuid/uuid.dart';

/// Campaign entity - a container for linked adventures
class Campaign {
  String id;
  String name;
  String description;

  /// List of Adventure IDs that belong to this campaign
  /// Order matters for the campaign flow
  List<String> adventureIds;

  DateTime createdAt;
  DateTime updatedAt;

  Campaign({
    String? id,
    required this.name,
    required this.description,
    List<String>? adventureIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       adventureIds = adventureIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'adventureIds': adventureIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    adventureIds:
        (json['adventureIds'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Campaign copyWith({
    String? name,
    String? description,
    List<String>? adventureIds,
  }) => Campaign(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    adventureIds: adventureIds ?? this.adventureIds,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
