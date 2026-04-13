import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/adventure/application/adventure_providers.dart';
import '../../features/adventure/domain/domain.dart';
import '../database/hive_database.dart';

final adventureBundleServiceProvider = Provider<AdventureBundleService>((ref) {
  return AdventureBundleService(ref.watch(hiveDatabaseProvider));
});

/// Imports a full adventure bundle JSON (produced by any QuestScript export or
/// hand-crafted JSON) into the local Hive database.
///
/// All entity IDs are remapped to fresh UUIDs to avoid collisions.
/// Image path fields are stripped — users add images manually after import.
class AdventureBundleService {
  final HiveDatabase _db;
  final _uuid = const Uuid();

  AdventureBundleService(this._db);

  // ---------------------------------------------------------------------------
  // Example JSON (shown in the import dialog for reference)
  // ---------------------------------------------------------------------------

  /// A complete, self-consistent example bundle covering every entity type.
  ///
  /// IMPORTANT: All "id" fields are optional and serve only as cross-reference
  /// keys within this JSON (e.g. a POI's "creatureIds" list points to a
  /// creature by its key here). The system replaces every ID with a fresh UUID
  /// on import — there is zero risk of collision with existing data.
  /// If an entity does not need to be referenced by others, you may omit its
  /// "id" field entirely.
  static const String exampleJson = r'''
{
  "adventure": {
    "id": "adv-001",
    "name": "A Tumba do Cavaleiro Dragão",
    "description": "Uma tumba selada nas montanhas, guardada por um culto de mortos-vivos.",
    "conceptWhat": "Uma tumba élfica nos picos gelados do norte",
    "conceptConflict": "Um culto quer despertar o cavaleiro para usá-lo como arma",
    "conceptSecondaryConflicts": [
      "A nobre família do cavaleiro quer recuperar seus restos",
      "Um mago rival busca o grimório enterrado com ele"
    ],
    "nextAdventureHint": "O sigilo encontrado na tumba aponta para um segundo sepulcro a leste",
    "tags": ["mortos-vivos", "tumba", "cultistas"],
    "sessionNotes": ""
  },

  "locations": [
    {
      "id": "loc-001",
      "name": "Picos Gelados do Norte",
      "description": "Montanhas cobertas de neve eterna. O vento uiva entre as rochas.",
      "parentLocationId": null,
      "creatureIds": [],
      "scenicEncounters": [
        "Uma águia carrega um osso humano nas garras",
        "Rastros frescos na neve levam para o leste"
      ],
      "status": 0,
      "tags": ["exterior", "frio"],
      "notes": []
    }
  ],

  "pointsOfInterest": [
    {
      "id": "poi-001",
      "number": 1,
      "name": "Entrada da Tumba",
      "purpose": 3,
      "firstImpression": "Uma porta de pedra negra ornamentada com dragões entalhados. O frio é mais intenso aqui.",
      "obvious": "A porta está entreaberta. Marcas de arrombamento recentes.",
      "detail": "Atrás da porta há uma câmara com inscrições élficas: 'Aqui jaz Aerindel, Cavaleiro do Dragão Prateado. Que a paz o guarde para sempre.'",
      "connections": [2, 3],
      "treasure": "",
      "creatureIds": ["creature-002"],
      "locationId": "loc-001",
      "isVisited": false
    },
    {
      "id": "poi-002",
      "number": 2,
      "name": "Câmara dos Guardas",
      "purpose": 1,
      "firstImpression": "Esqueletos em armaduras élficas enfileirados nas paredes. Um cheiro de incenso podre.",
      "obvious": "Seis esqueletos estão de pé nas alcoves. Eles não se movem... ainda.",
      "detail": "Se uma tocha for acesa, os esqueletos despertam. Cada um carrega uma espada longa élfica (valor: 50 po cada).",
      "connections": [1, 4],
      "treasure": "6x espadas longas élficas (50 po cada), 1 escudo com brasão do clã",
      "creatureIds": ["creature-001"],
      "locationId": null,
      "isVisited": false
    },
    {
      "id": "poi-003",
      "number": 3,
      "name": "Câmara do Ritual",
      "purpose": 2,
      "firstImpression": "Símbolos arcanos no chão formam um pentáculo. Velas negras ainda queimam.",
      "obvious": "O ritual está pela metade. Um livro aberto no centro do pentáculo.",
      "detail": "O livro é o grimório do mago rival. Quem o ler completo recebe uma maldição (save Con CD 15 ou -2 em saves de magia por 1 semana). Solução: destruir o livro ou completar o ritual ao contrário.",
      "connections": [1, 5],
      "treasure": "Grimório amaldiçoado (500 po para o culto, 200 po para mercadores)",
      "creatureIds": ["creature-003"],
      "locationId": null,
      "isVisited": false
    },
    {
      "id": "poi-004",
      "number": 4,
      "name": "Câmara do Descanso",
      "purpose": 0,
      "firstImpression": "Uma sala pequena com catres de pedra. Curiosamente limpa.",
      "obvious": "Uma fonte ainda jorra água limpa de uma estátua de dragão.",
      "detail": "A água tem propriedades curativas — beber restaura 1d6 PV. A fonte esgota após 3 usos.",
      "connections": [2],
      "treasure": "Fonte curativa (3 usos: 1d6 PV cada)",
      "creatureIds": [],
      "locationId": null,
      "isVisited": false
    },
    {
      "id": "poi-005",
      "number": 5,
      "name": "Câmara Final — Sarcófago",
      "purpose": 3,
      "firstImpression": "Um sarcófago de mármore branco no centro. Gravuras de batalhas cobrem as paredes.",
      "obvious": "O sarcófago está fechado com um lacre mágico luminoso. Vozes sussurram em élfico.",
      "detail": "O cavaleiro ainda dorme. Se o ritual em #3 for completado pelo culto, ele desperta como morto-vivo poderoso (Cavaleiro Dracolich). Se os PJs impedirem o ritual, ele pode ser acordado em paz e agradece com sua espada lendária.",
      "connections": [3],
      "treasure": "Espada do Cavaleiro Dragão (artefato lendário, ver itens)",
      "creatureIds": ["creature-004"],
      "locationId": null,
      "isVisited": false
    }
  ],

  "creatures": [
    {
      "id": "creature-001",
      "name": "Esqueleto Guarda Élfico",
      "type": 0,
      "description": "Esqueletos em armaduras élficas deterioradas, animados por magia necromântica antiga.",
      "motivation": "Proteger a tumba de invasores",
      "losingBehavior": "Recua para o centro da câmara e tenta alertar os outros",
      "locationIds": ["loc-001"],
      "stats": "CA: 13  HP: 13  ATK: +4 Espada Longa 1d8+2\nImune a veneno, encantamentos\nVulnerável a dano radiante",
      "roleplayNotes": "",
      "conversationTopics": [],
      "status": 0,
      "disposition": 2,
      "tags": ["morto-vivo", "guarda"],
      "notes": []
    },
    {
      "id": "creature-002",
      "name": "Irmão Valdric",
      "type": 1,
      "description": "Cultista jovem e nervoso, designado para guardar a entrada. Usa manto negro com símbolo de caveira alada.",
      "motivation": "Provar seu valor ao culto completando o ritual",
      "losingBehavior": "Se acuado, suplica por misericórdia e oferece informações sobre o culto em troca de sua vida",
      "locationIds": [],
      "stats": "CA: 11  HP: 9  ATK: +2 Adaga 1d4\nFeitiços: Infligir Ferimentos (1/dia)",
      "roleplayNotes": "Fala rápido quando nervoso. Chama o líder de 'Mestra Seravyn'. Não sabe o paradeiro do grimório.",
      "conversationTopics": [
        "A Mestra Seravyn está dentro completando o ritual",
        "Há seis esqueletos ativos na câmara dos guardas",
        "O culto tem mais oito membros esperando no acampamento ao norte"
      ],
      "status": 0,
      "disposition": 2,
      "tags": ["cultista", "informante"],
      "notes": []
    },
    {
      "id": "creature-003",
      "name": "Mestra Seravyn",
      "type": 1,
      "description": "Sacerdotisa do culto da morte, determinada e fria. Cabelos brancos, olhos violeta.",
      "motivation": "Despertar o Cavaleiro Dragão como arma suprema do culto",
      "losingBehavior": "Usa Toque do Vampiro para se curar e foge pelo corredor secreto em #5 se reduzida a menos de 10 HP",
      "locationIds": [],
      "stats": "CA: 13 (armadura de couro)  HP: 52  ATK: +5 Cajado 1d8+3\nFeitiços: Animação dos Mortos, Raio Necrôtico 3d8, Toque do Vampiro\nSalvaguardas: For+1 Des+3 Con+2 Int+4 Sab+6 Car+3",
      "roleplayNotes": "Não negocia. Trata os PJs como obstáculos menores. Monologará sobre a inevitabilidade da morte se tiver tempo.",
      "conversationTopics": [],
      "status": 0,
      "disposition": 2,
      "tags": ["chefe", "necromante"],
      "notes": ["Corredor secreto atrás do altar em #3 — Percepção CD 18"]
    },
    {
      "id": "creature-004",
      "name": "Aerindel, Cavaleiro Dragão",
      "type": 1,
      "description": "Um guerreiro élfico imponente em armadura de dragão. Dorme há séculos. Pode ser aliado ou inimigo.",
      "motivation": "Descansar em paz — ou, se despertado pelo culto, obedecer ao ritual de morte",
      "losingBehavior": "Nunca recua (morto-vivo) / Se aliado e reduzido a 0 PV, desfaz-se em luz prateada",
      "locationIds": [],
      "stats": "CA: 20 (armadura de placas de dragão)  HP: 190\nATK: +10 Espada do Cavaleiro 2d8+7 (radiante)\nHabilidades: Resistência Lendária 3/dia, Aura de Medo CD 15\n[VERSÃO ALIADA] HP: 190  Ajuda os PJs por 1 hora depois de acordado",
      "roleplayNotes": "Se acordado em paz (ritual destruído): fala em élfico arcaico, agradece com a espada e desaparece. Se despertado pelo culto: hostil, implacável.",
      "conversationTopics": [
        "Seu dragão prateado Mirathis ainda vive nas montanhas do sul",
        "O sigilo no caixão aponta para uma segunda tumba a leste"
      ],
      "status": 0,
      "disposition": 3,
      "tags": ["chefe-final", "élfico", "lendário"],
      "notes": []
    }
  ],

  "quests": [
    {
      "id": "quest-001",
      "name": "Impedir o Ritual",
      "description": "O culto da morte está a horas de completar um ritual que despertará o Cavaleiro Dragão como morto-vivo. Os PJs devem chegar a tempo.",
      "status": 0,
      "giverCreatureId": null,
      "objectives": [
        { "text": "Encontrar a entrada da tumba", "isComplete": false },
        { "text": "Derrotar ou neutralizar a Mestra Seravyn", "isComplete": false },
        { "text": "Destruir ou reverter o ritual na Câmara #3", "isComplete": false }
      ],
      "rewardDescription": "400 XP + gratidão da família Aerindel (contato nobre para aventuras futuras)",
      "relatedLocationIds": ["loc-001"],
      "tags": ["urgente", "principal"],
      "notes": []
    },
    {
      "id": "quest-002",
      "name": "Recuperar os Restos de Aerindel",
      "description": "A família nobre Aerindel contratou os PJs para garantir que os restos do ancestral não sejam profanados.",
      "status": 1,
      "giverCreatureId": null,
      "objectives": [
        { "text": "Verificar o estado do sarcófago", "isComplete": false },
        { "text": "Retornar com prova de que o cavaleiro descansa em paz", "isComplete": false }
      ],
      "rewardDescription": "300 po + Anel de Proteção +1 da família Aerindel",
      "relatedLocationIds": [],
      "tags": ["secundária", "nobre"],
      "notes": []
    }
  ],

  "facts": [
    {
      "id": "fact-001",
      "content": "O culto tem oito membros adicionais acampados ao norte da montanha.",
      "sourceId": "creature-002",
      "isSecret": false,
      "revealed": false,
      "tags": ["culto", "ameaça"],
      "createdAt": "2026-01-01T00:00:00.000Z"
    },
    {
      "id": "fact-002",
      "content": "Há um corredor secreto atrás do altar na Câmara do Ritual (Percepção CD 18).",
      "sourceId": "creature-003",
      "isSecret": true,
      "revealed": false,
      "tags": ["segredo", "saída"],
      "createdAt": "2026-01-01T00:00:00.000Z"
    },
    {
      "id": "fact-003",
      "content": "O dragão prateado Mirathis, companheiro de Aerindel, ainda vive nas montanhas do sul.",
      "sourceId": "creature-004",
      "isSecret": true,
      "revealed": false,
      "tags": ["lore", "próxima-aventura"],
      "createdAt": "2026-01-01T00:00:00.000Z"
    }
  ],

  "items": [
    {
      "id": "item-001",
      "name": "Espada do Cavaleiro Dragão",
      "description": "Uma espada longa élfica com a empunhadura em forma de dragão. Brilha com luz prateada suave.",
      "type": 4,
      "mechanics": "Arma mágica +2. Causa +2d6 de dano radiante contra mortos-vivos. Uma vez por dia pode lançar Luz do Dia (nível 3). Senciente: INT 14, SAB 12, CAR 18. Fala élfico arcaico.",
      "rarity": 4,
      "ownerCreatureId": "creature-004",
      "locationId": null,
      "tags": ["arma", "senciente", "anti-morto-vivo"],
      "notes": []
    },
    {
      "id": "item-002",
      "name": "Grimório Amaldiçoado de Seravyn",
      "description": "Um livro encadernado em couro negro com símbolos necromânticos. Emite frio ao toque.",
      "type": 3,
      "mechanics": "Contém 3 feitiços de necromancia (Animação dos Mortos, Raio Necrôtico, Toque do Vampiro). Maldição: ler completo causa -2 em saves de magia por 1 semana (save Con CD 15 para resistir).",
      "rarity": 2,
      "ownerCreatureId": "creature-003",
      "locationId": null,
      "tags": ["grimório", "maldição"],
      "notes": ["Vale 500 po para o culto, 200 po para mercadores comuns"]
    }
  ],

  "factions": [
    {
      "id": "faction-001",
      "name": "Culto da Morte Alada",
      "description": "Seita necromântica que acredita que os mortos poderosos devem servir aos vivos como guardiões eternos.",
      "type": 1,
      "memberCount": 12,
      "powerLevel": 1,
      "partyDisposition": -2,
      "leaderCreatureId": "creature-003",
      "memberCreatureIds": ["creature-002"],
      "objectives": [
        { "text": "Completar o ritual de despertar na tumba", "currentProgress": 3, "maxProgress": 5, "trigger": "Ritual completado" }
      ],
      "allies": ["Necromante de Ravenhollow"],
      "enemies": ["Família Aerindel", "Igreja de Lathander"],
      "cast": [],
      "stakes": "Se bem-sucedidos, terão um exército de mortos-vivos lendários. Isso ameaçaria toda a região.",
      "dangers": [
        { "name": "Exército reforçado", "drive": "Conquistar a região", "imminentDisaster": "Atacam a cidade mais próxima em 3 dias", "omens": ["Mortos são encontrados reanimados nos arredores", "Cartas criptografadas interceptadas"] }
      ]
    }
  ],

  "legends": [
    {
      "id": "legend-001",
      "text": "Dizem que quem empunhar a Espada do Cavaleiro Dragão sem ser digno enlouquecerá em três dias.",
      "isTrue": false,
      "source": "Estalajadeiro de Pedra Fria",
      "diceResult": "",
      "relatedCreatureId": null,
      "relatedLocationId": null
    },
    {
      "id": "legend-002",
      "text": "O dragão prateado Mirathis prometeu destruir qualquer um que profanasse a tumba de seu cavaleiro.",
      "isTrue": true,
      "source": "Manuscrito élfico no vilarejo",
      "diceResult": "",
      "relatedCreatureId": "creature-004",
      "relatedLocationId": "loc-001"
    }
  ],

  "randomEvents": [
    {
      "id": "event-001",
      "diceRange": "11-33",
      "eventType": 0,
      "description": "Patrulha de 1d4 cultistas vasculhando a área",
      "impact": "Se os PJs forem vistos, o culto é alertado e Seravyn acelera o ritual"
    },
    {
      "id": "event-002",
      "diceRange": "34-55",
      "eventType": 1,
      "description": "Queda de neve intensa — visibilidade reduzida a 3m",
      "impact": "Desvantagem em testes de Percepção no exterior por 1 hora"
    },
    {
      "id": "event-003",
      "diceRange": "56-65",
      "eventType": 2,
      "description": "Cânticos necromânticos ecoando das profundezas da tumba",
      "impact": "Os PJs sabem que o ritual está em andamento. Senso de urgência."
    },
    {
      "id": "event-004",
      "diceRange": "66-100",
      "eventType": 3,
      "description": "Silêncio absoluto. Nem o vento sopra.",
      "impact": "Atmosfera tensa mas sem ação imediata"
    }
  ],

  "quickRules": [
    {
      "title": "Vantagem & Desvantagem",
      "category": "Mecânicas Básicas",
      "order": 0,
      "content": "Vantagem: role 2d20, use o maior. Desvantagem: role 2d20, use o menor. Vantagem e desvantagem se cancelam, independentemente de quantas fontes de cada você tenha."
    },
    {
      "title": "Ações em Combate",
      "category": "Combate",
      "order": 0,
      "content": "Cada turno: 1 Ação + 1 Ação Bônus (se disponível) + 1 Reação (fora do turno) + Movimento livre até sua velocidade. Ações comuns: Atacar, Conjurar Feitiço, Dash (dobra movimento), Desviar, Ajudar, Esconder, Usar Objeto."
    },
    {
      "title": "Morte e Estabilização",
      "category": "Combate",
      "order": 1,
      "content": "A 0 PV: inconsciente, faça Testes de Morte (CD 10). 3 sucessos = estável. 3 falhas = morte. Crítico a 0 PV conta como 2 falhas. Recuperar qualquer PV cancela os contadores."
    },
    {
      "title": "Descanso Curto",
      "category": "Recuperação",
      "order": 0,
      "content": "1 hora de descanso leve. Permite gastar Dados de Vida: role o dado + mod. Constituição e recupere esse total em PV. Algumas habilidades de classe recarregam no descanso curto."
    },
    {
      "title": "Descanso Longo",
      "category": "Recuperação",
      "order": 1,
      "content": "8 horas (mínimo 6h de sono). Recupera todos os PV e metade dos Dados de Vida gastos. Recarrega magias, habilidades e recursos de classe. Apenas 1 por 24 horas."
    }
  ],

  "sessions": []
}
''';

