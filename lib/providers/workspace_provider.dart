import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace_file.dart';

class WorkspaceNotifier extends Notifier<List<WorkspaceFile>> {
  @override
  List<WorkspaceFile> build() => [];

  void addFiles(List<String> paths) {
    final newFiles = paths
        .map(WorkspaceFile.fromPath)
        .where((f) => !state.any((e) => e.path == f.path))
        .toList();
    if (newFiles.isNotEmpty) {
      state = [...state, ...newFiles];
    }
  }

  void removeFile(String path) {
    state = state.where((f) => f.path != path).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, List<WorkspaceFile>>(
  WorkspaceNotifier.new,
);
