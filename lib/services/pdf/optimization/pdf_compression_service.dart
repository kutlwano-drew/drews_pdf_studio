import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfCompressionService {
  Future<Uint8List> compress(Uint8List bytes, PdfImagePolicy policy) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.compress(
      PdfEngine.instance.input(bytes), sink, images: policy,
    );
    return sink.takeBytes();
  }

  Future<Uint8List> unembedFonts(Uint8List bytes) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) async { await editor.unembedStandardFonts(); },
    );
    return sink.takeBytes();
  }
}
