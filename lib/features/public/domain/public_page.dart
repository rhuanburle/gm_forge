import 'dart:math';

/// A published, player-safe snapshot of a campaign.
/// Stored at Firestore: public_pages/{shareId}
class PublicPage {
  final String shareId;
  final String userId;
  final String campaignId;
  final String campaignName;
  final String campaignDescription;
  final List<PublicSession> sessions;
  final List<PublicQuest> quests;
  final List<PublicCreature> npcs;
  final List<PublicFact> facts;
  final List<PublicPlayerCharacter> playerCharacters;
  final DateTime publishedAt;
  final bool isActive;

  const PublicPage({
    required this.shareId,
    required this.userId,
    required this.campaignId,
    required this.campaignName,
    this.campaignDescription = '',
    this.sessions = const [],
    this.quests = const [],
    this.npcs = const [],
    this.facts = const [],
    this.playerCharacters = const [],
    required this.publishedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'userId': userId,
    'campaignId': campaignId,
    'campaignName': campaignName,
    'campaignDescription': campaignDescription,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'quests': quests.map((q) => q.toJson()).toList(),
    'npcs': npcs.map((n) => n.toJson()).toList(),
    'facts': facts.map((f) => f.toJson()).toList(),
    'playerCharacters': playerCharacters.map((p) => p.toJson()).toList(),
    'publishedAt': publishedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory PublicPage.fromJson(Map<String, dynamic> json) => PublicPage(
    shareId: json['shareId'] as String,
    userId: json['userId'] as String,
    campaignId: json['campaignId'] as String,
    campaignName: json['campaignName'] as String,
    campaignDescription: json['campaignDescription'] as String? ?? '',
    sessions: (json['sessions'] as List<dynamic>?)
        ?.map((s) => PublicSession.fromJson(Map<String, dynamic>.from(s)))
        .toList() ?? [],
    quests: (json['quests'] as List<dynamic>?)
        ?.map((q) => PublicQuest.fromJson(Map<String, dynamic>.from(q)))
        .toList() ?? [],
    npcs: (json['npcs'] as List<dynamic>?)
        ?.map((n) => PublicCreature.fromJson(Map<String, dynamic>.from(n)))
        .toList() ?? [],
    facts: (json['facts'] as List<dynamic>?)
        ?.map((f) => PublicFact.fromJson(Map<String, dynamic>.from(f)))
        .toList() ?? [],
    playerCharacters: (json['playerCharacters'] as List<dynamic>?)
        ?.map((p) => PublicPlayerCharacter.fromJson(Map<String, dynamic>.from(p)))
        .toList() ?? [],
    publishedAt: DateTime.parse(json['publishedAt'] as String),
    isActive: json['isActive'] as bool? ?? true,
  );

  /// Generate a short, URL-friendly share ID
  static String generateShareId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

class PublicSession {
  final int number;
  final String name;
  final String date;
  final String recap;

  const PublicSession({
    required this.number,
    required this.name,
    required this.date,
    this.recap = '',
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'date': date,
    'recap': recap,
  };

  factory PublicSession.fromJson(Map<String, dynamic> json) => PublicSession(
    number: json['number'] as int,
    name: json['name'] as String,
    date: json['date'] as String,
    recap: json['recap'] as String? ?? '',
  );
}

class PublicQuest {
  final String name;
  final String description;
  final String status;
  final List<PublicObjective> objectives;

  const PublicQuest({
    required this.name,
    this.description = '',
    required this.status,
    this.objectives = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'status': status,
    'objectives': objectives.map((o) => o.toJson()).toList(),
  };

  factory PublicQuest.fromJson(Map<String, dynamic> json) => PublicQuest(
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    status: json['status'] as String,
    objectives: (json['objectives'] as List<dynamic>?)
        ?.map((o) => PublicObjective.fromJson(Map<String, dynamic>.from(o)))
        .toList() ?? [],
  );
}

class PublicObjective {
  final String text;
  final bool isComplete;

  const PublicObjective({required this.text, this.isComplete = false});

  Map<String, dynamic> toJson() => {'text': text, 'isComplete': isComplete};

  factory PublicObjective.fromJson(Map<String, dynamic> json) => PublicObjective(
    text: json['text'] as String,
    isComplete: json['isComplete'] as bool? ?? false,
  );
}

class PublicCreature {
  final String name;
  final String description;
  final String? imageUrl;

  const PublicCreature({
    required this.name,
    this.description = '',
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
  };

  factory PublicCreature.fromJson(Map<String, dynamic> json) => PublicCreature(
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
  );
}

class PublicFact {
  final String content;
  final String sourceName;

  const PublicFact({required this.content, this.sourceName = ''});

  Map<String, dynamic> toJson() => {
    'content': content,
    'sourceName': sourceName,
  };

  factory PublicFact.fromJson(Map<String, dynamic> json) => PublicFact(
    content: json['content'] as String,
    sourceName: json['sourceName'] as String? ?? '',
  );
}

class PublicPlayerCharacter {
  final String name;
  final String playerName;
  final String species;
  final String characterClass;
  final int level;
  final String? imageUrl;

  const PublicPlayerCharacter({
    required this.name,
    this.playerName = '',
    this.species = '',
    this.characterClass = '',
    this.level = 1,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'playerName': playerName,
    'species': species,
    'characterClass': characterClass,
    'level': level,
    'imageUrl': imageUrl,
  };

  factory PublicPlayerCharacter.fromJson(Map<String, dynamic> json) =>
      PublicPlayerCharacter(
        name: json['name'] as String,
        playerName: json['playerName'] as String? ?? '',
        species: json['species'] as String? ?? '',
        characterClass: json['characterClass'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        imageUrl: json['imageUrl'] as String?,
      );
}
