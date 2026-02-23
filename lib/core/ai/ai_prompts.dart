enum AiFieldType {
  adventureName,
  adventureDescription,
  campaignName,
  campaignDescription,
  conceptLocation,
  conceptConflict,
  conceptConflictSecondary,
  narrativeHook,
  creatureDescription,
  creatureMotivation,
  creatureLosingBehavior,
  creatureStats,
  legendText,
  eventDescription,
  eventImpact,
  locationDescription,
  poiFirstImpression,
  poiObvious,
  poiDetail,
  poiTreasure,
}

class AiPrompts {
  AiPrompts._();

  static const String _systemPrompt = '''
You are an expert Game Master assistant specializing in tabletop RPG adventure design.
You help Game Masters create immersive, evocative content for their adventures.
The setting and genre are determined by the context provided — you adapt your style accordingly (fantasy, horror, sci-fi, etc.).
Always respond in Brazilian Portuguese (PT-BR), regardless of the input language.
Be concise, creative, and focus on sensory details and dramatic tension.
Never exceed the scope of what was asked — keep responses focused and usable at the table.
''';

  static String getSystemPrompt() => _systemPrompt;

  static String buildImprovePrompt({
    required AiFieldType fieldType,
    required String currentText,
    required Map<String, String> adventureContext,
  }) {
    final contextBlock = _buildContextBlock(adventureContext);
    final fieldInstruction = _getImproveInstruction(fieldType);

    return '''
$contextBlock

CRITICAL RULES FOR IMPROVING TEXT:
1. RESPECT THE CORE: You can expand the text and add immersive details (sensory descriptions, atmosphere, world-building flavor), but you MUST NOT alter the original facts, invent new main characters, or change the intent of the writer.
2. ENHANCE PROSE: Elevate the writing style, vocabulary, and grammar. Make it sound like a published RPG adventure book.
3. ALLOWED EXPANSION: You may add 1-3 sentences of evocative flavor to enrich the description, as long as it fits the setting and obeys Rule 1.
4. NO META-TEXT: Return ONLY the improved text, without introducing phrases like "Here is the improved text" or quoting it.

$fieldInstruction

Current text to improve:
"$currentText"
''';
  }

  static String buildSuggestPrompt({
    required AiFieldType fieldType,
    required Map<String, String> adventureContext,
    Map<String, String>? extraContext,
  }) {
    final contextBlock = _buildContextBlock(adventureContext);
    final fieldInstruction = _getSuggestInstruction(fieldType, extraContext);

    return '''
$contextBlock

$fieldInstruction

Return ONLY the text content, nothing else. No labels, no explanations.
''';
  }

  static String _buildContextBlock(Map<String, String> context) {
    final parts = <String>[];

    if (context['adventureName']?.isNotEmpty == true) {
      parts.add('Adventure Name: ${context['adventureName']}');
    }
    if (context['conceptLocation']?.isNotEmpty == true) {
      parts.add('Setting: ${context['conceptLocation']}');
    }
    if (context['conceptConflict']?.isNotEmpty == true) {
      parts.add('Main Conflict: ${context['conceptConflict']}');
    }
    if (context['locationName']?.isNotEmpty == true) {
      parts.add('Current Location: ${context['locationName']}');
    }
    if (context['creatureName']?.isNotEmpty == true) {
      parts.add('Creature/NPC: ${context['creatureName']}');
    }
    if (context['creatureType']?.isNotEmpty == true) {
      parts.add('Type: ${context['creatureType']}');
    }
    if (context['poiName']?.isNotEmpty == true) {
      parts.add('Room/POI: ${context['poiName']}');
    }
    if (context['poiPurpose']?.isNotEmpty == true) {
      parts.add('Room Purpose: ${context['poiPurpose']}');
    }

    if (parts.isEmpty) {
      return 'No specific adventure context provided.';
    }

    return 'ADVENTURE CONTEXT:\n${parts.join('\n')}';
  }

  static String _getImproveInstruction(AiFieldType fieldType) {
    switch (fieldType) {
      case AiFieldType.adventureName:
        return 'Make this adventure name more evocative, mysterious, or exciting. Keep it short (2-5 words).';

      case AiFieldType.adventureDescription:
        return 'Improve this adventure overview. Make it engaging and give a clear sense of tone and stakes.';

      case AiFieldType.campaignName:
        return 'Make this campaign name epic, grand, and evocative. Keep it short (2-5 words).';

      case AiFieldType.campaignDescription:
        return 'Improve this campaign description. Give it a sweeping, epic tone that promises a long, heroic (or tragic) journey.';

      case AiFieldType.conceptLocation:
        return 'Improve this location description. Focus on atmosphere, history, and what makes this place unique and dangerous or compelling.';

      case AiFieldType.conceptConflict:
        return 'Improve this conflict description. Ensure there are clear factions, motivations, and tensions. The conflict should feel inevitable yet complex.';

      case AiFieldType.conceptConflictSecondary:
        return 'Improve this secondary conflict. It should complement the main conflict and add layers of complexity without overshadowing the main plot.';

      case AiFieldType.narrativeHook:
        return 'Improve this narrative hook for the next adventure. Make it tantalizing — a mystery, a threat, or a looming danger that players cannot ignore.';

      case AiFieldType.creatureDescription:
        return 'Improve this creature/NPC description. Focus on appearance, combat behavior, personality, and what makes them memorable at the table.';

      case AiFieldType.creatureMotivation:
        return 'Improve this motivation. Make it feel authentic and understandable — even for a monster. Avoid generic "wants to kill PCs". Add nuance.';

      case AiFieldType.creatureLosingBehavior:
        return 'Improve this losing behavior. Be specific about what the creature/NPC does when clearly losing: flee, negotiate, sacrifice themselves, berserk, etc.';

      case AiFieldType.creatureStats:
        return 'Improve these combat stats. Make them clear and table-ready. Use a concise format like: HP X, AC Y, ATK +Z (Xd6+Y), SAVE X.';

      case AiFieldType.legendText:
        return 'Improve this rumor text. Make it evocative and feel like something a real person would actually say in a tavern. Keep the truth/falsehood ambiguous.';

      case AiFieldType.eventDescription:
        return 'Improve this random event description. Make it dramatic, immediate, and requiring a reaction from the players.';

      case AiFieldType.eventImpact:
        return 'Improve this mechanical/narrative impact. Be specific about mechanical consequences and how this event changes the scene.';

      case AiFieldType.locationDescription:
        return 'Improve this location/room description. Focus on atmosphere: lighting, smells, sounds, temperature. Make players feel present.';

      case AiFieldType.poiFirstImpression:
        return 'Improve this first impression. Describe what ALL senses perceive the moment a door opens or players enter. Be immediate and evocative.';

      case AiFieldType.poiObvious:
        return 'Improve this "obvious" section. List what any player would see without investigation. Be clear and specific — these are facts, not secrets.';

      case AiFieldType.poiDetail:
        return 'Improve this detail/secret section. What do players find when they investigate? Include one mechanical reward (clue, advantage, item) and one potential danger.';

      case AiFieldType.poiTreasure:
        return 'Improve this treasure description. Be specific (not just "gold") — items have names, histories, and sometimes drawbacks. Make it feel earned.';
    }
  }

