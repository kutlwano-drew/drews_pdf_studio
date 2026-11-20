import 'dart:typed_data';

import 'package:pdf_manipulator/pdf_manipulator.dart';

class PdfEngine {
  PdfEngine._();
  static final PdfEngine instance = PdfEngine._();
  final Pdf pdf = Pdf();
  final Set<dynamic> _activeTasks = {};

  PdfInput input(List<int> bytes, {String? password}) =>
      PdfInput(MemorySource(Uint8List.fromList(bytes)), password: password);

  MemorySink createSink() => MemorySink();

  Future<void> rewrite(
    PdfInput input,
    MemorySink sink,
    Future<void> Function(PdfEditor editor) operation,
  ) async {
    final task = pdf.rewrite(input, sink, operation);
    _activeTasks.add(task);
    try {
      await task;
    } finally {
      _activeTasks.remove(task);
    }
  }

  void cancelActiveTasks() {
    for (final task in _activeTasks.toList()) {
      task.cancel();
    }
  }
}
