import 'dart:typed_data';

class PdfDocumentAsset {
  const PdfDocumentAsset({
    required this.name,
    required this.bytes,
    this.pageCount,
    this.isModified = false,
  });

  final String name;
  final Uint8List bytes;
  final int? pageCount;
  final bool isModified;

  PdfDocumentAsset copyWith({
    String? name,
    Uint8List? bytes,
    int? pageCount,
    bool? isModified,
  }) => PdfDocumentAsset(
        name: name ?? this.name,
        bytes: bytes ?? this.bytes,
        pageCount: pageCount ?? this.pageCount,
        isModified: isModified ?? this.isModified,
      );
}
