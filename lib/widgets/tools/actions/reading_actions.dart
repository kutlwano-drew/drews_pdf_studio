import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/app_controller.dart';
import '../../../services/pdf/pdf_read_service.dart';
import '../../../services/pdf/reading/pdf_render_service.dart';
import '../../../services/files/directory_export_service.dart';
import '../tool_dialogs.dart';

class ReadingActions {
  ReadingActions(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> documentInfo() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final info = await PdfReadService.instance.inspect(document.bytes);
    final details = info.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
    await ToolDialogs.showText(context, 'Document information', details);
  }

  Future<void> xfaInfo() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final info = await PdfReadService.instance.xfa(document.bytes);
    await ToolDialogs.showText(context, 'XFA information', info?.toString() ?? 'This PDF has no XFA packet.');
  }

  Future<void> extractText() async {
    await controller.extractText();
    final text = controller.extractedText;
    if (text != null && context.mounted) await ToolDialogs.showText(context, 'Extracted text', text);
  }

  Future<void> search() async {
    final query = await ToolDialogs.ask(context, 'Search PDF', 'Text to find');
    final document = controller.currentDocument;
    if (query == null || query.isEmpty || document == null) return;
    final hits = await PdfReadService.instance.search(document.bytes, query);
    await ToolDialogs.showText(context, 'Search results (${hits.length})', hits.map((hit) => hit.toString()).join('\n\n'));
  }

  Future<void> pageInfo() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final pages = await PdfReadService.instance.pageInfo(document.bytes);
    final text = pages.asMap().entries.map((entry) => 'Page ${entry.key + 1}: ${entry.value}').join('\n');
    await ToolDialogs.showText(context, 'Page information', text);
  }

  Future<void> classify() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final kind = await PdfReadService.instance.classifyDocument(document.bytes);
    final pages = await PdfReadService.instance.classifyPages(document.bytes);
    final pageText = pages.asMap().entries.map((entry) => 'Page ${entry.key + 1}: ${entry.value}').join('\n');
    await ToolDialogs.showText(context, 'Document classification', '$kind\n\n$pageText');
  }

  Future<void> forms() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final fields = await PdfReadService.instance.formFields(document.bytes);
    await ToolDialogs.showText(context, 'Form fields (${fields.length})', fields.map((field) => field.toString()).join('\n\n'));
  }

  Future<void> annotations() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final page = await ToolDialogs.ask(context, 'Inspect annotations', 'Page number', initial: '1');
    final pageNumber = int.tryParse(page ?? '');
    if (pageNumber == null || pageNumber < 1) return;
    final annotations = await PdfReadService.instance.annotations(document.bytes, pageNumber);
    await ToolDialogs.showText(context, 'Annotations on page $pageNumber', annotations.map((item) => item.toString()).join('\n\n'));
  }

  Future<void> bookmarks() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final items = await PdfReadService.instance.bookmarks(document.bytes);
    await ToolDialogs.showText(context, 'Bookmarks (${items.length})', items.map((item) => item.toString()).join('\n\n'));
  }

  Future<void> renderAllPages() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final format = await _choose(
      'Choose render format',
      ['PNG', 'JPG'],
    );
    if (format == null) return;
    final normalized = format.toLowerCase();
    final extension = normalized == 'jpg' ? 'jpg' : normalized;
    final mime = normalized == 'jpg' ? 'image/jpeg' : 'image/png';

    final pages = await PdfRenderService().renderAllPages(
      document.bytes,
      format: normalized,
    );
    for (var index = 0; index < pages.length; index++) {
      await controller.saveExport(
        '${_base(document.name)}_page_${index + 1}.$extension',
        pages[index],
        mimeType: mime,
      );
    }
    ToolDialogs.message(
      context,
      'Rendered ${pages.length} pages as ${format.toUpperCase()}.',
    );
  }

  Future<void> extractImages() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final images = await PdfRenderService().extractImages(document.bytes);
    final files = <String, Uint8List>{};
    final renderer = PdfRenderService();

    for (var index = 0; index < images.length; index++) {
      files['${_base(document.name)}_image_${index + 1}.png'] =
          renderer.convertImageFormat(images[index], 'png');
    }

    if (files.isEmpty) {
      ToolDialogs.message(context, 'No embedded images were found.');
      return;
    }

    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose a folder for extracted PNG images',
    );

    if (directory != null && await exportFilesToDirectory(directory, files)) {
      ToolDialogs.message(
        context,
        'Exported ${files.length} PNG image${files.length == 1 ? '' : 's'} to the selected folder.',
      );
      return;
    }

    for (final entry in files.entries) {
      await controller.saveExport(
        entry.key,
        entry.value,
        mimeType: 'image/png',
      );
    }
    ToolDialogs.message(context, 'Exported ${files.length} PNG images.');
  }

  Future<void> renderPage() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final page = await ToolDialogs.ask(
      context,
      'Render page',
      'Page number',
      initial: '1',
    );
    final number = int.tryParse(page ?? '');
    if (number == null || number < 1) return;

    final format = await _choose(
      'Choose render format',
      ['PNG', 'JPG'],
    );
    if (format == null) return;

    final normalized = format.toLowerCase();
    final extension = normalized == 'jpg' ? 'jpg' : normalized;
    final mime = normalized == 'jpg' ? 'image/jpeg' : 'image/png';

    final bitmap = await PdfRenderService().renderPage(
      document.bytes,
      number - 1,
      format: normalized,
    );
    await controller.saveExport(
      '${_base(document.name)}_page_$number.$extension',
      bitmap,
      mimeType: mime,
    );
  }

  Future<void> attachments() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final items = await PdfReadService.instance.attachments(document.bytes);
    if (items.isEmpty) {
      await ToolDialogs.showText(context, 'Attachments', 'This PDF has no embedded attachments.');
      return;
    }
    final name = await ToolDialogs.ask(context, 'Extract attachment', 'Enter the exact attachment name', initial: items.first.name);
    if (name == null || name.isEmpty) return;
    final bytes = await PdfReadService.instance.extractAttachment(document.bytes, name);
    await controller.saveExport(name, bytes);
  }

  Future<void> exportFormData() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final bytes = await PdfReadService.instance.exportFormData(document.bytes);
    await controller.saveExport('${_base(document.name)}.xfdf', bytes, mimeType: 'application/xml');
  }

  Future<String?> _choose(String title, List<String> options) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(option),
                leading: const Icon(Icons.image_outlined),
                onTap: () => Navigator.pop(dialogContext, option),
              ),
          ],
        ),
      ),
    );
  }

  String _base(String name) => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
}
