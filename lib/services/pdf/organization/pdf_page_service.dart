import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfPageService {

  Future<Uint8List> extractInOrder(
    Uint8List bytes,
    List<int> zeroBasedPages,
  ) async {
    if (bytes.isEmpty || zeroBasedPages.isEmpty) {
      throw const FormatException('Select at least one page to extract.');
    }

    final info = await PdfEngine.instance.pdf.info(
      PdfEngine.instance.input(bytes),
    );
    final pageCount = info.pageCount as int;
    if (pageCount < 1) {
      throw const FormatException('The PDF contains no pages.');
    }

    final seen = <int>{};
    for (final page in zeroBasedPages) {
      if (page < 0 || page >= pageCount) {
        throw RangeError.range(page, 0, pageCount - 1, 'page');
      }
      if (!seen.add(page)) {
        throw FormatException('Page ${page + 1} appears more than once.');
      }
    }

    // keepPages creates a valid subset first. reorderPages then receives a
    // complete permutation of that subset (never a partial source index list).
    final sortedPages = List<int>.of(zeroBasedPages)..sort();
    final subsetOrder = zeroBasedPages
        .map((sourcePage) => sortedPages.indexOf(sourcePage))
        .toList(growable: false);

    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes),
      sink,
      (editor) async {
        await editor.keepPages(PdfPages.list(sortedPages));
        if (subsetOrder.length > 1) {
          await editor.reorderPages(PdfPageOrder(subsetOrder));
        }
      },
    );
    return sink.takeBytes();
  }

  Future<Uint8List> remove(Uint8List bytes, List<int> zeroBasedPages) async {
    final pageCount = await _pageCount(bytes);
    _validateSelection(zeroBasedPages, pageCount);
    if (zeroBasedPages.length >= pageCount) {
      throw const FormatException('A PDF must retain at least one page.');
    }
    return _rewrite(bytes, (editor) => editor.removePages(PdfPages.list(zeroBasedPages)));
  }

  Future<Uint8List> keep(Uint8List bytes, List<int> zeroBasedPages) async {
    final pageCount = await _pageCount(bytes);
    _validateSelection(zeroBasedPages, pageCount);
    return _rewrite(bytes, (editor) => editor.keepPages(PdfPages.list(zeroBasedPages)));
  }

  Future<int> _pageCount(Uint8List bytes) async {
    if (bytes.isEmpty) throw const FormatException('The PDF is empty.');
    final info = await PdfEngine.instance.pdf.info(PdfEngine.instance.input(bytes));
    final count = info.pageCount as int;
    if (count < 1) throw const FormatException('The PDF contains no pages.');
    return count;
  }

  void _validateSelection(List<int> pages, int pageCount) {
    if (pages.isEmpty) throw const FormatException('Select at least one page.');
    final seen = <int>{};
    for (final page in pages) {
      if (page < 0 || page >= pageCount) {
        throw RangeError.range(page, 0, pageCount - 1, 'page');
      }
      if (!seen.add(page)) {
        throw FormatException('Page ${page + 1} appears more than once.');
      }
    }
  }

  Future<Uint8List> rotate(Uint8List bytes, PdfRotation rotation, {List<int>? pages}) =>
      _rewrite(bytes, (editor) => editor.rotatePages(
            by: rotation,
            pages: pages == null ? const PdfPages.all() : PdfPages.list(pages),
          ));

  Future<Uint8List> reorder(Uint8List bytes, List<int> order) async {
    if (bytes.isEmpty) {
      throw const FormatException('The PDF is empty.');
    }

    final info = await PdfEngine.instance.pdf.info(
      PdfEngine.instance.input(bytes),
    );
    final pageCount = info.pageCount as int;

    if (pageCount < 1) {
      throw const FormatException('The PDF contains no pages.');
    }
    if (order.length != pageCount) {
      throw FormatException(
        'The new order must contain exactly $pageCount page numbers.',
      );
    }

    final seen = <int>{};
    for (final page in order) {
      if (page < 0 || page >= pageCount) {
        throw RangeError.range(page, 0, pageCount - 1, 'page');
      }
      if (!seen.add(page)) {
        throw FormatException('Page ${page + 1} appears more than once.');
      }
    }

    if (seen.length != pageCount) {
      throw const FormatException(
        'Every page must appear exactly once in the new order.',
      );
    }

    return _rewrite(
      bytes,
      (editor) => editor.reorderPages(PdfPageOrder(List<int>.of(order))),
    );
  }

  Future<Uint8List> append(Uint8List bytes, Uint8List other) =>
      _rewrite(bytes, (editor) => editor.appendPages(PdfEngine.instance.input(other)));

  Future<Uint8List> duplicate(Uint8List bytes, List<int> zeroBasedPages) async {
    final selected = zeroBasedPages.toSet().toList()..sort();
    if (selected.isEmpty) throw const FormatException('Select at least one page to duplicate.');
    final info = await PdfEngine.instance.pdf.info(PdfEngine.instance.input(bytes));
    final originalCount = info.pageCount as int;
    if (selected.any((page) => page < 0 || page >= originalCount)) {
      throw RangeError('A selected page is outside the document.');
    }
    final order = <int>[];
    for (var page = 0; page < originalCount; page++) {
      order.add(page);
      final duplicatePosition = selected.indexOf(page);
      if (duplicatePosition >= 0) order.add(originalCount + duplicatePosition);
    }
    return _rewrite(bytes, (editor) async {
      await editor.appendPages(
        PdfEngine.instance.input(bytes),
        pages: PdfPages.list(selected),
      );
      await editor.reorderPages(PdfPageOrder(order));
    });
  }

  Future<Uint8List> _rewrite(
    Uint8List bytes,
    Future<void> Function(PdfEditor editor) operation,
  ) async {
    final sink = MemorySink();
    await PdfEngine.instance.rewrite(
      PdfEngine.instance.input(bytes),
      sink,
      operation,
    );
    return sink.takeBytes();
  }
}
