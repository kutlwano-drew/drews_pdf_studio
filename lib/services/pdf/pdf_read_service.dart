import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class ExtractedPdfImage {
  const ExtractedPdfImage({required this.info, required this.bytes});
  final dynamic info;
  final Uint8List bytes;
  String get extension => switch (info.encoding.name as String) {
        'jpeg' => 'jpg',
        'jpx' => 'jp2',
        'ccitt' => 'tiff',
        'jbig2' => 'jb2',
        _ => 'bin',
      };
}

class PdfReadService {
  PdfReadService._();
  static final instance = PdfReadService._();
  final _runtime = PdfRuntime.instance;

  Future<Map<String, Object?>> inspect(Uint8List bytes, {String? password}) =>
      _runtime.read<Map<String, Object?>>(bytes, (document) async => {
            'pageCount': document.pageCount,
            'version': document.version,
            'isTagged': document.isTagged,
            'isEncrypted': document.encryption != null,
            'title': document.metadata.title ?? '',
            'author': document.metadata.author ?? '',
            'subject': document.metadata.subject ?? '',
            'keywords': document.metadata.keywords ?? '',
            'producer': document.metadata.producer ?? '',
            'creator': document.metadata.creator ?? '',
            'creationDate': document.metadata.creationDate?.toIso8601String() ?? '',
            'modificationDate': document.metadata.modificationDate?.toIso8601String() ?? '',
            'encryption': document.encryption?.toString() ?? 'None',
          }, password: password);

  Future<String> extractText(Uint8List bytes, {String? password}) =>
      _runtime.read<String>(bytes, (document) => document.text(), password: password);

  Future<List<dynamic>> search(
    Uint8List bytes,
    String query, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.search(query),
        password: password,
      );

  Future<List<dynamic>> pageInfo(Uint8List bytes, {String? password}) =>
      _runtime.read<List<dynamic>>(bytes, (document) => document.pageInfo(), password: password);

  Future<List<dynamic>> classifyPages(
    Uint8List bytes, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.classifyPages(),
        password: password,
      );

  Future<dynamic> classifyDocument(Uint8List bytes, {String? password}) =>
      _runtime.read<dynamic>(
        bytes,
        (document) async => document.classifyDocument(),
        password: password,
      );

  Future<List<dynamic>> bookmarks(
    Uint8List bytes, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.bookmarkRanges(),
        password: password,
      );

  Future<List<dynamic>> annotations(
    Uint8List bytes,
    int page, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.annotations(page - 1),
        password: password,
      );

  Future<List<dynamic>> formFields(
    Uint8List bytes, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.formFields(),
        password: password,
      );

  Future<List<dynamic>> attachments(
    Uint8List bytes, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.attachments(),
        password: password,
      );

  Future<Uint8List> exportFormData(
    Uint8List bytes, {
    String? password,
    PdfFormDataFormat format = PdfFormDataFormat.xfdf,
  }) async {
    final sink = MemorySink();
    await _runtime.read<void>(bytes, (document) => document.exportFormData(sink, format: format),
        password: password);
    return sink.takeBytes();
  }

  Future<Uint8List> extractAttachment(
    Uint8List bytes,
    String name, {
    String? password,
  }) async {
    final sink = MemorySink();
    await _runtime.read<void>(
      bytes,
      (document) => document.extractAttachment(name, sink),
      password: password,
    );
    return sink.takeBytes();
  }

  Future<List<dynamic>> signatures(
    Uint8List bytes, {
    String? password,
  }) => _runtime.read<List<dynamic>>(
        bytes,
        (document) => document.signatures(),
        password: password,
      );

  Future<bool> verifySignatures(Uint8List bytes, {String? password}) =>
      _runtime.read<bool>(
        bytes,
        (document) => document.verifySignatures(),
        password: password,
      );

  Future<dynamic> xfa(Uint8List bytes, {String? password}) =>
      _runtime.read<dynamic>(bytes, (document) => document.xfa(), password: password);

  Future<dynamic> renderPage(
    Uint8List bytes,
    int page, {
    String? password,
  }) => _runtime.read<dynamic>(
        bytes,
        (document) => document.bitmap(page - 1),
        password: password,
      );

  Future<List<Uint8List>> renderAllPages(Uint8List bytes, {String? password}) async {
    final sinks = <MemorySink>[];
    await _runtime.read<dynamic>(bytes, (document) => document.render((page) {
          final sink = MemorySink();
          sinks.add(sink);
          return sink;
        }), password: password);
    return sinks.map((sink) => sink.takeBytes()).toList();
  }

  Future<List<ExtractedPdfImage>> extractImages(Uint8List bytes, {String? password}) async {
    final sinks = <MemorySink>[];
    final infos = await _runtime.read<List<dynamic>>(bytes, (document) => document.extractImages((image) {
          final sink = MemorySink();
          sinks.add(sink);
          return sink;
        }), password: password);
    return [
      for (var index = 0; index < infos.length; index++)
        ExtractedPdfImage(info: infos[index], bytes: sinks[index].takeBytes()),
    ];
  }
}
