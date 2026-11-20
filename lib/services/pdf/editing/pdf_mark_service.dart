import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfMarkService {
  Future<Uint8List> watermark(
    Uint8List bytes,
    String text, {
    double fontSize = 48,
    int color = 0xFF808080,
    double opacity = 0.3,
    double angleDegrees = 45,
  }) =>
      _rewrite(
        bytes,
        (editor) => editor.addWatermark(
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
        ),
      );

  Future<Uint8List> stamp(Uint8List bytes, PdfStamp stamp) =>
      _rewrite(bytes, (editor) => editor.addStamp(
        stamp, bounds: const PdfRect(x: 48, y: 720, width: 150, height: 42),
      ));

  Future<Uint8List> imageStamp(Uint8List bytes, Uint8List image) =>
      _rewrite(bytes, (editor) => editor.addImageStamp(
        MemorySource(image),
        bounds: const PdfRect(x: 48, y: 720, width: 120, height: 60),
      ));


  Future<Uint8List> imageStampOnPage(
    Uint8List bytes,
    Uint8List image, {
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
  }) => _rewrite(bytes, (editor) => editor.addImageStamp(
        MemorySource(image),
        bounds: PdfRect(x: x, y: y, width: width, height: height),
        pages: PdfPages.single(pageNumber - 1),
      ));

  Future<Uint8List> _rewrite(Uint8List bytes, Future<void> Function(PdfEditor) action) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(PdfEngine.instance.input(bytes), sink, action);
    return sink.takeBytes();
  }
}
