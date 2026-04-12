import 'package:uuid/uuid.dart';

enum PlotThreadStatus { active, dormant, resolved }

extension PlotThreadStatusExtension on PlotThreadStatus {
  String get displayName {
    switch (this) {
      case PlotThreadStatus.active:
        return 'Ativo';
      case PlotThreadStatus.dormant:
        return 'Dormente';
      case PlotThreadStatus.resolved:
        return 'Resolvido';
    }
  }

}

class PlotThread {
  final String id;
  final String title;
  final String description;
  final PlotThreadStatus status;
  final String? linkedQuestId;

  const PlotThread({
    required this.id,
    required this.title,
    this.description = '',
    this.status = PlotThreadStatus.active,
    this.linkedQuestId,
  });

  factory PlotThread.create({
    required String title,
    String description = '',
    String? linkedQuestId,
  }) {
    return PlotThread(
      id: const Uuid().v4(),
      title: title,
      description: description,
      linkedQuestId: linkedQuestId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.index,
    'linkedQuestId': linkedQuestId,
  };

  factory PlotThread.fromJson(Map<String, dynamic> json) => PlotThread(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    status: PlotThreadStatus.values[json['status'] as int? ?? 0],
    linkedQuestId: json['linkedQuestId'] as String?,
  );

  PlotThread copyWith({
    String? title,
    String? description,
    PlotThreadStatus? status,
    String? linkedQuestId,
    bool clearLinkedQuest = false,
  }) {
    return PlotThread(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      linkedQuestId: clearLinkedQuest ? null : (linkedQuestId ?? this.linkedQuestId),
    );
  }
}

class InspirationTable {
  final String id;
  final String name;
  final List<String> entries;

  const InspirationTable({
    required this.id,
    required this.name,
    this.entries = const [],
  });