  static String _getSuggestInstruction(
    AiFieldType fieldType,
    Map<String, String>? extra,
  ) {
    switch (fieldType) {
      case AiFieldType.adventureName:
        return 'Generate a short, evocative adventure title (2-5 words) that fits the context.';

      case AiFieldType.adventureDescription:
        return 'Write a 2-3 sentence adventure overview that captures the tone, setting, and stakes.';

      case AiFieldType.campaignName:
        return 'Generate an epic, memorable title for a whole RPG campaign (2-5 words).';

      case AiFieldType.campaignDescription:
        return 'Write a 2-3 sentence campaign overview that sets a grand scale, outlining the main arc or overarching threat.';

      case AiFieldType.conceptLocation:
        return 'Describe the adventure location in 2-3 sentences. Focus on what makes it atmospheric, dangerous, or compelling for exploration.';

      case AiFieldType.conceptConflict:
        return 'Write the main conflict in 2-3 sentences. Include at least two factions or forces in opposition, and what is at stake.';

      case AiFieldType.conceptConflictSecondary:
        return 'Create a secondary conflict that adds complexity to the adventure. It should be related to but distinct from the main conflict.';

      case AiFieldType.narrativeHook:
        return 'Write a narrative hook pointing to the next adventure. It should be a tantalizing loose end — a mystery, a threat, or a revelation that demands follow-up.';

      case AiFieldType.creatureDescription:
        final creatureType = extra?['creatureType'] ?? 'creature';
        return 'Write a description for this $creatureType. Include notable appearance features, how it fights, and what makes it memorable at the table (2-3 sentences).';

      case AiFieldType.creatureMotivation:
        return 'Write a motivation for this creature/NPC that feels authentic and non-trivial. It should explain their presence in this location and what they truly want.';

      case AiFieldType.creatureLosingBehavior:
        return 'Describe exactly what this creature/NPC does when clearly losing a fight. Be specific and interesting — what they do at 25% HP or when surrounded.';

      case AiFieldType.creatureStats:
        return 'Generate minimal but usable combat stats in a concise format: HP, AC, Attack bonus, Damage, and any 1-2 notable abilities.';

      case AiFieldType.legendText:
        final isTrueStr = extra?['isTrue'] ?? 'true';
        final isTrue = isTrueStr == 'true';
        if (isTrue) {
          return 'Write a TRUE rumor about this adventure location, as something a well-traveled merchant or local guard would say. It should hint at real dangers or treasure without being too obvious.';
        } else {
          return 'Write a FALSE or EXAGGERATED rumor about this adventure location. It should sound plausible but be misleading, creating misdirection or false expectations.';
        }

      case AiFieldType.eventDescription:
        final eventType = extra?['eventType'] ?? '';
        if (eventType.isNotEmpty) {
          return 'Write a random encounter/event of type "$eventType". Make it immediate and requiring a reaction. 1-2 sentences, dramatic and specific.';
        }
        return 'Write a random encounter/event for this adventure. Make it immediate and requiring a reaction. 1-2 sentences, dramatic and specific.';

      case AiFieldType.eventImpact:
        return 'Describe the mechanical and/or narrative impact of this event. Be specific: stat penalties, resource costs, narrative consequences, or advantage/disadvantage.';

      case AiFieldType.locationDescription:
        return 'Describe this room/area atmosphere in 2-3 sentences. Focus on ambiance: quality of light, smells, sounds, temperature, and the general feeling of the space.';

      case AiFieldType.poiFirstImpression:
        final purpose = extra?['poiPurpose'] ?? '';
        return 'Write the first impression of this ${purpose.isNotEmpty ? purpose.toLowerCase() : 'room'} from the doorway. Engage multiple senses in 1-2 sentences. This is what players experience the moment they arrive.';

      case AiFieldType.poiObvious:
        return 'List 2-3 obvious things visible in this room without any investigation. These are facts any observant player would notice immediately.';

      case AiFieldType.poiDetail:
        return 'Describe what players discover when they investigate this room carefully. Include one meaningful reward (clue, item, advantage) and one hidden danger or complication.';

      case AiFieldType.poiTreasure:
        return 'Describe a specific treasure found in this room. Give it a name, a brief description, and optionally a minor history or quirk that makes it memorable.';
    }
  }
}
