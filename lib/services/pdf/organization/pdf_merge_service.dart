import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfMergeService {
  Future<Uint8List> merge(List<Uint8List> documents) async {
    if (documents.length < 2) throw ArgumentError('Select at least two PDFs.');
    final sink = MemorySink();
    await PdfEngine.instance.pdf.merge(
      documents.map((bytes) => PdfInput(MemorySource(bytes))).toList(),
      sink,
    );
    return sink.takeBytes();
  }
}
