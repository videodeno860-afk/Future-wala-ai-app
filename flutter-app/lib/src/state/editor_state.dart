import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_ai/src/models/screen_model.dart';
import 'package:future_ai/src/models/component_model.dart';

class EditorState {
  final ScreenModel screen;
  final String? selectedId;
  final List<ScreenModel> history;
  final int historyIndex;

  EditorState({required this.screen, this.selectedId, List<ScreenModel>? history, this.historyIndex = 0})
      : history = history ?? [screen];

  EditorState copyWith({ScreenModel? screen, String? selectedId, List<ScreenModel>? history, int? historyIndex}) {
    return EditorState(
      screen: screen ?? this.screen,
      selectedId: selectedId ?? this.selectedId,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier(ScreenModel screen) : super(EditorState(screen: screen));

  void select(String? id) {
    state = state.copyWith(selectedId: id);
  }

  void addComponent(ComponentModel c) {
    final newScreen = ScreenModel(id: state.screen.id, name: state.screen.name, components: [...state.screen.components, c]);
    _pushHistory(newScreen);
  }

  void updateComponent(ComponentModel c) {
    final list = state.screen.components.map((e) => e.id == c.id ? c : e).toList();
    final newScreen = ScreenModel(id: state.screen.id, name: state.screen.name, components: list);
    _pushHistory(newScreen);
  }

  void removeComponent(String id) {
    final list = state.screen.components.where((e) => e.id != id).toList();
    final newScreen = ScreenModel(id: state.screen.id, name: state.screen.name, components: list);
    _pushHistory(newScreen);
    select(null);
  }

  void _pushHistory(ScreenModel newScreen) {
    final newHistory = [...state.history.sublist(0, state.historyIndex + 1), newScreen];
    state = state.copyWith(screen: newScreen, history: newHistory, historyIndex: newHistory.length - 1);
  }

  bool canUndo() => state.historyIndex > 0;
  bool canRedo() => state.historyIndex < state.history.length - 1;

  void undo() {
    if (!canUndo()) return;
    final idx = state.historyIndex - 1;
    state = state.copyWith(screen: state.history[idx], historyIndex: idx);
  }

  void redo() {
    if (!canRedo()) return;
    final idx = state.historyIndex + 1;
    state = state.copyWith(screen: state.history[idx], historyIndex: idx);
  }
}
