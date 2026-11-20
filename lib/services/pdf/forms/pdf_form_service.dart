import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfFormService {
  Future<dynamic> fields(List<int> bytes) => PdfEngine.instance.pdf.read(
    PdfEngine.instance.input(bytes), (document) => document.formFields(),
  );

  Future<dynamic> xfa(List<int> bytes) => PdfEngine.instance.pdf.read(
    PdfEngine.instance.input(bytes), (document) => document.xfa(),
  );

  Future<Uint8List> setTextField(Uint8List bytes, String name, String value) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes), sink,
      (editor) => editor.field(name).setValue(PdfFormFieldValue.text(value)),
    );
    return sink.takeBytes();
  }

  Future<Uint8List> convertXfa(Uint8List bytes) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.convertXfaToAcroForm(
      PdfEngine.instance.input(bytes), sink,
    );
    return sink.takeBytes();
  }
}
