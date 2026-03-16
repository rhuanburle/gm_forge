import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/smart_network_image.dart';
import '../../application/publish_service.dart';
import '../../domain/public_page.dart';

class PublicCampaignPage extends StatefulWidget {
  final String shareId;

  const PublicCampaignPage({super.key, required this.shareId});

  @override
  State<PublicCampaignPage> createState() => _PublicCampaignPageState();
}

class _PublicCampaignPageState extends State<PublicCampaignPage> {
  PublicPage? _page;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      final page = await PublishService.fetchPublicPage(widget.shareId);
      if (mounted) {
        setState(() {
          _page = page;
          _loading = false;
          if (page == null) _error = 'Página não encontrada ou desativada.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erro ao carregar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _page == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(_error ?? 'Página não encontrada.'),
            ],
          ),
        ),
      );
    }

    final page = _page!;
    return Scaffold(
      appBar: AppBar(
        title: Text(page.campaignName),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'GM Forge',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: _tabCount(page),
        child: Column(
          children: [
            if (page.campaignDescription.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: AppTheme.primary.withValues(alpha: 0.05),
                child: Text(
                  page.campaignDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            TabBar(
              isScrollable: true,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: _buildTabs(page),
            ),
            Expanded(
              child: TabBarView(
                children: _buildTabViews(page),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _tabCount(PublicPage page) {
    int count = 0;
    if (page.sessions.isNotEmpty) count++;
    if (page.playerCharacters.isNotEmpty) count++;
    if (page.quests.isNotEmpty) count++;
    if (page.npcs.isNotEmpty) count++;
    if (page.facts.isNotEmpty) count++;
    return count == 0 ? 1 : count; // at least 1 tab
  }

  List<Tab> _buildTabs(PublicPage page) {
    final tabs = <Tab>[];
    if (page.sessions.isNotEmpty) tabs.add(const Tab(text: 'Historia'));
    if (page.playerCharacters.isNotEmpty) tabs.add(const Tab(text: 'Grupo'));
    if (page.quests.isNotEmpty) tabs.add(const Tab(text: 'Missoes'));
    if (page.npcs.isNotEmpty) tabs.add(const Tab(text: 'NPCs'));
    if (page.facts.isNotEmpty) tabs.add(const Tab(text: 'Descobertas'));
    if (tabs.isEmpty) tabs.add(const Tab(text: 'Campanha'));
    return tabs;
  }

  List<Widget> _buildTabViews(PublicPage page) {
    final views = <Widget>[];

    if (page.sessions.isNotEmpty) views.add(_buildSessionsView(page.sessions));
    if (page.playerCharacters.isNotEmpty) views.add(_buildPartyView(page.playerCharacters));
    if (page.quests.isNotEmpty) views.add(_buildQuestsView(page.quests));
    if (page.npcs.isNotEmpty) views.add(_buildNpcsView(page.npcs));
    if (page.facts.isNotEmpty) views.add(_buildFactsView(page.facts));

    if (views.isEmpty) {
      views.add(const Center(
        child: Text('O mestre ainda não publicou conteúdo.'),
      ));
    }

    return views;
  }

  // --- Sessions / Story ---
  Widget _buildSessionsView(List<PublicSession> sessions) {
    final sorted = List<PublicSession>.from(sessions)
      ..sort((a, b) => b.number.compareTo(a.number));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final session = sorted[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sessao #${session.number}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      session.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (session.recap.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    session.recap,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Party ---
  Widget _buildPartyView(List<PublicPlayerCharacter> pcs) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image or placeholder
              Expanded(
                flex: 3,
                child: (pc.imageUrl ?? '').isNotEmpty
                    ? SmartNetworkImage(
                        imageUrl: pc.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: AppTheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
              ),
              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pc.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pc.playerName.isNotEmpty)
                        Text(
                          'Jogador: ${pc.playerName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (pc.characterClass.isNotEmpty)
                        Text(
                          '${pc.characterClass} Nv. ${pc.level}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (pc.species.isNotEmpty)
                        Text(
                          pc.species,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Quests ---
  Widget _buildQuestsView(List<PublicQuest> quests) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final isComplete = quest.status == 'Concluída';
        final isFailed = quest.status == 'Falhada';
        final statusColor = isComplete
            ? AppTheme.success
            : isFailed
                ? AppTheme.error
                : AppTheme.info;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isComplete
                          ? Icons.check_circle
                          : isFailed
                              ? Icons.cancel
                              : Icons.assignment,
                      color: statusColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quest.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        quest.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (quest.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(quest.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (quest.objectives.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...quest.objectives.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          o.isComplete
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: o.isComplete
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            o.text,
                            style: TextStyle(
                              decoration: o.isComplete
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: o.isComplete ? AppTheme.textMuted : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NPCs ---
  Widget _buildNpcsView(List<PublicCreature> npcs) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: npcs.length,
      itemBuilder: (context, index) {
        final npc = npcs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: (npc.imageUrl ?? '').isNotEmpty
                ? ClipOval(
                    child: SmartNetworkImage(
                      imageUrl: npc.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.npc.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AppTheme.npc),
                  ),
            title: Text(npc.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: npc.description.isNotEmpty
                ? Text(npc.description, maxLines: 3,
                    overflow: TextOverflow.ellipsis)
                : null,
          ),
        );
      },
    );
  }

  // --- Discovered Facts ---
  Widget _buildFactsView(List<PublicFact> facts) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: facts.length,
      itemBuilder: (context, index) {
        final fact = facts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: AppTheme.discovery),
            title: Text(fact.content, style: const TextStyle(fontSize: 14)),
            subtitle: fact.sourceName.isNotEmpty
                ? Text(fact.sourceName,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))
                : null,
          ),
        );
      },
    );
  }
}
