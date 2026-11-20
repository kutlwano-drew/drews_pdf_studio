import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'models/pdf_document_item.dart';
import '../services/files/pdf_file_service.dart';
import '../services/pdf/pdf_conversion_service.dart';
import '../services/pdf/pdf_creation_service.dart';
import '../services/pdf/pdf_edit_service.dart';
import '../services/pdf/pdf_organize_service.dart';
import '../services/pdf/pdf_read_service.dart';
import '../services/pdf/pdf_security_service.dart';
import '../services/pdf/pdf_standards_service.dart';

part 'controller/app_controller_files.dart';
part 'controller/app_controller_edits.dart';
part 'controller/app_controller_tasks.dart';

class AppController extends ChangeNotifier {
  final files = PdfFileService();
  PdfDocumentItem? currentDocument;
  final List<PdfDocumentItem> recentDocuments = [];
  bool busy = false;
  String? status;
  String? error;
  String? extractedText;

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> _edit(String label, Future<Uint8List> Function(Uint8List) operation) async {
    final document = currentDocument;
    if (document == null) return;
    await _run(label, () async {
      final bytes = await operation(document.bytes);
      await _replaceCurrent(document.name, bytes);
    });
  }

  Future<void> _replaceCurrent(String name, Uint8List bytes) async {
    final info = await PdfReadService.instance.inspect(bytes);
    final updated = PdfDocumentItem(
      name: name,
      bytes: bytes,
      pageCount: info['pageCount'] as int?,
      modified: true,
    );
    currentDocument = updated;
    recentDocuments.removeWhere((doc) => doc.name == name);
    recentDocuments.insert(0, updated);
    status = 'Updated $name';
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    busy = true;
    status = label;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (exception) {
      error = exception.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _baseName(String name) => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
  String _outputName(String name) => '${_baseName(name)}_edited.pdf';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
