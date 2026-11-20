import 'package:flutter/material.dart';
import '../../../core/app_controller.dart';
import '../../../services/pdf/pdf_creation_service.dart';
import '../tool_dialogs.dart';

class CreationActions {
  CreationActions(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> createTextPdf() async {
    final title = await ToolDialogs.ask(context, 'Create PDF', 'Document title', initial: 'Untitled document');
    if (title == null || title.trim().isEmpty) return;
    final body = await ToolDialogs.ask(context, 'Create PDF', 'Document text', initial: 'Start writing your document here.', maxLines: 8);
    if (body == null) return;
    await controller.createDocument(title, body);
  }

  Future<void> createTable() async {
    final title = await ToolDialogs.ask(context, 'Create table PDF', 'Document title', initial: 'Report table');
    if (title == null || title.trim().isEmpty) return;
    final headerText = await ToolDialogs.ask(context, 'Table columns', 'Column names separated by commas', initial: 'Item,Quantity,Price');
    if (headerText == null) return;
    final headers = headerText.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    if (headers.isEmpty) return;
    final rowText = await ToolDialogs.ask(context, 'Table rows', 'Rows separated by semicolons; cells separated by commas', initial: 'Paper,2,10;Pens,5,3');
    if (rowText == null) return;
    final rows = rowText.split(';').map((row) => row.split(',').map((cell) => cell.trim()).toList()).where((row) => row.length == headers.length).toList();
    if (rows.isEmpty) {
      ToolDialogs.message(context, 'No valid rows. Each row must have ${headers.length} cells.');
      return;
    }
    final bytes = await PdfCreationService.instance.createTableDocument(title: title, headers: headers, rows: rows);
    await controller.openBytes('$title.pdf', bytes);
  }

  Future<void> createForm() async {
    final title = await ToolDialogs.ask(context, 'Create fillable form', 'Form title', initial: 'New form');
    if (title == null || title.trim().isEmpty) return;
    final bytes = await PdfCreationService.instance.createFillableForm(title: title);
    await controller.openBytes('$title.pdf', bytes);
  }

  Future<void> createShapes() async {
    final bytes = await PdfCreationService.instance.createShapesDocument();
    await controller.openBytes('shapes.pdf', bytes);
  }

  Future<void> createImagePage() async {
    final image = await controller.files.pickAnyFile(extensions: const ['png', 'jpg', 'jpeg']);
    if (image == null) return;
    final altText = await ToolDialogs.ask(context, 'Create image page', 'Accessible image description', initial: image.name);
    if (altText == null) return;
    final bytes = await PdfCreationService.instance.createImagePage(image.bytes, altText: altText);
    await controller.openBytes('${image.name}.pdf', bytes);
  }

  Future<void> imagesToPdf() async {
    final images = await controller.files.pickManyFiles(extensions: const ['png', 'jpg', 'jpeg']);
    if (images.isEmpty) return;
    final bytes = await PdfCreationService.instance.photosToPdf(images.map((image) => image.bytes).toList());
    await controller.openBytes('images.pdf', bytes);
  }
}
