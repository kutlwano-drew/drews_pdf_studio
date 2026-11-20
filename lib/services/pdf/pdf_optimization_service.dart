import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfOptimizationService {
  PdfOptimizationService._();
  static final instance = PdfOptimizationService._();
  final _runtime = PdfRuntime.instance;

  Future<Uint8List> compress(Uint8List bytes, {PdfImagePolicy policy = PdfImagePolicy.lossless}) =>
      _runtime.output((sink) => _runtime.engine.compress(_runtime.input(bytes), sink, images: policy));

  Future<Uint8List> reduceImages(Uint8List bytes, PdfImagePolicy policy) =>
      _runtime.rewrite(bytes, (editor) async { await editor.reduceImages(policy); });

  Future<Uint8List> unembedStandardFonts(Uint8List bytes) =>
      _runtime.rewrite(bytes, (editor) async { await editor.unembedStandardFonts(); });
}
