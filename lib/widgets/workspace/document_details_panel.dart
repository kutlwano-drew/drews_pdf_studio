import 'package:flutter/material.dart';
import '../../core/models/pdf_document_asset.dart';
import 'document_detail_row.dart';

class DocumentDetailsPanel extends StatelessWidget {
  const DocumentDetailsPanel({super.key, required this.document});
  final PdfDocumentAsset document;

  @override
  Widget build(BuildContext context) => Container(
        width: 230, padding: const EdgeInsets.all(16), color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DOCUMENT', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.black45)),
          const SizedBox(height: 16),
          DocumentDetailRow(label: 'File name', value: document.name),
          DocumentDetailRow(label: 'Pages', value: '${document.pageCount ?? 'Unknown'}'),
          DocumentDetailRow(label: 'File size', value: _size(document.bytes.length)),
          DocumentDetailRow(label: 'Status', value: document.isModified ? 'Modified' : 'Original'),
        ]),
      );

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

