import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfFormExportService {
  Future<Uint8List> export(List<int> bytes) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.read(
      PdfEngine.instance.input(bytes), (document) => document.exportFormData(sink),
    );
    return sink.takeBytes();
  }
}
