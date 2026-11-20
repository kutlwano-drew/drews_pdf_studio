import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfRedactionService {
  Future<Uint8List> redact(Uint8List bytes, int page, List<PdfRect> regions) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) async { await editor.redact(page, regions); },
    );
    return sink.takeBytes();
  }
}
