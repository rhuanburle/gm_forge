import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/domain.dart';
import 'adventure_providers.dart';

final sessionExportServiceProvider = Provider<SessionExportService>((ref) {
  return SessionExportService(ref);
});

class SessionExportService {
  final Ref _ref;

  SessionExportService(this._ref);

  Future<void> copySessionLogToClipboard(String adventureId) async {
    final adventure = _ref.read(adventureProvider(adventureId));
    if (adventure == null) return;

    final entries = _ref.read(sessionEntriesProvider(adventureId));
    // Sort ascending for chronological output
    final sortedEntries = List<SessionEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buffer = StringBuffer();
    buffer.writeln('# Resumo da Sessão: ${adventure.name}');
    buffer.writeln();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    String? currentTurn;

    for (final entry in sortedEntries) {
      if (entry.turnLabel != currentTurn &&
          entry.turnLabel != null &&
          entry.turnLabel!.isNotEmpty) {
        currentTurn = entry.turnLabel;
        buffer.writeln('## [$currentTurn]');
      }

      final time = dateFormat.format(entry.timestamp);
      final text = _cleanSmartText(entry.text);
      buffer.writeln('- ${entry.entryType.icon} $text ($time)');
    }

    if (adventure.sessionNotes != null && adventure.sessionNotes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Notas Antigas');
      buffer.writeln(adventure.sessionNotes);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  String _cleanSmartText(String text) {
    // Remove the smart text markup like [#Location Name] -> Location Name
    // or [@Creature Name] -> Creature Name
    var cleaned = text.replaceAllMapped(
      RegExp(r'\[@(.*?)\]'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[#(.*?)\]'),
      (match) => match.group(1) ?? '',
    );
    return cleaned;
  }
}
