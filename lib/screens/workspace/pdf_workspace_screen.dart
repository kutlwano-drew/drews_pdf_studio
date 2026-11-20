import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../widgets/workspace/pdf_preview.dart';

class PdfWorkspaceScreen extends StatelessWidget {
  const PdfWorkspaceScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final AppController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final document = controller.currentDocument;

    if (document == null) {
      return const Center(child: Text('No PDF document is currently open.'));
    }

    return Column(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFE53935),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${document.pageCount ?? 0} pages',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Save PDF',
                onPressed: controller.busy ? null : controller.saveCurrent,
                icon: const Icon(Icons.save_outlined),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF2A2A2A)),
        Expanded(
          child: Container(
            color: Colors.black,
            child: Padding(
            padding: const EdgeInsets.all(18),
            child: PdfPreview(document: document),
            ),
          ),
        ),
      ],
    );
  }
}
