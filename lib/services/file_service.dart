import 'dart:io';

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
      await File(path).writeAsString(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Read file as list of lines, truncated if file is very large.
  Future<String?> readFileSafe(String path, {int maxChars = 50000}) async {
    final content = await readFile(path);
    if (content == null) return null;
    if (content.length > maxChars) {
      return '${content.substring(0, maxChars)}\n\n[File truncated – showing first $maxChars characters]';
    }
    return content;
  }
}
