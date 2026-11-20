import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

enum OfficeDocumentFormat { docx, pptx, xlsx }

class PdfConversionService {
  PdfConversionService._();
  static final instance = PdfConversionService._();
  final _runtime = PdfRuntime.instance;

  PdfOfficeFormat _format(OfficeDocumentFormat format) => switch (format) {
        OfficeDocumentFormat.docx => PdfOfficeFormat.docx,
        OfficeDocumentFormat.pptx => PdfOfficeFormat.pptx,
        OfficeDocumentFormat.xlsx => PdfOfficeFormat.xlsx,
      };

  Future<Uint8List> pdfToOffice(
    Uint8List bytes,
    OfficeDocumentFormat format,
  ) => _runtime.output((sink) => _runtime.engine.convertToOffice(
        _runtime.input(bytes),
        sink,
        format: _format(format),
      ));

  Future<Uint8List> officeToPdf(
    Uint8List bytes,
    OfficeDocumentFormat format,
  ) => _runtime.output((sink) => _runtime.engine.convertFromOffice(
        MemorySource(bytes),
        sink,
        format: _format(format),
      ));

  Future<Uint8List> xfaToAcroForm(Uint8List bytes) =>
      _runtime.output((sink) => _runtime.engine.convertXfaToAcroForm(
            _runtime.input(bytes),
            sink,
          ));
}
