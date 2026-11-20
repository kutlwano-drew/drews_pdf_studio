import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_form_edit_service.dart';
import 'pdf_marks_service.dart';
import 'pdf_optimization_service.dart';
import 'pdf_page_edit_service.dart';

class PdfEditService {
  PdfEditService._();
  static final instance = PdfEditService._();

  Future<Uint8List> compress(Uint8List bytes, {PdfImagePolicy policy = PdfImagePolicy.lossless}) =>
      PdfOptimizationService.instance.compress(bytes, policy: policy);
  Future<Uint8List> cropMargins(Uint8List bytes, {double top = 0, double bottom = 0, double left = 0, double right = 0}) =>
      PdfPageEditService.instance.cropMargins(bytes, top: top, bottom: bottom, left: left, right: right);
  Future<Uint8List> setCropBox(Uint8List bytes, {required double x, required double y, required double width, required double height}) =>
      PdfPageEditService.instance.setCropBox(bytes, x: x, y: y, width: width, height: height);
  Future<Uint8List> resizePages(Uint8List bytes, {required double width, required double height}) =>
      PdfPageEditService.instance.resizePages(bytes, width: width, height: height);
  Future<List<dynamic>> pageImages(Uint8List bytes, int page) =>
      PdfPageEditService.instance.pageImages(bytes, page);
  Future<Uint8List> moveOrResizeImage(Uint8List bytes, {required int page, required String imageName, required double x, required double y, required double width, required double height}) =>
      PdfPageEditService.instance.moveOrResizeImage(bytes, page: page, imageName: imageName, x: x, y: y, width: width, height: height);
  Future<Uint8List> watermark(
    Uint8List bytes,
    String text, {
    double fontSize = 48,
    int color = 0xFF808080,
    double opacity = 0.3,
    double angleDegrees = 45,
  }) => PdfMarksService.instance.watermark(
    bytes, text, fontSize: fontSize, color: color, opacity: opacity, angleDegrees: angleDegrees,
  );
  Future<Uint8List> stamp(Uint8List bytes, String name) => PdfMarksService.instance.stamp(bytes, name);
  Future<Uint8List> imageStamp(Uint8List bytes, Uint8List imageBytes) => PdfMarksService.instance.imageStamp(bytes, imageBytes);
  Future<Uint8List> addAttachment(Uint8List bytes, {required String name, required Uint8List attachment}) =>
      PdfMarksService.instance.addAttachment(bytes, name: name, attachment: attachment);
  Future<Uint8List> updateMetadata(Uint8List bytes, {String? title, String? author, String? subject, String? keywords}) =>
      PdfMarksService.instance.updateMetadata(bytes, title: title, author: author, subject: subject, keywords: keywords);
  Future<Uint8List> sanitize(Uint8List bytes, {bool metadata = true, bool scripts = true, bool attachments = true}) =>
      PdfMarksService.instance.sanitize(bytes, metadata: metadata, scripts: scripts, attachments: attachments);
  Future<Uint8List> redact(Uint8List bytes, {required int page, required double x, required double y, required double width, required double height}) =>
      PdfMarksService.instance.redact(bytes, page: page, x: x, y: y, width: width, height: height);
  Future<Uint8List> flattenForms(Uint8List bytes) => PdfFormEditService.instance.flattenForms(bytes);
  Future<Uint8List> flattenAnnotations(Uint8List bytes) => PdfFormEditService.instance.flattenAnnotations(bytes);
  Future<Uint8List> fillMultiChoiceField(Uint8List bytes, {required String fieldName, required List<String> values}) =>
      PdfFormEditService.instance.fillMultiChoiceField(bytes, fieldName: fieldName, values: values);
  Future<Uint8List> fillTextField(Uint8List bytes, {required String fieldName, required String value}) =>
      PdfFormEditService.instance.fillTextField(bytes, fieldName: fieldName, value: value);
  Future<Uint8List> fillCheckboxField(Uint8List bytes, {required String fieldName, required bool checked}) =>
      PdfFormEditService.instance.fillCheckboxField(bytes, fieldName: fieldName, checked: checked);
  Future<Uint8List> fillChoiceField(Uint8List bytes, {required String fieldName, required String value}) =>
      PdfFormEditService.instance.fillChoiceField(bytes, fieldName: fieldName, value: value);
  Future<Uint8List> reduceImages(Uint8List bytes, PdfImagePolicy policy) =>
      PdfOptimizationService.instance.reduceImages(bytes, policy);
  Future<Uint8List> unembedStandardFonts(Uint8List bytes) =>
      PdfOptimizationService.instance.unembedStandardFonts(bytes);
}
