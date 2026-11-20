import 'dart:typed_data';

import 'pdf_document_asset.dart';

class PdfDocumentItem extends PdfDocumentAsset {
  const PdfDocumentItem({
    required String name,
    required Uint8List bytes,
    int? pageCount,
    bool modified = false,
  }) : super(
          name: name,
          bytes: bytes,
          pageCount: pageCount,
          isModified: modified,
        );

  bool get modified => isModified;

  @override
  PdfDocumentItem copyWith({
    String? name,
    Uint8List? bytes,
    int? pageCount,
    bool? isModified,
  }) {
    return PdfDocumentItem(
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      pageCount: pageCount ?? this.pageCount,
      modified: isModified ?? this.isModified,
    );
  }
}
