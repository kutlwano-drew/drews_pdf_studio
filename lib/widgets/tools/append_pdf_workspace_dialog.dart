import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/models/pdf_document_asset.dart';
import '../../core/state/studio_controller.dart';
import '../../services/files/picked_file.dart';
import '../workspace/pdf_preview.dart';

class AppendPdfWorkspaceDialog extends StatelessWidget {
  const AppendPdfWorkspaceDialog({super.key, required this.controller, required this.appendix, required this.appendixPageCount});

  final StudioController controller;
  final PickedFile appendix;
  final int appendixPageCount;

  static Future<bool> show(BuildContext context, {
    required StudioController controller,
    required PickedFile appendix,
    required int appendixPageCount,
  }) async => await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AppendPdfWorkspaceDialog(controller: controller, appendix: appendix, appendixPageCount: appendixPageCount),
  ) ?? false;

  @override
  Widget build(BuildContext context) {
    final current = controller.currentDocument;
    final currentBytes = controller.activeDocumentBytes;
    if (current == null || currentBytes == null) return const SizedBox.shrink();
    final currentName = controller.workingName ?? current.name;
    final currentCount = controller.workingPageCount ?? current.pageCount;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(width: size.width * .92, height: size.height * .88, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 12, 8, 8), child: Row(children: [
          const Icon(Icons.playlist_add, color: Color(0xFFE53935)), const SizedBox(width: 10),
          const Expanded(child: Text('Append PDF documents', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 17))),
          IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
        ])),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(12), child: Text(
          'The second document will be appended after every page in the current document. Review both documents before applying.',
          style: const TextStyle(color: Colors.black87),
        )),
        Expanded(child: Row(children: [
          Expanded(child: _panel(
            title: 'Current document · first',
            name: currentName,
            pageCount: currentCount,
            bytes: currentBytes,
          )),
          const VerticalDivider(width: 1),
          Expanded(child: _panel(
            title: 'Append document · second',
            name: appendix.name,
            pageCount: appendixPageCount,
            bytes: appendix.bytes,
          )),
        ])),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: Text('${currentCount?.toString() ?? '-'} + $appendixPageCount pages', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700))),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.playlist_add), label: const Text('Append pages')),
        ])),
      ])),
    );
  }

  Widget _panel({required String title, required String name, required int? pageCount, required Uint8List bytes}) =>
      Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 12)),
        Text('${pageCount?.toString() ?? '-'} pages', style: const TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 10),
        Expanded(child: PdfPreview(document: PdfDocumentAsset(name: name, bytes: bytes, pageCount: pageCount))),
      ]));
}
