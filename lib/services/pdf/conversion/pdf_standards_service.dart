import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfStandardsService {
  Future<dynamic> validatePdfA(List<int> bytes) => PdfEngine.instance.pdf.read(
    PdfEngine.instance.input(bytes), (document) => document.validatePdfA(),
  );

  Future<dynamic> validatePdfUa(List<int> bytes) => PdfEngine.instance.pdf.read(
    PdfEngine.instance.input(bytes), (document) => document.validatePdfUa(),
  );

  Future<Uint8List> convertToPdfA(Uint8List bytes) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) => editor.convertToPdfA(),
    );
    return sink.takeBytes();
  }
}
