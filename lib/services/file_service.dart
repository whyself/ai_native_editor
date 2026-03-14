import 'dart:io';
import 'package:path/path.dart' as p;

class FileService {
  FileService._();
  static final FileService instance = FileService._();

  Future<String?> readFile(String path) async {
    try {
      return await File(path).readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeFile(String path, String content) async {
    try {
      final file = File(path);
      // Ensure parent directory exists (handles user-selected save dirs)
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Read file as string, truncated at [maxChars] for AI context.
  Future<String?> readFileSafe(String path, {int maxChars = 50000}) async {
    final content = await readFile(path);
    if (content == null) return null;
    if (content.length > maxChars) {
      return '${content.substring(0, maxChars)}\n\n[File truncated – showing first $maxChars characters]';
    }
    return content;
  }

  /// Returns a context placeholder for a PDF file.
  /// Native PDF text extraction is not supported in this build; the AI will
  /// know a PDF was attached and can ask the user to paste relevant content.
  Future<String?> extractPdfText(String path, {int maxChars = 50000}) async {
    final name = p.basename(path);
    return '[已添加 PDF 文件 "$name"。当前版本暂不支持 PDF 文字提取，如需 AI 分析内容，请手动粘贴相关段落到消息中。]';
  }
}
