import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfFormEditService {
  PdfFormEditService._();
  static final instance = PdfFormEditService._();
  final _runtime = PdfRuntime.instance;

  Future<Uint8List> flattenForms(Uint8List bytes) =>
      _runtime.rewrite(bytes, (editor) => editor.flattenForms());

  Future<Uint8List> flattenAnnotations(Uint8List bytes) =>
      _runtime.rewrite(bytes, (editor) => editor.flattenAnnotations());

  Future<Uint8List> fillMultiChoiceField(Uint8List bytes, {required String fieldName, required List<String> values}) =>
      _runtime.rewrite(bytes, (editor) => editor.field(fieldName).setValue(PdfFormFieldValue.choices(values)));

  Future<Uint8List> fillTextField(Uint8List bytes, {required String fieldName, required String value}) =>
      _runtime.rewrite(bytes, (editor) => editor.field(fieldName).setValue(PdfFormFieldValue.text(value)));

  Future<Uint8List> fillCheckboxField(Uint8List bytes, {required String fieldName, required bool checked}) =>
      _runtime.rewrite(bytes, (editor) => editor.field(fieldName).setValue(PdfFormFieldValue.checked(checked)));

  Future<Uint8List> fillChoiceField(Uint8List bytes, {required String fieldName, required String value}) =>
      _runtime.rewrite(bytes, (editor) => editor.field(fieldName).setValue(PdfFormFieldValue.choice(value)));
}
