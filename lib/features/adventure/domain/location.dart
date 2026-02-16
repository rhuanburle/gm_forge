import 'package:uuid/uuid.dart';

class Location {
  final String id;
  final String adventureId;
  final String name;
  final String description;
  final String? imagePath;
  final String? parentLocationId;

  const Location({
    required this.id,
    required this.adventureId,
    required this.name,
    this.description = '',
    this.imagePath,
    this.parentLocationId,
  });

  factory Location.create({
    required String adventureId,
    required String name,
    String description = '',
    String? imagePath,
    String? parentLocationId,
  }) {
    return Location(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: name,
      description: description,
      imagePath: imagePath,
      parentLocationId: parentLocationId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'adventureId': adventureId,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'parentLocationId': parentLocationId,
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'] as String,
    adventureId: json['adventureId'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    imagePath: json['imagePath'] as String?,
    parentLocationId: json['parentLocationId'] as String?,
  );

  Location copyWith({
    String? name,
    String? description,
    String? imagePath,
    String? parentLocationId,
  }) {
    return Location(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      parentLocationId: parentLocationId ?? this.parentLocationId,
    );
  }
}
