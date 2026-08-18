import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import 'sync_service.dart';
import 'unsynced_changes_provider.dart';

/// Debounced autosave to the cloud.
///
/// Local Hive writes are already immediate, so data is never lost locally.
/// This wrapper watches [unsyncedChangesProvider] and, a few seconds after the
/// last edit, pushes changes to Firestore — removing the need to click the
/// cloud button. It only pushes (never pulls); the full pull stays on login and
/// the manual sync button.
class AutoSyncScope extends ConsumerStatefulWidget {
  final Widget child;

  const AutoSyncScope({super.key, required this.child});

  @override
  ConsumerState<AutoSyncScope> createState() => _AutoSyncScopeState();
}

class _AutoSyncScopeState extends ConsumerState<AutoSyncScope> {
  static const _baseDelay = Duration(seconds: 3);
  static const _maxDelaySeconds = 180; // cap the backoff at 3 minutes

  Timer? _timer;
  bool _running = false;
  int _failures = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Debounce on the happy path; exponential backoff once pushes start failing,
  /// so a durable error (bad doc, permission, offline) can't turn into a 3s
  /// loop that re-uploads the whole library forever.
  void _schedule() {
    _timer?.cancel();
    final delay = _failures == 0
        ? _baseDelay
        : Duration(
            seconds: math.min(_maxDelaySeconds, 3 * (1 << _failures)),
          );
    _timer = Timer(delay, _run);
  }

  Future<void> _run() async {
    if (_running) {
      // A push is in flight; retry shortly so we catch edits made meanwhile.
      _schedule();
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) return; // nothing to push to

    if (!ref.read(unsyncedChangesProvider)) return;

    _running = true;
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    // Optimistic: clear the flag before pushing so edits during the push
    // re-arm it and get picked up on the next cycle.
    ref.read(unsyncedChangesProvider.notifier).state = false;
    try {
      await ref.read(syncServiceProvider).pushAll();
      if (!mounted) return;
      _failures = 0;
      ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
    } catch (_) {
      if (!mounted) return;
      // Keep the change pending and surface the error. Re-arming the flag
      // reschedules via the listener, but _failures now stretches the delay
      // (6s, 12s, … up to 3 min) instead of hammering every 3s.
      _failures++;
      ref.read(unsyncedChangesProvider.notifier).state = true;
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(unsyncedChangesProvider, (prev, next) {
      if (next) _schedule();
    });
    return widget.child;
  }
}
