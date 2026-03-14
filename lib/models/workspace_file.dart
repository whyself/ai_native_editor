import 'package:flutter/foundation.dart';

@immutable
class WorkspaceFile {
  final String path;
  final String name;

  const WorkspaceFile({required this.path, required this.name});

  factory WorkspaceFile.fromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return WorkspaceFile(path: path, name: name);
  }

  Map<String, dynamic> toJson() => {'path': path};

  factory WorkspaceFile.fromJson(Map<String, dynamic> json) =>
      WorkspaceFile.fromPath(json['path'] as String);

  @override
  bool operator ==(Object other) => other is WorkspaceFile && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
