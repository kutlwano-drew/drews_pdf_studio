import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'page_preview_dialog_view.dart';

class PagePreviewDialogViewState extends State<PagePreviewDialogView> {
  late int _page = widget.initialPage;
  late Future<Uint8List> _image = widget.initialImage;

  void _move(int delta) {
    final next = (_page + delta).clamp(1, widget.pageCount).toInt();
    if (next == _page) return;
    setState(() {
      _page = next;
      _image = widget.loadPage(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: SizedBox(
        width: size.width * .88,
        height: size.height * .88,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
            child: Row(children: [
              IconButton(tooltip: 'preview.previous'.tr(), onPressed: _page > 1 ? () => _move(-1) : null, icon: const Icon(Icons.chevron_left, color: Colors.black)),
              Expanded(child: Text('${'preview.page'.tr()} $_page / ${widget.pageCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              IconButton(tooltip: 'preview.next'.tr(), onPressed: _page < widget.pageCount ? () => _move(1) : null, icon: const Icon(Icons.chevron_right, color: Colors.black)),
              IconButton(tooltip: 'preview.close'.tr(), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF0F2F5),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Uint8List>(
                future: _image,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('This page could not be rendered. Try reopening the PDF.', textAlign: TextAlign.center);
                  if (!snapshot.hasData) return const CircularProgressIndicator(color: Color(0xFFE84B3C));
                  return InteractiveViewer(minScale: .5, maxScale: 5, child: Image.memory(snapshot.data!, fit: BoxFit.contain));
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
