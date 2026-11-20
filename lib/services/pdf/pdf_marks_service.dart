import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfMarksService {
  PdfMarksService._();
  static final instance = PdfMarksService._();
  final _runtime = PdfRuntime.instance;

  Future<Uint8List> watermark(
    Uint8List bytes,
    String text, {
    double fontSize = 48,
    int color = 0xFF808080,
    double opacity = 0.3,
    double angleDegrees = 45,
  }) => _runtime.rewrite(bytes, (editor) => editor.addWatermark(
    text,
    style: PdfWatermarkStyle(
      fontSize: fontSize,
      color: PdfColor(
        ((color >> 16) & 0xFF) / 255,
        ((color >> 8) & 0xFF) / 255,
        (color & 0xFF) / 255,
      ),
      opacity: opacity,
      angleDegrees: angleDegrees,
    ),
  ));

  Future<Uint8List> stamp(Uint8List bytes, String name) {
    final stamp = switch (name.toLowerCase()) {
      'approved' => PdfStamp.approved,
      'confidential' => PdfStamp.confidential,
      _ => PdfStamp.draft,
    };
    return _runtime.rewrite(bytes, (editor) => editor.addStamp(
      stamp,
      bounds: const PdfRect(x: 50, y: 700, width: 150, height: 48),
    ));
  }

  Future<Uint8List> imageStamp(Uint8List bytes, Uint8List imageBytes) =>
      _runtime.rewrite(bytes, (editor) => editor.addImageStamp(
        MemorySource(imageBytes),
        bounds: const PdfRect(x: 50, y: 700, width: 120, height: 60),
      ));

  Future<Uint8List> addAttachment(Uint8List bytes, {required String name, required Uint8List attachment}) =>
      _runtime.rewrite(bytes, (editor) => editor.addAttachment(name, MemorySource(attachment)));

  Future<Uint8List> updateMetadata(Uint8List bytes, {String? title, String? author, String? subject, String? keywords}) async {
    final current = await _runtime.read<PdfMetadata>(
      bytes,
      (document) async => document.metadata,
    );
    return _runtime.rewrite(bytes, (editor) async {
      await editor.setMetadata(PdfMetadata(
        title: title ?? current.title,
        author: author ?? current.author,
        subject: subject ?? current.subject,
        keywords: keywords ?? current.keywords,
        producer: current.producer,
        creator: current.creator,
        creationDate: current.creationDate,
        modificationDate: current.modificationDate,
      ));
    });
  }

  Future<Uint8List> sanitize(Uint8List bytes, {bool metadata = true, bool scripts = true, bool attachments = true}) =>
      _runtime.rewrite(bytes, (editor) => editor.sanitize(
        stripMetadata: metadata,
        stripJavaScript: scripts,
        stripAttachments: attachments,
      ));

  Future<Uint8List> redact(Uint8List bytes, {required int page, required double x, required double y, required double width, required double height}) =>
      _runtime.rewrite(bytes, (editor) async {
        await editor.redact(page - 1, [PdfRect(x: x, y: y, width: width, height: height)]);
      });
}
