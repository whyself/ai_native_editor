import 'dart:io';
import 'package:flutter/foundation.dart' show compute;
import 'package:syncfusion_flutter_pdf/pdf.dart';

// ── Top-level functions required by compute() ────────────────────────────────

String _cleanPdfText(String raw) {
  final cleaned = raw.replaceAll(
    RegExp(
      r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F'
      r'\u00AD\u200B\u200C\u200D\u200E\u200F'
      r'\u2028\u2029\uFEFF\uFFF0-\uFFFF]',
    ),
    '',
  );
  final lines = cleaned.split('\n').map((l) => l.trimRight()).toList();
  final buffer = StringBuffer();
  int blankRun = 0;
  for (final line in lines) {
    if (line.isEmpty) {
      blankRun++;
      if (blankRun <= 1) buffer.writeln();
    } else {
      blankRun = 0;
      buffer.writeln(line);
    }
  }
  return buffer.toString().trim();
}

Future<String> _extractPdfIsolate(String path) async {
  final bytes = await File(path).readAsBytes();
  final doc = PdfDocument(inputBytes: bytes);
  final pageCount = doc.pages.count;
  final extractor = PdfTextExtractor(doc);
  final raw = extractor.extractText();
  doc.dispose();
  final text = _cleanPdfText(raw);
  if (text.isEmpty) {
    return '[PDF 文件（共 $pageCount 页）无法提取文字内容（可能为扫描版 PDF 或使用了嵌入字体）]';
  }
  return text;
}

// ── FileService ───────────────────────────────────────────────────────────────

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
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Read file as string for AI context (no truncation).
  Future<String?> readFileSafe(String path) async {
    return readFile(path);
  }

  /// Extract text from a PDF file in a background isolate (non-blocking).
  Future<String?> extractPdfText(String path) async {
    try {
      return await compute(_extractPdfIsolate, path);
    } catch (e) {
      return '[PDF 文字提取失败：$e]';
    }
  }
}
