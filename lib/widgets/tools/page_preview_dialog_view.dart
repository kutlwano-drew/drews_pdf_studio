import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'page_preview_dialog_view_state.dart';

class PagePreviewDialogView extends StatefulWidget {
  const PagePreviewDialogView({
    required this.initialPage,
    required this.pageCount,
    required this.initialImage,
    required this.loadPage,
  });

  final int initialPage;
  final int pageCount;
  final Future<Uint8List> initialImage;
  final Future<Uint8List> Function(int pageNumber) loadPage;

  @override
  PagePreviewDialogViewState createState() => PagePreviewDialogViewState();
}
