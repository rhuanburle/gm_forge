import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryAction {
  final String description;
  final Future<void> Function() onUndo;
  final Future<void> Function() onRedo;

  const HistoryAction({
    required this.description,
    required this.onUndo,
    required this.onRedo,
  });
}

class HistoryState {
  final List<HistoryAction> undoStack;
  final List<HistoryAction> redoStack;

  const HistoryState({this.undoStack = const [], this.redoStack = const []});

  HistoryState copyWith({
    List<HistoryAction>? undoStack,
    List<HistoryAction>? redoStack,
  }) {
    return HistoryState(
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
}

class HistoryService extends Notifier<HistoryState> {
  static const int maxStackSize = 50;
  bool _isExecutingAction = false;

  @override
  HistoryState build() {
    return const HistoryState();
  }

  void recordAction(HistoryAction action) {
    // If an action is recorded while we are currently executing an undo or redo, ignore it.
    // Undo/Redo closures might trigger state saves themselves. We don't want them polluting the stack.
    if (_isExecutingAction) return;

    final newUndoStack = List<HistoryAction>.from(state.undoStack)..add(action);

    if (newUndoStack.length > maxStackSize) {
      newUndoStack.removeAt(0);
    }

    state = state.copyWith(
      undoStack: newUndoStack,
      redoStack: [], // Writing new history invalidates redo stack
    );
  }

  Future<void> undo() async {
    if (!state.canUndo || _isExecutingAction) return;

    _isExecutingAction = true;
    try {
      final undoList = List<HistoryAction>.from(state.undoStack);
      final action = undoList.removeLast();

      await action.onUndo();

      final newRedoStack = List<HistoryAction>.from(state.redoStack)
        ..add(action);
      state = state.copyWith(undoStack: undoList, redoStack: newRedoStack);
    } finally {
      _isExecutingAction = false;
    }
  }

  Future<void> redo() async {
    if (!state.canRedo || _isExecutingAction) return;

    _isExecutingAction = true;
    try {
      final redoList = List<HistoryAction>.from(state.redoStack);
      final action = redoList.removeLast();

      await action.onRedo();

      final newUndoStack = List<HistoryAction>.from(state.undoStack)
        ..add(action);
      state = state.copyWith(undoStack: newUndoStack, redoStack: redoList);
    } finally {
      _isExecutingAction = false;
    }
  }

  void clear() {
    state = const HistoryState();
  }
}

final historyProvider = NotifierProvider<HistoryService, HistoryState>(() {
  return HistoryService();
});
