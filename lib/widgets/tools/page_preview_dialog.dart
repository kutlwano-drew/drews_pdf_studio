import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'page_preview_dialog_view.dart';

class PagePreviewDialog {
  static Future<void> show(
    BuildContext context, {
    required int pageNumber,
    required Future<Uint8List> image,
    required int pageCount,
    required Future<Uint8List> Function(int pageNumber) loadPage,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PagePreviewDialogView(
        initialPage: pageNumber,
        pageCount: pageCount,
        initialImage: image,
        loadPage: loadPage,
      ),
    );
  }
}
