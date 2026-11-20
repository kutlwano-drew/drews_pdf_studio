import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfOrganizeService {
  PdfOrganizeService._();
  static final instance = PdfOrganizeService._();
  final _runtime = PdfRuntime.instance;

  Future<Uint8List> merge(List<Uint8List> documents) async {
    if (documents.length < 2) throw ArgumentError('Choose at least two PDFs.');
    return _runtime.output((sink) => _runtime.engine.merge(
          documents.map((bytes) => _runtime.input(bytes)).toList(),
          sink,
        ));
  }

  Future<List<Uint8List>> splitEvery(Uint8List bytes, int pagesPerPart) async {
    if (pagesPerPart < 1) throw ArgumentError('Pages per file must be positive.');
    return _split(bytes, PdfSplitRule.every(pagesPerPart));
  }

  Future<List<Uint8List>> splitBySize(Uint8List bytes, int maxBytes) =>
      _split(bytes, PdfSplitRule.maxBytes(maxBytes));

  Future<List<Uint8List>> splitByBookmarks(Uint8List bytes) =>
      _split(bytes, PdfSplitRule.bookmarks());

  Future<List<Uint8List>> _split(Uint8List bytes, PdfSplitRule rule) async {
    final sinks = <MemorySink>[];
    await _runtime.engine.split(
      _runtime.input(bytes),
      (part) {
        final sink = MemorySink();
        sinks.add(sink);
        return sink;
      },
      by: rule,
    );
    return sinks.map((sink) => sink.takeBytes()).toList();
  }


  Future<Uint8List> keepPagesInOrder(Uint8List bytes, List<int> zeroBasedOrder) async {
    if (zeroBasedOrder.isEmpty) {
      throw const FormatException('Select at least one page.');
    }
    final info = await _runtime.engine.info(_runtime.input(bytes));
    final pageCount = info.pageCount;
    final unique = zeroBasedOrder.toSet();
    if (unique.length != zeroBasedOrder.length ||
        zeroBasedOrder.any((page) => page < 0 || page >= pageCount)) {
      throw FormatException('The selected page order is invalid.');
    }
    final sorted = unique.toList()..sort();
    final outputOrder = zeroBasedOrder.map(sorted.indexOf).toList();
    return _runtime.rewrite(bytes, (editor) async {
      await editor.keepPages(PdfPages.list(sorted));
      if (outputOrder.length > 1) {
        await editor.reorderPages(PdfPageOrder(outputOrder));
      }
    });
  }

  Future<Uint8List> removePages(Uint8List bytes, List<int> pages) =>
      _runtime.rewrite(bytes, (editor) => editor.removePages(_zeroBased(pages)));

  Future<Uint8List> keepPages(Uint8List bytes, List<int> pages) =>
      _runtime.rewrite(bytes, (editor) => editor.keepPages(_zeroBased(pages)));

  Future<Uint8List> reorderPages(Uint8List bytes, List<int> order) async {
    if (bytes.isEmpty) {
      throw const FormatException('The PDF is empty.');
    }

    final info = await _runtime.engine.info(_runtime.input(bytes));
    final pageCount = info.pageCount;
    if (pageCount < 1 || order.length != pageCount) {
      throw FormatException(
        'The new order must contain exactly $pageCount page numbers.',
      );
    }

    final seen = <int>{};
    for (final page in order) {
      if (page < 1 || page > pageCount) {
        throw RangeError.range(page, 1, pageCount, 'page');
      }
      if (!seen.add(page)) {
        throw FormatException('Page $page appears more than once.');
      }
    }

    return _runtime.rewrite(
      bytes,
      (editor) => editor.reorderPages(
        PdfPageOrder(_zeroBasedList(List<int>.of(order))),
      ),
    );
  }

  Future<Uint8List> rotatePages(Uint8List bytes, {int? page}) =>
      _runtime.rewrite(
        bytes,
        (editor) => editor.rotatePages(
          by: PdfRotation.r90,
          pages: page == null ? const PdfPages.all() : PdfPages.single(page - 1),
        ),
      );

  Future<Uint8List> appendPdf(
    Uint8List bytes,
    Uint8List appendix, {
    String? password,
  }) =>
      _runtime.rewrite(
        bytes,
        (editor) => editor.appendPages(
          _runtime.input(appendix, password: password),
        ),
      );

  PdfPages _zeroBased(List<int> pages) => PdfPages.list(_zeroBasedList(pages));

  List<int> _zeroBasedList(List<int> pages) =>
      pages.map((page) => page - 1).toList();
}
