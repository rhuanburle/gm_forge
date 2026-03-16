import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether there are local changes not yet pushed to Firestore.
///
/// Set to `true` whenever a local save happens (any entity).
/// Set to `false` after a successful fullSync().
final unsyncedChangesProvider = StateProvider<bool>((ref) => false);

/// Convenience extension so widgets can call:
///   ref.markUnsynced()
extension UnsyncedRef on Ref {
  void markUnsynced() {
    read(unsyncedChangesProvider.notifier).state = true;
  }
}

extension UnsyncedWidgetRef on WidgetRef {
  void markUnsynced() {
    read(unsyncedChangesProvider.notifier).state = true;
  }
}
