import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../../domain/domain.dart';

class SessionPrepPage extends ConsumerStatefulWidget {
  final String adventureId;
  final String? sessionId;

  const SessionPrepPage({super.key, required this.adventureId, this.sessionId});

  @override
  ConsumerState<SessionPrepPage> createState() => _SessionPrepPageState();
}

class _SessionPrepPageState extends ConsumerState<SessionPrepPage> {
  final _nameController = TextEditingController();
  final _strongStartController = TextEditingController();
  final _recapController = TextEditingController();
  final _numberController = TextEditingController(text: '1');

  DateTime _selectedDate = DateTime.now();
  SessionStatus _status = SessionStatus.prep;

  List<TextEditingController> _starsControllers = [];
  List<TextEditingController> _wishesControllers = [];

  String? _existingSessionId;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSession());
  }

  void _loadSession() {
    if (widget.sessionId != null) {
      final sessions = ref
          .read(hiveDatabaseProvider)
          .getSessions(widget.adventureId);
      final session = sessions
          .where((s) => s.id == widget.sessionId)
          .firstOrNull;
      if (session != null) {
        _existingSessionId = session.id;
        _nameController.text = session.name;
        _strongStartController.text = session.strongStart;
        _recapController.text = session.recap;
        _numberController.text = session.number.toString();
        _selectedDate = session.date;
        _status = session.status;

        _starsControllers = session.stars
            .map((s) => TextEditingController(text: s))
            .toList();
        _wishesControllers = session.wishes
            .map((s) => TextEditingController(text: s))
            .toList();

        setState(() => _isLoaded = true);
        return;
      }
    }
    setState(() => _isLoaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strongStartController.dispose();
    _recapController.dispose();
    _numberController.dispose();
    for (final c in _starsControllers) {
      c.dispose();
    }
    for (final c in _wishesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Session _buildSession() {
    final number = int.tryParse(_numberController.text) ?? 1;
    if (_existingSessionId != null) {
      return Session(
        id: _existingSessionId!,
        adventureId: widget.adventureId,
        name: _nameController.text.trim(),
        date: _selectedDate,
        status: _status,
        number: number,
        strongStart: _strongStartController.text.trim(),
        recap: _recapController.text.trim(),
        stars: _starsControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        wishes: _wishesControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );
    }
    return Session.create(
      adventureId: widget.adventureId,
      name: _nameController.text.trim(),
      date: _selectedDate,
      status: _status,
      number: number,
      strongStart: _strongStartController.text.trim(),
      recap: _recapController.text.trim(),
      stars: _starsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      wishes: _wishesControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );
  }

  Future<void> _saveSession() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da sessão é obrigatório.')),
      );
      return;
    }
    final session = _buildSession();
    _existingSessionId ??= session.id;
    await ref.read(hiveDatabaseProvider).saveSession(session);
    ref.invalidate(sessionsProvider(widget.adventureId));
    ref.read(unsyncedChangesProvider.notifier).state = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão salva com sucesso!')),
      );
    }
  }

  Future<void> _startSession() async {
    _status = SessionStatus.played;
    await _saveSession();
    if (mounted) {
      context.go('/adventure/play/${widget.adventureId}');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: SkeletonList(itemCount: 5, itemHeight: 72));
    }

    final sessionEntries = ref.watch(
      sessionEntriesProvider(widget.adventureId),
    );
    final filteredEntries = widget.sessionId != null
        ? sessionEntries.where((e) => e.sessionId == widget.sessionId).toList()
        : sessionEntries;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _existingSessionId != null ? 'Editar Sessão' : 'Nova Sessão',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Sessão'),
            onPressed: _startSession,
          ),
        ],
      ),
      body: screenSizeOf(context) == ScreenSize.compact
          ? _buildCompactBody(filteredEntries)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Lazy DM worksheet form
                Expanded(flex: 3, child: _buildWorksheetForm()),
                const VerticalDivider(width: 1),
                // Right column: Session log entries
                Expanded(flex: 2, child: _buildSessionLog(filteredEntries)),
              ],
            ),
    );
  }

  Widget _buildCompactBody(List<SessionEntry> entries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorksheetFormContent(),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Log da Sessao'),
            leading: const Icon(Icons.history),
            initiallyExpanded: false,
            children: [
              SizedBox(height: 400, child: _buildSessionLogContent(entries)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorksheetForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildWorksheetFormContent(),
    );
  }

  Widget _buildWorksheetFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session name
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome da Sessão',
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        const SizedBox(height: 12),

        // Date picker and Session number row
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  prefixIcon: Icon(Icons.tag),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status dropdown
        DropdownButtonFormField<SessionStatus>(
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(Icons.flag),
          ),
          items: SessionStatus.values.map((s) {
            return DropdownMenuItem(value: s, child: Text(s.displayName));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
        const SizedBox(height: 24),

        // Strong Start
        _buildSectionHeader('Início Forte', Icons.bolt),
        const SizedBox(height: 8),
        TextField(
          controller: _strongStartController,
          decoration: const InputDecoration(
            hintText: 'Descreva o início forte da sessão...',
          ),
          maxLines: 4,
          minLines: 2,
        ),
        const SizedBox(height: 24),

        // Recap
        _buildSectionHeader('Recapitulação', Icons.summarize),
        const SizedBox(height: 8),
        TextField(
          controller: _recapController,
          decoration: const InputDecoration(
            hintText: 'Resumo do que aconteceu na sessão...',
          ),
          maxLines: 4,
          minLines: 2,
        ),
        const SizedBox(height: 24),

        // Stars (what went well)
        _buildDynamicListSection(
          title: 'Estrelas (O que funcionou)',
          icon: Icons.star,
          controllers: _starsControllers,
          hintText: 'O que os jogadores gostaram...',
          onAdd: () =>
              setState(() => _starsControllers.add(TextEditingController())),
          onRemove: (index) => setState(() {
            _starsControllers[index].dispose();
            _starsControllers.removeAt(index);
          }),
        ),

        // Wishes (what players want more of)
        _buildDynamicListSection(
          title: 'Desejos (O que querem mais)',
          icon: Icons.auto_awesome,
          controllers: _wishesControllers,
          hintText: 'O que os jogadores querem mais...',
          onAdd: () =>
              setState(() => _wishesControllers.add(TextEditingController())),
          onRemove: (index) => setState(() {
            _wishesControllers[index].dispose();
            _wishesControllers.removeAt(index);
          }),
        ),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salvar Sessão'),
            onPressed: _saveSession,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
        ),
      ],
    );
  }

  Widget _buildDynamicListSection({
    required String title,
    required IconData icon,
    required List<TextEditingController> controllers,
    required String hintText,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon),
        const SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      hintText: hintText,
                      prefixText: '${index + 1}. ',
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppTheme.error,
                  ),
                  onPressed: () => onRemove(index),
                  tooltip: 'Remover',
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
            onPressed: onAdd,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSessionLog(List<SessionEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Registro da Sessão',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildSessionLogContent(entries)),
      ],
    );
  }

  Widget _buildSessionLogContent(List<SessionEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma entrada registrada.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          dense: true,
          leading: _entryTypeIcon(entry.entryType),
          title: Text(entry.text, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')} - ${entry.entryType.displayName}',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        );
      },
    );
  }

  Widget _entryTypeIcon(SessionEntryType type) {
    switch (type) {
      case SessionEntryType.combat:
        return const Icon(
          Icons.local_fire_department,
          color: AppTheme.error,
          size: 20,
        );
      case SessionEntryType.discovery:
        return const Icon(Icons.explore, color: AppTheme.secondary, size: 20);
      case SessionEntryType.narrative:
        return const Icon(
          Icons.auto_stories,
          color: AppTheme.primary,
          size: 20,
        );
      case SessionEntryType.note:
        return const Icon(Icons.edit_note, color: AppTheme.textMuted, size: 20);
    }
  }
}
