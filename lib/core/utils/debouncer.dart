import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  VoidCallback? _pendingAction;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _pendingAction = action;
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _pendingAction = null;
      action();
    });
  }

  /// Executes any pending action immediately and cancels the timer.
  /// Call this in dispose() to avoid losing unsaved changes.
  void flush() {
    if (_pendingAction != null) {
      _timer?.cancel();
      _timer = null;
      final action = _pendingAction!;
      _pendingAction = null;
      action();
    }
  }

  void dispose() {
    flush();
    _timer?.cancel();
  }
}
