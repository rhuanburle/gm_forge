import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks if there are local changes that haven't been synced to the cloud.
final unsyncedChangesProvider = StateProvider<bool>((ref) => false);
