import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfAttachmentService {
  Future<Uint8List> add(Uint8List bytes, String name, Uint8List attachment) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) => editor.addAttachment(name, MemorySource(attachment)),
    );
    return sink.takeBytes();
  }

  Future<Uint8List> extract(List<int> bytes, String name) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.read(
      PdfEngine.instance.input(bytes), (document) => document.extractAttachment(name, sink),
    );
    return sink.takeBytes();
  }
}
