import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfPageEditService {
  PdfPageEditService._();
  static final instance = PdfPageEditService._();
  final _runtime = PdfRuntime.instance;

  Future<Uint8List> cropMargins(Uint8List bytes, {double top = 0, double bottom = 0, double left = 0, double right = 0}) =>
      _runtime.rewrite(bytes, (editor) => editor.cropMargins(top: top, bottom: bottom, left: left, right: right));

  Future<Uint8List> setCropBox(Uint8List bytes, {required double x, required double y, required double width, required double height}) =>
      _runtime.rewrite(bytes, (editor) => editor.setCropBox(PdfRect(x: x, y: y, width: width, height: height)));

  Future<Uint8List> resizePages(Uint8List bytes, {required double width, required double height}) =>
      _runtime.rewrite(bytes, (editor) => editor.setMediaBox(PdfRect(x: 0, y: 0, width: width, height: height)));

  Future<List<dynamic>> pageImages(Uint8List bytes, int page) async {
    final editor = await _runtime.engine.edit(_runtime.input(bytes));
    try {
      return await editor.pageImages(page - 1);
    } finally {
      await editor.dispose();
    }
  }

  Future<Uint8List> moveOrResizeImage(Uint8List bytes, {required int page, required String imageName, required double x, required double y, required double width, required double height}) =>
      _runtime.rewrite(bytes, (editor) => editor.setImageBounds(page - 1, imageName, PdfRect(x: x, y: y, width: width, height: height)));
}
