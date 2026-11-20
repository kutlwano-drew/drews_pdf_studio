import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfOfficeConversionService {
  Future<Uint8List> toOffice(Uint8List bytes, PdfOfficeFormat format) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.convertToOffice(
      PdfEngine.instance.input(bytes), sink, format: format,
    );
    return sink.takeBytes();
  }

  Future<Uint8List> fromOffice(Uint8List bytes, PdfOfficeFormat format) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.convertFromOffice(
      MemorySource(bytes), sink, format: format,
    );
    return sink.takeBytes();
  }
}
