import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfSplitService {
  Future<List<Uint8List>> splitEvery(Uint8List bytes, int pagesPerFile) async {
    if (pagesPerFile < 1) throw ArgumentError.value(pagesPerFile);
    final sinks = <int, MemorySink>{};
    await PdfEngine.instance.pdf.split(
      PdfEngine.instance.input(bytes),
      (part) async => sinks[part.index] = MemorySink(),
      by: PdfSplitRule.every(pagesPerFile),
    );
    return [for (final key in sinks.keys.toList()..sort()) sinks[key]!.takeBytes()];
  }
}
