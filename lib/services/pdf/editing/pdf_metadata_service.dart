import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfMetadataService {
  Future<Uint8List> update(Uint8List bytes, PdfMetadata metadata) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) => editor.setMetadata(metadata),
    );
    return sink.takeBytes();
  }
}