  // ---------------------------------------------------------------------------
  // Validation & stats
  // ---------------------------------------------------------------------------

  /// Returns true if [bundle] has the minimum required structure.
  static bool isValidBundle(Map<String, dynamic> bundle) {
    final adv = bundle['adventure'];
    return adv is Map<String, dynamic> && (adv['name'] is String);
  }

  /// Returns entity counts per type for display in the confirmation step.
  static Map<String, int> countEntities(Map<String, dynamic> bundle) {
    int n(String key) {
      final v = bundle[key];
      return v is List ? v.length : 0;
    }

    return {
      'creatures': n('creatures'),
      'locations': n('locations'),
      'pointsOfInterest': n('pointsOfInterest'),
      'quests': n('quests'),
      'facts': n('facts'),
      'items': n('items'),
      'factions': n('factions'),
      'legends': n('legends'),
      'randomEvents': n('randomEvents'),
      'sessions': n('sessions'),
      'quickRules': n('quickRules'),
    };
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  Future<Adventure> importBundle(
    Map<String, dynamic> bundle, {
    String? targetCampaignId,
  }) async {
    final advRaw =
        Map<String, dynamic>.from(bundle['adventure'] as Map<String, dynamic>);
    final oldAdvId = advRaw['id'] as String? ?? _uuid.v4();
    final newAdvId = _uuid.v4();
    final now = DateTime.now();

    // Parse all entity lists -----------------------------------------------
    List<Map<String, dynamic>> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final locations    = parseList(bundle['locations']);
    final pois         = parseList(bundle['pointsOfInterest']);
    final creatures    = parseList(bundle['creatures']);
    final quests       = parseList(bundle['quests']);
    final facts        = parseList(bundle['facts']);
    final items        = parseList(bundle['items']);
    final factions     = parseList(bundle['factions']);
    final legends      = parseList(bundle['legends']);
    final randomEvents = parseList(bundle['randomEvents']);
    final sessions     = parseList(bundle['sessions']);
    final quickRules   = parseList(bundle['quickRules']);

    // Build idMap: old key → new UUID.
    // Entities without an "id" field get an auto-generated positional key so
    // they still receive a fresh UUID even if the JSON omitted IDs entirely.
    final idMap = <String, String>{oldAdvId: newAdvId};
    int autoIdx = 0;
    for (final list in [
      locations, pois, creatures, quests, facts, items,
      factions, legends, randomEvents, sessions, quickRules,
    ]) {
      for (final e in list) {
        var id = e['id'] as String?;
        if (id == null || id.isEmpty) {
          id = '__auto_${autoIdx++}__';
          e['id'] = id; // write back so patchAdventure finds it
        }
        if (!idMap.containsKey(id)) {
          idMap[id] = _uuid.v4();
        }
      }
    }

    // Helpers ---------------------------------------------------------------
    String remap(String id) => idMap[id] ?? id;
    dynamic remapN(dynamic id) =>
        (id is String && id.isNotEmpty) ? remap(id) : null;
    List<String> remapL(dynamic list) =>
        (list is List) ? list.map((id) => remap(id.toString())).toList() : [];

    final effectiveCampaignId = targetCampaignId ??
        (advRaw['campaignId'] as String?) ??
        newAdvId;

    // Patch helper for adventure-scoped entities ----------------------------
    Map<String, dynamic> patchAdventure(Map<String, dynamic> e) {
      final m = Map<String, dynamic>.from(e);
      final oldId = m['id'] as String?;
      m['id'] = oldId != null ? (idMap[oldId] ?? _uuid.v4()) : _uuid.v4();
      m['adventureId'] = newAdvId;
      m['campaignId'] = effectiveCampaignId;
      return m;
    }

    // ---- Adventure --------------------------------------------------------
    advRaw['id'] = newAdvId;
    advRaw['campaignId'] = targetCampaignId; // null keeps it standalone
    advRaw['dungeonMapPath'] = null;
    advRaw['createdAt'] = now.toIso8601String();
    advRaw['updatedAt'] = now.toIso8601String();
    advRaw['isComplete'] = false;
    advRaw['locationNotes'] = <String, dynamic>{};
    advRaw['sessionNotes'] = advRaw['sessionNotes'] ?? '';
    final newAdventure = Adventure.fromJson(advRaw);
    await _db.saveAdventure(newAdventure);

    // ---- Locations --------------------------------------------------------
    for (final raw in locations) {
      final m = patchAdventure(raw);
      m['imagePath'] = null;
      if (m['parentLocationId'] != null) {
        m['parentLocationId'] = remapN(m['parentLocationId']);
      }
      m['creatureIds'] = remapL(m['creatureIds']);
      await _db.saveLocation(Location.fromJson(m));
    }

    // ---- Creatures --------------------------------------------------------
    for (final raw in creatures) {
      final m = patchAdventure(raw);
      m['imagePath'] = null;
      m['locationIds'] = remapL(m['locationIds']);
      if (m['currentLocationId'] != null) {
        m['currentLocationId'] = remapN(m['currentLocationId']);
      }
      await _db.saveCreature(Creature.fromJson(m));
    }

    // ---- Points of Interest -----------------------------------------------
    for (final raw in pois) {
      final m = patchAdventure(raw);
      m['imagePath'] = null;
      m['creatureIds'] = remapL(m['creatureIds']);
      if (m['locationId'] != null) {
        m['locationId'] = remapN(m['locationId']);
      }
      m['isVisited'] = false;
      await _db.savePointOfInterest(PointOfInterest.fromJson(m));
    }

    // ---- Quests -----------------------------------------------------------
    for (final raw in quests) {
      final m = patchAdventure(raw);
      if (m['giverCreatureId'] != null) {
        m['giverCreatureId'] = remapN(m['giverCreatureId']);
      }
      m['relatedLocationIds'] = remapL(m['relatedLocationIds']);
      await _db.saveQuest(Quest.fromJson(m));
    }

    // ---- Facts ------------------------------------------------------------
    for (final raw in facts) {
      final m = patchAdventure(raw);
      if (m['sourceId'] != null) m['sourceId'] = remapN(m['sourceId']);
      m['revealed'] = false;
      m['revealedAt'] = null;
      m['createdAt'] = now.toIso8601String();
      await _db.saveFact(Fact.fromJson(m));
    }

    // ---- Items ------------------------------------------------------------
    for (final raw in items) {
      final m = patchAdventure(raw);
      if (m['ownerCreatureId'] != null) {
        m['ownerCreatureId'] = remapN(m['ownerCreatureId']);
      }
      if (m['locationId'] != null) {
        m['locationId'] = remapN(m['locationId']);
      }
      await _db.saveItem(Item.fromJson(m));
    }

    // ---- Factions ---------------------------------------------------------
    for (final raw in factions) {
      final m = patchAdventure(raw);
      if (m['leaderCreatureId'] != null) {
        m['leaderCreatureId'] = remapN(m['leaderCreatureId']);
      }
      m['memberCreatureIds'] = remapL(m['memberCreatureIds']);
      await _db.saveFaction(Faction.fromJson(m));
    }

    // ---- Legends ----------------------------------------------------------
    for (final raw in legends) {
      final m = patchAdventure(raw);
      if (m['relatedCreatureId'] != null) {
        m['relatedCreatureId'] = remapN(m['relatedCreatureId']);
      }
      if (m['relatedLocationId'] != null) {
        m['relatedLocationId'] = remapN(m['relatedLocationId']);
      }
      await _db.saveLegend(Legend.fromJson(m));
    }

    // ---- Random Events ----------------------------------------------------
    for (final raw in randomEvents) {
      final m = patchAdventure(raw);
      await _db.saveRandomEvent(RandomEvent.fromJson(m));
    }

    // ---- Sessions (adventure-scoped, no campaignId) -----------------------
    for (final raw in sessions) {
      final m = Map<String, dynamic>.from(raw);
      final oldId = m['id'] as String?;
      m['id'] = oldId != null ? (idMap[oldId] ?? _uuid.v4()) : _uuid.v4();
      m['adventureId'] = newAdvId;
      await _db.saveSession(Session.fromJson(m));
    }

    // ---- Quick Rules (campaign-scoped — only imported when a campaign is
    //      selected; rules without a campaign have nowhere to live) ----------
    if (targetCampaignId != null && quickRules.isNotEmpty) {
      for (final raw in quickRules) {
        final m = Map<String, dynamic>.from(raw);
        final oldId = m['id'] as String?;
        m['id'] = oldId != null ? (idMap[oldId] ?? _uuid.v4()) : _uuid.v4();
        m['campaignId'] = targetCampaignId;
        await _db.saveQuickRule(QuickRule.fromJson(m));
      }
    }

    // ---- Link to campaign if requested ------------------------------------
    if (targetCampaignId != null) {
      final campaign = _db.getCampaign(targetCampaignId);
      if (campaign != null) {
        final updatedIds = List<String>.from(campaign.adventureIds)
          ..add(newAdvId);
        await _db.saveCampaign(
          campaign.copyWith(adventureIds: updatedIds, updatedAt: now),
        );
      }
    }

    return newAdventure;
  }
}
