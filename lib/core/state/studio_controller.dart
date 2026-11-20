import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../services/files/pdf_file_service.dart';
import '../../services/pdf/pdf_document_service.dart';
import '../../services/pdf/pdf_engine.dart';
import '../models/pdf_document_asset.dart';

class StudioController extends ChangeNotifier {
  final PdfFileService files = PdfFileService();
  final PdfDocumentService documents = PdfDocumentService();

  PdfDocumentAsset? currentDocument;
  final List<PdfDocumentAsset> recentDocuments = [];

  Uint8List? workingBytes;
  String? workingName;
  int? workingPageCount;

  final List<Uint8List?> _undoStack = [];
  final List<Uint8List?> _redoStack = [];
  static const int _historyLimit = 25;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void cancelCurrentTask() {
    PdfEngine.instance.cancelActiveTasks();
  }

  bool isBusy = false;
  String? statusMessage;
  String? errorMessage;

  Uint8List? get activeDocumentBytes => workingBytes ?? currentDocument?.bytes;
  bool get hasWorkingCopy => workingBytes != null;


  void closeDocument() {
    currentDocument = null;
    workingBytes = null;
    workingName = null;
    workingPageCount = null;
    _undoStack.clear();
    _redoStack.clear();
    statusMessage = 'Document closed';
    errorMessage = null;
    notifyListeners();
  }

  Future<void> openPdf() async {
    errorMessage = null;
    notifyListeners();
    try {
      final picked = await files.pickPdf();
      if (picked == null) return;
      await openBytes(picked.name, picked.bytes);
    } catch (error) {
      errorMessage = friendlyError(error, action: 'open this PDF');
      notifyListeners();
    }
  }

  Future<void> openBytes(String name, Uint8List bytes) async {
    await runTask('Opening document…', () async {
      int? pageCount;
      try {
        pageCount = await documents.pageCount(bytes);
      } catch (_) {
        pageCount = null;
      }
      workingBytes = null;
      workingName = null;
      workingPageCount = null;
      _undoStack.clear();
      _redoStack.clear();
      final asset = PdfDocumentAsset(
        name: name,
        bytes: bytes,
        pageCount: pageCount,
      );
      currentDocument = asset;
      recentDocuments.removeWhere((item) => item.name == name);
      recentDocuments.insert(0, asset);
      statusMessage = 'Opened $name';
    });
  }

  Future<void> setWorkingCopy(
    List<int> bytes, {
    String? name,
  }) async {
    final copy = Uint8List.fromList(bytes);
    int? count;
    try {
      count = await documents.pageCount(copy);
    } catch (_) {
      count = null;
    }
    if (workingBytes == null || workingBytes!.hashCode != copy.hashCode) {
      _undoStack.add(workingBytes == null ? null : Uint8List.fromList(workingBytes!));
      if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
      _redoStack.clear();
    }
    workingBytes = copy;
    workingName = name ?? workingName ?? currentDocument?.name ?? 'document.pdf';
    workingPageCount = count;
    if (!isBusy) statusMessage = 'Preview updated';
    notifyListeners();
  }

