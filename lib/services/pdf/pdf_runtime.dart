import 'dart:typed_data';

import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_engine.dart';

class PdfRuntime {
  PdfRuntime._();

  static final PdfRuntime instance = PdfRuntime._();

  final Pdf engine = PdfEngine.instance.pdf;

  PdfInput input(Uint8List bytes, {String? password}) =>
      PdfInput(MemorySource(bytes), password: password);

  Future<Uint8List> rewrite(
    Uint8List bytes,
    Future<void> Function(PdfEditor editor) operation, {
    String? password,
  }) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      input(bytes, password: password),
      sink,
      operation,
    );
    return sink.takeBytes();
  }

  Future<Uint8List> output(
    Future<void> Function(MemorySink sink) operation,
  ) async {
    final sink = MemorySink();
    await operation(sink);
    return sink.takeBytes();
  }

  Future<T> read<T>(
    Uint8List bytes,
    Future<T> Function(PdfDocument document) operation, {
    String? password,
  }) =>
      engine.read(
        input(bytes, password: password),
        operation,
      );
}
