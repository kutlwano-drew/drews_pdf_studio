import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfSanitizeService {
  Future<Uint8List> sanitize(Uint8List bytes) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.editOnce(
      PdfEngine.instance.input(bytes), sink,
    ).sanitize(stripAttachments: true);
    return sink.takeBytes();
  }

  Future<Uint8List> flattenForms(Uint8List bytes) => _flatten(bytes, forms: true);
  Future<Uint8List> flattenAnnotations(Uint8List bytes) => _flatten(bytes, forms: false);

  Future<Uint8List> _flatten(Uint8List bytes, {required bool forms}) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) => forms ? editor.flattenForms() : editor.flattenAnnotations(),
    );
    return sink.takeBytes();
  }
}