  factory InspirationTable.create({
    required String name,
    List<String> entries = const [],
  }) {
    return InspirationTable(
      id: const Uuid().v4(),
      name: name,
      entries: entries,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'entries': entries,
  };

  factory InspirationTable.fromJson(Map<String, dynamic> json) =>
      InspirationTable(
        id: json['id'] as String,
        name: json['name'] as String,
        entries:
            (json['entries'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  InspirationTable copyWith({
    String? name,
    List<String>? entries,
  }) {
    return InspirationTable(
      id: id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
    );
  }

  static List<InspirationTable> defaults() => [
    InspirationTable.create(
      name: 'Cenas de Atmosfera',
      entries: [
        'Nuvens escuras se acumulam ao norte com trovões distantes',
        'Borboletas coloridas pousam brevemente no ombro de um personagem',
        'Coro de sapos ecoa de uma poça próxima',
        'Brisa traz cheiro de pinheiro e terra molhada',
        'Pássaros circulam em grupo coordenado no céu',
        'Redemoinho de folhas secas dança à frente do grupo',
        'Flores silvestres desabrocham ao toque do sol',
        'Coruja solitária pia em plena luz do dia',
        'Chuva fina cria círculos nas poças d\'água',
        'Pássaros coloridos saltam de galho em galho, curiosos',
        'Insetos luminosos brilham conforme o crepúsculo se aproxima',
        'Vento forte faz árvores se curvarem como sussurrando segredos',
        'Capim alto ondula como um oceano verde',
        'Névoa azulada cobre montanhas distantes ao amanhecer',
        'Rebanho de cervos corre no horizonte',
        'Corvo pousa perto, grasna profundamente e voa embora',
        'Borboleta gigante e colorida paira no ar, reluzente',
        'Arco-íris aparece no horizonte após chuva rápida',
        'Flores noturnas abrem lentamente em um campo',
        'Nuvens formam padrões como símbolos antigos',
      ],
    ),
    InspirationTable.create(
      name: 'NPC Relâmpago',
      entries: [
        'Cicatriz no queixo, impaciente, quer vender algo rápido',
        'Cabelo grisalho, fala baixo, procura um parente perdido',
        'Manca da perna esquerda, alegre, coleciona moedas estrangeiras',
        'Olhos de cores diferentes, desconfiado, foge de uma dívida',
        'Mãos enormes, gentil, quer aprender a ler',
        'Sempre mastigando algo, nervoso, esconde um segredo do patrão',
        'Tatuagem tribal no braço, orgulhoso, busca honra em combate',
        'Voz rouca, melancólico, lamenta uma decisão passada',
        'Sorriso largo, trapaceiro, vende informações falsas',
        'Corcunda leve, sábio, conhece histórias antigas da região',
        'Jovem demais pro cargo, determinado, quer provar seu valor',
        'Cheira a ervas, curioso, estuda criaturas estranhas',
        'Olhar distante, profético, fala em metáforas confusas',
        'Forte como um touro, tímido, apaixonado em segredo',
        'Elegante mas sujo, decadente, perdeu tudo no jogo',
      ],
    ),
    InspirationTable.create(
      name: 'Complicações',
      entries: [
        'Um aliado trai o grupo no pior momento possível',
        'O objetivo está protegido por alguém que o grupo respeita',
        'Há um prazo — se não resolverem até o anoitecer, piora',
        'Duas facções rivais querem a mesma coisa que o grupo',
        'A informação que tinham estava errada desde o início',
        'Um inocente será prejudicado se o grupo agir diretamente',
        'O vilão oferece um acordo tentador e razoável',
        'Um desastre natural (enchente, terremoto, incêndio) interrompe tudo',
        'O verdadeiro inimigo é alguém que o grupo já ajudou antes',
        'Completar o objetivo criará um problema maior no futuro',
        'Um membro importante está doente/envenenado/amaldiçoado',
        'O caminho mais rápido passa por território proibido',
      ],
    ),
    InspirationTable.create(
      name: 'Descrição de Sala',
      entries: [
        'Câmara circular com teto abobadado — eco amplifica sussurros',
        'Corredor estreito com paredes úmidas — musgo bioluminescente brilha fracamente',
        'Salão amplo com pilares quebrados — algo se move nas sombras do teto',
        'Sala pequena com mesa de pedra ao centro — marcas de garras no chão',
        'Passagem natural em rocha — gotejamento constante forma estalactites',
        'Biblioteca abandonada — livros mofados, um está aberto numa página específica',
        'Forja apagada — ferramentas enferrujadas, mas o carvão ainda está quente',
        'Sala com piso de mosaico — algumas peças foram arrancadas revelando um compartimento',
        'Câmara com poço seco ao centro — corrente enferrujada desce na escuridão',
        'Sala com teia de aranha gigante cobrindo uma passagem — algo brilha do outro lado',
      ],
    ),
  ];
}

class Campaign {
  final String id;
  final String name;
  final String description;
  final String centralConflict;
  final String currentArc;
  final int currentDay;
  final List<PlotThread> plotThreads;
  final List<InspirationTable> inspirationTables;

  final List<String> adventureIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Campaign({
    required this.id,
    required this.name,
    required this.description,
    this.centralConflict = '',
    this.currentArc = '',
    this.currentDay = 1,
    this.plotThreads = const [],
    this.inspirationTables = const [],
    this.adventureIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Campaign.create({required String name, required String description}) {
    return Campaign(
      id: const Uuid().v4(),
      name: name,
      description: description,
      inspirationTables: InspirationTable.defaults(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'centralConflict': centralConflict,
    'currentArc': currentArc,
    'currentDay': currentDay,
    'plotThreads': plotThreads.map((t) => t.toJson()).toList(),
    'inspirationTables': inspirationTables.map((t) => t.toJson()).toList(),
    'adventureIds': adventureIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    centralConflict: json['centralConflict'] as String? ?? '',
    currentArc: json['currentArc'] as String? ?? '',
    currentDay: json['currentDay'] as int? ?? 1,
    plotThreads: (json['plotThreads'] as List<dynamic>?)
            ?.map((t) => PlotThread.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
    inspirationTables: (json['inspirationTables'] as List<dynamic>?)
            ?.map((t) => InspirationTable.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
    adventureIds:
        (json['adventureIds'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Campaign copyWith({
    String? name,
    String? description,
    String? centralConflict,
    String? currentArc,
    int? currentDay,
    List<PlotThread>? plotThreads,
    List<InspirationTable>? inspirationTables,
    List<String>? adventureIds,
    DateTime? updatedAt,
  }) => Campaign(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    centralConflict: centralConflict ?? this.centralConflict,
    currentArc: currentArc ?? this.currentArc,
    currentDay: currentDay ?? this.currentDay,
    plotThreads: plotThreads ?? this.plotThreads,
    inspirationTables: inspirationTables ?? this.inspirationTables,
    adventureIds: adventureIds ?? this.adventureIds,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
