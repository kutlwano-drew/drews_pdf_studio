import 'package:flutter/material.dart';

import '../../core/models/pdf_document_asset.dart';
import '../workspace/pdf_preview.dart';

class PdfChangesPreviewDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required PdfDocumentAsset document,
  }) {
    final size = MediaQuery.of(context).size;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: size.width * 0.94,
          height: size.height * 0.92,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$title · Preview changes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PdfPreview(document: document),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
