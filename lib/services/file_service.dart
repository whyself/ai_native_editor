import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  /// Extract text from a PDF file using Syncfusion PDF.
  /// Returns up to [maxChars] characters of extracted text.
  Future<String?> extractPdfText(String path, {int maxChars = 50000}) async {
    try {
      final bytes = await File(path).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final pageCount = doc.pages.count;
      final extractor = PdfTextExtractor(doc);
      final text = extractor.extractText();
      doc.dispose();

      if (text.trim().isEmpty) {
        return '[PDF 文件（共 $pageCount 页）无法提取文字内容（可能为扫描版 PDF）]';
      }
      if (text.length > maxChars) {
        return '${text.substring(0, maxChars)}\n\n[PDF 内容已截断，仅显示前 $maxChars 字]';
      }
      return text;
    } catch (e) {
      return '[PDF 文字提取失败：$e]';
    }
  }
}
