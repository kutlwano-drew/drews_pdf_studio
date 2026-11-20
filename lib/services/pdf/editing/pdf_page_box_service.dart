import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfPageBoxService {
  Future<Uint8List> cropMargins(
    Uint8List bytes, {double left = 0, double right = 0, double top = 0, double bottom = 0}) =>
      _rewrite(bytes, (editor) => editor.cropMargins(
        left: left, right: right, top: top, bottom: bottom,
      ));

  Future<Uint8List> setCropBox(Uint8List bytes, PdfRect? box) =>
      _rewrite(bytes, (editor) => editor.setCropBox(box));

  Future<Uint8List> resize(Uint8List bytes, double width, double height) =>
      _rewrite(bytes, (editor) => editor.setMediaBox(
        PdfRect(x: 0, y: 0, width: width, height: height),
      ));

  Future<Uint8List> _rewrite(Uint8List bytes, Future<void> Function(PdfEditor) action) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(PdfEngine.instance.input(bytes), sink, action);
    return sink.takeBytes();
  }
}
