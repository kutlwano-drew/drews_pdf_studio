import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfImageService {
  Future<Uint8List> moveImage(
    Uint8List bytes, int page, String imageName, PdfRect bounds,
  ) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) => editor.setImageBounds(page, imageName, bounds),
    );
    return sink.takeBytes();
  }
}
