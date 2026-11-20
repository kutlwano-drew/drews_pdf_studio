import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../core/models/pdf_document_asset.dart';
import '../common/pdf_password_dialog.dart';

class PdfPreview extends StatelessWidget {
  const PdfPreview({super.key, required this.document});
  final PdfDocumentAsset document;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: PdfViewer.data(
          document.bytes,
          sourceName: '${document.name}_${document.bytes.hashCode}',
          passwordProvider: () => PdfPasswordDialog.request(context),
          key: ValueKey(document.bytes.hashCode),
        ),
      );
}
