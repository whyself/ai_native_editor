import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_file.dart';
import '../services/persistence_service.dart';

class WorkspaceNotifier extends Notifier<List<WorkspaceFile>> {
  @override
  List<WorkspaceFile> build() {
    // Restore from last session
    final saved = PersistenceService.instance.loadWorkspace();
    if (saved != null) {
      return saved.map(WorkspaceFile.fromPath).toList();
    }
    return [];
  }

  void _persist() {
    PersistenceService.instance
        .saveWorkspace(state.map((f) => f.path).toList());
  }

  void addFiles(List<String> paths) {
    final newFiles = paths
        .map(WorkspaceFile.fromPath)
        .where((f) => !state.any((e) => e.path == f.path))
        .toList();
    if (newFiles.isNotEmpty) {
      state = [...state, ...newFiles];
      _persist();
    }
  }

  void removeFile(String path) {
    state = state.where((f) => f.path != path).toList();
    _persist();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _persist();
  }

  void clearAll() {
    state = [];
    _persist();
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, List<WorkspaceFile>>(
  WorkspaceNotifier.new,
);
