import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfStandardsService {
  PdfStandardsService._();
  static final instance = PdfStandardsService._();
  final _runtime = PdfRuntime.instance;

  Future<dynamic> validatePdfA(Uint8List bytes) =>
      _runtime.read(bytes, (document) => document.validatePdfA());

  Future<dynamic> validatePdfUa(Uint8List bytes) =>
      _runtime.read(bytes, (document) => document.validatePdfUa());

  Future<Uint8List> convertToPdfA(Uint8List bytes) => _runtime.rewrite(
        bytes,
        (editor) => editor.convertToPdfA(),
      );
}
