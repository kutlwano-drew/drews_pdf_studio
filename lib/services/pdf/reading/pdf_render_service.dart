import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfRenderService {
  Future<Uint8List> renderPage(
    List<int> bytes,
    int page, {
    String format = 'png',
  }) async {
    final bitmap = await PdfEngine.instance.pdf.read(
      PdfEngine.instance.input(bytes),
      (document) => document.bitmap(page),
    );
    return convertImageFormat(bitmap.bytes, format);
  }

  Future<List<Uint8List>> renderAllPages(
    List<int> bytes, {
    String format = 'png',
  }) async {
    final rendered = <Uint8List>[];
    final info = await PdfEngine.instance.pdf.info(
      PdfEngine.instance.input(bytes),
    );
    final count = info.pageCount as int;
    for (var page = 0; page < count; page++) {
      final bitmap = await PdfEngine.instance.pdf.read(
        PdfEngine.instance.input(bytes),
        (document) => document.bitmap(page),
      );
      rendered.add(convertImageFormat(bitmap.bytes, format));
    }
    return rendered;
  }

  Uint8List convertImageFormat(Uint8List bytes, String format) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }

    return Uint8List.fromList(
      switch (format.toLowerCase()) {
        'jpg' || 'jpeg' => img.encodeJpg(decoded, quality: 92),
        _ => img.encodePng(decoded),
      },
    );
  }

  Future<List<Uint8List>> extractImages(List<int> bytes) async {
    final sinks = <MemorySink>[];
    await PdfEngine.instance.pdf.read(
      PdfEngine.instance.input(bytes),
      (document) => document.extractImages((_) async {
        final sink = MemorySink();
        sinks.add(sink);
        return sink;
      }),
    );
    return [for (final sink in sinks) sink.takeBytes()];
  }
}
