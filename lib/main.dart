import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/workspace_provider.dart';
import 'widgets/split_view.dart';
import 'widgets/sidebar.dart';

void main() {
  runApp(const ProviderScope(child: AINativeEditorApp()));
}

class AINativeEditorApp extends StatelessWidget {
  const AINativeEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Native Freeform Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const EditorWorkspace(),
    );
  }
}

/// 主工作区页面：侧边栏 + 分区面板
class EditorWorkspace extends ConsumerWidget {
  const EditorWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);

    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          const Sidebar(),
          // 主工作区: 递归渲染分区树
          Expanded(
            child: SplitView(node: workspace.rootNode),
          ),
        ],
      ),
    );
  }
}