  void clearWorkingCopy() {
    _undoStack.clear();
    _redoStack.clear();
    workingBytes = null;
    workingName = null;
    workingPageCount = null;
    statusMessage = 'Unexported changes discarded';
    notifyListeners();
  }


  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    _redoStack.add(workingBytes == null ? null : Uint8List.fromList(workingBytes!));
    final previous = _undoStack.removeLast();
    await _restoreHistory(previous, 'Undo applied');
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    _undoStack.add(workingBytes == null ? null : Uint8List.fromList(workingBytes!));
    final next = _redoStack.removeLast();
    await _restoreHistory(next, 'Redo applied');
  }

  Future<void> _restoreHistory(Uint8List? bytes, String label) async {
    workingBytes = bytes == null ? null : Uint8List.fromList(bytes);
    workingName = bytes == null ? null : (workingName ?? currentDocument?.name ?? 'document.pdf');
    if (bytes == null) {
      workingPageCount = null;
    } else {
      try {
        workingPageCount = await documents.pageCount(bytes);
      } catch (_) {
        workingPageCount = null;
      }
    }
    statusMessage = label;
    notifyListeners();
  }

  Future<void> exportWorkingCopy() async {
    final bytes = workingBytes;
    if (bytes == null) {
      throw StateError('Apply an operation before exporting a PDF copy.');
    }
    final sourceName = workingName ?? currentDocument?.name ?? 'document.pdf';
    final baseName = sourceName.contains('.')
        ? sourceName.substring(0, sourceName.lastIndexOf('.'))
        : sourceName;
    await files.savePdf('${baseName}_edited_copy.pdf', bytes);
    statusMessage = 'Exported ${baseName}_edited_copy.pdf';
  }

  Future<void> saveCurrent() async {
    final current = currentDocument;
    if (current == null) return;
    await runTask('Saving PDF…', () => files.savePdf(current.name, current.bytes));
  }

  Future<void> replaceCurrent(Uint8List bytes, {String? name}) async {
    final current = currentDocument;
    if (current == null) return;
    int? count;
    try {
      count = await documents.pageCount(bytes);
    } catch (_) {
      count = null;
    }
    final updated = PdfDocumentAsset(
      name: name ?? current.name,
      bytes: bytes,
      pageCount: count,
      isModified: true,
    );
    currentDocument = updated;
    recentDocuments.removeWhere((item) => item.name == updated.name);
    recentDocuments.insert(0, updated);
    statusMessage = 'Document updated';
    notifyListeners();
  }

  Future<void> runTask(String label, Future<void> Function() task) async {
    isBusy = true;
    errorMessage = null;
    statusMessage = label;
    notifyListeners();
    try {
      await task();
    } catch (error) {
      final cleanLabel = label.replaceAll('…', '').trim().toLowerCase();
      final action = cleanLabel.startsWith('applying ')
          ? cleanLabel.substring('applying '.length)
          : cleanLabel.startsWith('exporting ')
              ? 'export ${cleanLabel.substring('exporting '.length)}'
              : cleanLabel.startsWith('saving ')
                  ? 'save ${cleanLabel.substring('saving '.length)}'
                  : cleanLabel.startsWith('opening ')
                      ? 'open ${cleanLabel.substring('opening '.length)}'
                      : cleanLabel;
      errorMessage = friendlyError(error, action: action);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String friendlyError(Object error, {String action = 'complete this operation'}) {
    if (error.toString().toLowerCase().contains('cancel')) {
      return 'The operation was cancelled. Your original PDF has been left unchanged.';
    }
    if (error is RangeError) {
      return 'One or more selected page numbers are outside this document. Check the page selection and try again.';
    }
    if (error is FormatException || error is ArgumentError) {
      return 'Some of the supplied options are invalid. Check the values and page numbers, then try again.';
    }
    if (error is StateError) {
      return error.message.toString();
    }

    final detail = error.toString().toLowerCase();
    if (detail.contains('password') || detail.contains('decrypt')) {
      return 'This PDF is password-protected or could not be unlocked. Check the password and try again.';
    }
    if (detail.contains('unsupported') || detail.contains('not supported')) {
      return 'This PDF contains a feature or format that this operation cannot process.';
    }
    if (detail.contains('permission') || detail.contains('denied')) {
      return 'The app does not have permission to access that file or location.';
    }
    if (detail.contains('corrupt') || detail.contains('invalid pdf')) {
      return 'The selected file does not appear to be a valid, readable PDF.';
    }
    return 'Drew’s PDF Studio could not $action. Your original PDF has been left unchanged. Try again or use a different PDF.';
  }

  void clearMessages() {
    errorMessage = null;
    statusMessage = null;
    notifyListeners();
  }
}
