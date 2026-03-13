import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Session timer state
// ---------------------------------------------------------------------------

class SessionTimerState {
  /// Real-world elapsed seconds since session start
  final int elapsedSeconds;
  /// In-game minutes that have passed
  final int inGameMinutes;
  /// Whether the timer is running
  final bool isRunning;
  /// In-game time increment per step (in minutes)
  final int incrementMinutes;
  /// Number of exploration turns (each increment counts as a turn)
  final int explorationTurns;

  const SessionTimerState({
    this.elapsedSeconds = 0,
    this.inGameMinutes = 0,
    this.isRunning = false,
    this.incrementMinutes = 10,
    this.explorationTurns = 0,
  });

  SessionTimerState copyWith({
    int? elapsedSeconds,
    int? inGameMinutes,
    bool? isRunning,
    int? incrementMinutes,
    int? explorationTurns,
  }) {
    return SessionTimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      inGameMinutes: inGameMinutes ?? this.inGameMinutes,
      isRunning: isRunning ?? this.isRunning,
      incrementMinutes: incrementMinutes ?? this.incrementMinutes,
      explorationTurns: explorationTurns ?? this.explorationTurns,
    );
  }

  String get elapsedFormatted {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get inGameFormatted {
    final days = inGameMinutes ~/ 1440;
    final hours = (inGameMinutes % 1440) ~/ 60;
    final mins = inGameMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0 || days > 0) parts.add('${hours}h');
    parts.add('${mins}min');
    return parts.join(' ');
  }

  /// Rough time-of-day based on in-game minutes (assuming start at dawn ~6:00)
  String get timeOfDay {
    final hourOfDay = ((inGameMinutes ~/ 60) + 6) % 24; // start at 6 AM
    if (hourOfDay >= 6 && hourOfDay < 12) return 'Manhã';
    if (hourOfDay >= 12 && hourOfDay < 14) return 'Meio-dia';
    if (hourOfDay >= 14 && hourOfDay < 18) return 'Tarde';
    if (hourOfDay >= 18 && hourOfDay < 21) return 'Entardecer';
    return 'Noite';
  }

  IconData get timeOfDayIcon {
    final hourOfDay = ((inGameMinutes ~/ 60) + 6) % 24;
    if (hourOfDay >= 6 && hourOfDay < 18) return Icons.wb_sunny;
    if (hourOfDay >= 18 && hourOfDay < 21) return Icons.wb_twilight;
    return Icons.nightlight_round;
  }

  Color get timeOfDayColor {
    final hourOfDay = ((inGameMinutes ~/ 60) + 6) % 24;
    if (hourOfDay >= 6 && hourOfDay < 12) return AppTheme.secondary;
    if (hourOfDay >= 12 && hourOfDay < 18) return AppTheme.warning;
    if (hourOfDay >= 18 && hourOfDay < 21) return Colors.orange.shade800;
    return AppTheme.info;
  }
}

class SessionTimerNotifier extends Notifier<SessionTimerState> {
  Timer? _timer;

  @override
  SessionTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SessionTimerState();
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void toggle() {
    if (state.isRunning) {
      pause();
    } else {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    state = const SessionTimerState();
  }

  void advanceInGameTime([int? customMinutes]) {
    final mins = customMinutes ?? state.incrementMinutes;
    state = state.copyWith(
      inGameMinutes: state.inGameMinutes + mins,
      explorationTurns: state.explorationTurns + 1,
    );
  }

  void setInGameMinutes(int minutes) {
    state = state.copyWith(inGameMinutes: minutes);
  }

  void setIncrement(int minutes) {
    state = state.copyWith(incrementMinutes: minutes);
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerNotifier, SessionTimerState>(
  SessionTimerNotifier.new,
);

// ---------------------------------------------------------------------------
// Timer panel widget
// ---------------------------------------------------------------------------

class SessionTimerPanel extends ConsumerWidget {
  const SessionTimerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sessionTimerProvider);
    final notifier = ref.read(sessionTimerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.timer, size: 16, color: AppTheme.info),
              SizedBox(width: 8),
              Text(
                'Timer de Sessão',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Real time row
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    const Text(
                      'Tempo real:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      timer.elapsedFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play/pause
                    InkWell(
                      onTap: () => notifier.toggle(),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          timer.isRunning ? Icons.pause : Icons.play_arrow,
                          size: 18,
                          color: timer.isRunning ? AppTheme.warning : AppTheme.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => notifier.reset(),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.restart_alt, size: 16, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 12),

                // In-game time row
                Row(
                  children: [
                    Icon(timer.timeOfDayIcon, size: 14, color: timer.timeOfDayColor),
                    const SizedBox(width: 6),
                    Text(
                      'In-game: ${timer.timeOfDay}',
                      style: TextStyle(fontSize: 11, color: timer.timeOfDayColor),
                    ),
                    const Spacer(),
                    Text(
                      timer.inGameFormatted,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: timer.timeOfDayColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // In-game time controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TimeChip(
                      label: '10min',
                      selected: timer.incrementMinutes == 10,
                      onTap: () => notifier.setIncrement(10),
                    ),
                    _TimeChip(
                      label: '30min',
                      selected: timer.incrementMinutes == 30,
                      onTap: () => notifier.setIncrement(30),
                    ),
                    _TimeChip(
                      label: '1h',
                      selected: timer.incrementMinutes == 60,
                      onTap: () => notifier.setIncrement(60),
                    ),
                    _TimeChip(
                      label: '8h',
                      selected: timer.incrementMinutes == 480,
                      onTap: () => notifier.setIncrement(480),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => notifier.advanceInGameTime(),
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(
                        '+${_formatIncrement(timer.incrementMinutes)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Turno ${timer.explorationTurns}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),
        const Divider(height: 1),
      ],
    );
  }

  String _formatIncrement(int minutes) {
    if (minutes >= 60) return '${minutes ~/ 60}h';
    return '${minutes}min';
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.info.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? AppTheme.info
                  : AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppTheme.info : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
