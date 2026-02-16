import 'package:uuid/uuid.dart';

class Campaign {
  final String id;
  final String name;
  final String description;

  final List<String> adventureIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Campaign({
    required this.id,
    required this.name,
    required this.description,
    this.adventureIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Campaign.create({required String name, required String description}) {
    return Campaign(
      id: const Uuid().v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
    DateTime? updatedAt,
  }) => Campaign(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    adventureIds: adventureIds ?? this.adventureIds,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
