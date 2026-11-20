import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/app_controller.dart';
import '../../../services/pdf/pdf_organize_service.dart';
import '../tool_dialogs.dart';

class OrganisationActions {
  OrganisationActions(this.context, this.controller);

  final BuildContext context;
  final AppController controller;

  Future<void> merge() => controller.mergePdfs();

  Future<void> append() async {
    final picked = await controller.files.pickPdf();
    if (picked == null) return;

    await controller.applyCustom(
      'Appending pages…',
      (bytes) => PdfOrganizeService.instance.appendPdf(bytes, picked.bytes),
    );
  }

  Future<void> split() async {
    final mode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Split method'),
        children: [
          _splitChoice(dialogContext, 'pages', 'Every N pages'),
          _splitChoice(dialogContext, 'size', 'Maximum file size'),
          _splitChoice(dialogContext, 'bookmarks', 'Top-level bookmarks'),
        ],
      ),
    );

    final document = controller.currentDocument;

    if (mode == null || document == null) return;

    List<Uint8List> parts;

    if (mode == 'bookmarks') {
      parts = await PdfOrganizeService.instance.splitByBookmarks(
        document.bytes,
      );
    } else if (mode == 'size') {
      final value = await ToolDialogs.ask(
        context,
        'Split by size',
        'Maximum size in MB',
        initial: '10',
      );

      final megabytes = double.tryParse(value ?? '');

      if (megabytes == null || megabytes <= 0) return;

      parts = await PdfOrganizeService.instance.splitBySize(
        document.bytes,
        (megabytes * 1024 * 1024).round(),
      );
    } else {
      final value = await ToolDialogs.ask(
        context,
        'Split by pages',
        'Pages per output file',
        initial: '5',
      );

      final pages = int.tryParse(value ?? '');

      if (pages == null || pages < 1) return;

      parts = await PdfOrganizeService.instance.splitEvery(
        document.bytes,
        pages,
      );
    }

    for (var index = 0; index < parts.length; index++) {
      await controller.saveExport(
        '${_base(document.name)}_part_${index + 1}.pdf',
        parts[index],
        mimeType: 'application/pdf',
      );
    }

    ToolDialogs.message(context, 'Created ${parts.length} PDF parts.');
  }

  SimpleDialogOption _splitChoice(
    BuildContext context,
    String value,
    String label,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Text(label),
    );
  }

  Future<void> rotate() async {
    final value = await ToolDialogs.ask(
      context,
      'Rotate pages',
      'Page number (blank rotates all)',
      initial: '',
    );

    if (value == null) return;

    final page = value.trim().isEmpty ? null : int.tryParse(value);

    if (value.trim().isNotEmpty && (page == null || page < 1)) {
      return;
    }

    await controller.rotate(page: page);
  }

  Future<void> removePages({required bool keep}) async {
    final value = await ToolDialogs.ask(
      context,
      keep ? 'Extract pages' : 'Remove pages',
      'Page numbers, separated by commas',
      initial: '1,3',
    );

    final pages = _parsePages(value);

    if (pages.isEmpty) return;

    if (keep) {
      await controller.keepPages(pages);
    } else {
      await controller.removePages(pages);
    }
  }

  Future<void> reorder() async {
    final value = await ToolDialogs.ask(
      context,
      'Reorder pages',
      'New order, e.g. 3,1,2',
      initial: '2,1,3',
    );

    final pages = _parsePages(value);

    if (pages.isNotEmpty) {
      await controller.reorderPages(pages);
    }
  }

  List<int> _parsePages(String? value) {
    return (value ?? '')
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .where((page) => page > 0)
        .toList();
  }

  String _base(String name) {
    return name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
  }
}
