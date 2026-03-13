import 'package:uuid/uuid.dart';

enum ItemType { weapon, armor, potion, scroll, artifact, misc }

extension ItemTypeExtension on ItemType {
  String get displayName {
    switch (this) {
      case ItemType.weapon:
        return 'Arma';
      case ItemType.armor:
        return 'Armadura';
      case ItemType.potion:
        return 'Poção';
      case ItemType.scroll:
        return 'Pergaminho';
      case ItemType.artifact:
        return 'Artefato';
      case ItemType.misc:
        return 'Diversos';
    }
  }
}

enum ItemRarity { common, uncommon, rare, veryRare, legendary }

extension ItemRarityExtension on ItemRarity {
  String get displayName {
    switch (this) {
      case ItemRarity.common:
        return 'Comum';
      case ItemRarity.uncommon:
        return 'Incomum';
      case ItemRarity.rare:
        return 'Raro';
      case ItemRarity.veryRare:
        return 'Muito Raro';
      case ItemRarity.legendary:
        return 'Lendário';
    }
  }
}

class Item {
  final String id;
  final String campaignId;
  final String? adventureId;
  final String name;
  final String description;
  final ItemType type;
  final String mechanics;
  final String? ownerCreatureId;
  final String? locationId;
  final ItemRarity rarity;

  const Item({
    required this.id,
    required this.campaignId,
    this.adventureId,
    required this.name,
    this.description = '',
    this.type = ItemType.misc,
    this.mechanics = '',
    this.ownerCreatureId,
    this.locationId,
    this.rarity = ItemRarity.common,
  });

  factory Item.create({
    required String campaignId,
    String? adventureId,
    required String name,
    String description = '',
    ItemType type = ItemType.misc,
    String mechanics = '',
    String? ownerCreatureId,
    String? locationId,
    ItemRarity rarity = ItemRarity.common,
  }) {
    return Item(
      id: const Uuid().v4(),
      campaignId: campaignId,
      adventureId: adventureId,
      name: name,
      description: description,
      type: type,
      mechanics: mechanics,
      ownerCreatureId: ownerCreatureId,
      locationId: locationId,
      rarity: rarity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'adventureId': adventureId,
    'name': name,
    'description': description,
    'type': type.index,
    'mechanics': mechanics,
    'ownerCreatureId': ownerCreatureId,
    'locationId': locationId,
    'rarity': rarity.index,
  };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] as String,
    campaignId: json["campaignId"] as String? ?? json["adventureId"] as String, // Fallback for migration
    adventureId: json['adventureId'] as String?,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    type: ItemType.values[json['type'] as int? ?? 5],
    mechanics: json['mechanics'] as String? ?? '',
    ownerCreatureId: json['ownerCreatureId'] as String?,
    locationId: json['locationId'] as String?,
    rarity: ItemRarity.values[json['rarity'] as int? ?? 0],
  );

  Item copyWith({
    String? campaignId,
    String? adventureId,
    bool clearAdventureId = false,
    String? name,
    String? description,
    ItemType? type,
    String? mechanics,
    String? ownerCreatureId,
    bool clearOwner = false,
    String? locationId,
    bool clearLocation = false,
    ItemRarity? rarity,
  }) {
    return Item(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      adventureId: clearAdventureId ? null : (adventureId ?? this.adventureId),
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      mechanics: mechanics ?? this.mechanics,
      ownerCreatureId:
          clearOwner ? null : (ownerCreatureId ?? this.ownerCreatureId),
      locationId: clearLocation ? null : (locationId ?? this.locationId),
      rarity: rarity ?? this.rarity,
    );
  }
}
