import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../../../core/app_controller.dart';
import '../../../services/pdf/pdf_edit_service.dart';
import '../../../services/pdf/pdf_read_service.dart';
import '../tool_dialogs.dart';

class EditingActions {
  EditingActions(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> watermark() async {
    final value = await ToolDialogs.ask(context, 'Add watermark', 'Watermark text', initial: 'CONFIDENTIAL');
    if (value != null && value.trim().isNotEmpty) await controller.watermark(value.trim());
  }

  Future<void> stamp() async {
    final value = await _choose('Choose a stamp', ['Draft', 'Approved', 'Confidential']);
    if (value != null) await controller.stamp(value);
  }

  Future<void> imageStamp() async {
    final image = await controller.files.pickAnyFile(extensions: const ['png', 'jpg', 'jpeg']);
    if (image == null) return;
    await controller.applyCustom('Adding image stamp…', (bytes) => PdfEditService.instance.imageStamp(bytes, image.bytes));
  }

  Future<void> attachment() async {
    final file = await controller.files.pickAnyFile();
    if (file == null) return;
    await controller.applyCustom(
      'Embedding attachment…',
      (bytes) => PdfEditService.instance.addAttachment(bytes, name: file.name, attachment: file.bytes),
    );
  }

  Future<void> crop() async {
    final value = await ToolDialogs.ask(context, 'Crop margins', 'Margin in PDF points (all sides)', initial: '24');
    final margin = double.tryParse(value ?? '');
    if (margin == null || margin < 0) return;
    await controller.cropMargins(top: margin, bottom: margin, left: margin, right: margin);
  }

  Future<void> metadata() async {
    final title = await ToolDialogs.ask(context, 'Document metadata', 'New document title');
    if (title != null) await controller.updateMetadata(title: title);
  }

  Future<void> redact() async {
    final value = await ToolDialogs.ask(context, 'Redact region', 'Page,x,y,width,height (PDF points)', initial: '1,72,700,180,30');
    final values = value?.split(',').map((part) => double.tryParse(part.trim())).toList();
    if (values == null || values.length != 5 || values.any((part) => part == null)) return;
    await controller.applyCustom('Applying permanent redaction…', (bytes) => PdfEditService.instance.redact(
      bytes,
      page: values[0]!.toInt(),
      x: values[1]!,
      y: values[2]!,
      width: values[3]!,
      height: values[4]!,
    ));
  }

  Future<void> cropBox() async {
    final value = await ToolDialogs.ask(context, 'Crop to box', 'x,y,width,height in PDF points', initial: '36,36,523,770');
    final values = value?.split(',').map((part) => double.tryParse(part.trim())).toList();
    if (values == null || values.length != 4 || values.any((item) => item == null || item < 0)) return;
    await controller.applyCustom('Setting crop box…', (bytes) => PdfEditService.instance.setCropBox(
      bytes, x: values[0]!, y: values[1]!, width: values[2]!, height: values[3]!,
    ));
  }

  Future<void> resizePages() async {
    final value = await ToolDialogs.ask(context, 'Resize pages', 'Width,height in PDF points', initial: '595,842');
    final dimensions = value?.split(',').map((part) => double.tryParse(part.trim())).toList();
    if (dimensions == null || dimensions.length != 2 || dimensions.any((part) => part == null || part <= 0)) return;
    await controller.applyCustom('Resizing pages…', (bytes) => PdfEditService.instance.resizePages(
      bytes, width: dimensions[0]!, height: dimensions[1]!,
    ));
  }

  Future<void> moveImage() async {
    final pageValue = await ToolDialogs.ask(context, 'Move or resize image', 'Page number', initial: '1');
    final page = int.tryParse(pageValue ?? '');
    final document = controller.currentDocument;
    if (page == null || page < 1 || document == null) return;
    final images = await PdfEditService.instance.pageImages(document.bytes, page);
    if (images.isEmpty) {
      ToolDialogs.message(context, 'No embedded images were found on that page.');
      return;
    }
    final imageName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose an image'),
        children: [for (final image in images)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, image.name),
            child: Text('${image.name} · ${image.bounds}'),
          )],
      ),
    );
    if (imageName == null) return;
    final value = await ToolDialogs.ask(context, 'Set image bounds', 'x,y,width,height (PDF points)', initial: '50,50,200,100');
    final numbers = value?.split(',').map((part) => double.tryParse(part.trim())).toList();
    if (numbers == null || numbers.length != 4 || numbers.any((number) => number == null)) return;
    await controller.applyCustom('Updating embedded image…', (bytes) => PdfEditService.instance.moveOrResizeImage(
      bytes, page: page, imageName: imageName, x: numbers[0]!, y: numbers[1]!, width: numbers[2]!, height: numbers[3]!,
    ));
  }

  Future<void> unembedFonts() => controller.applyCustom(
        'Removing embedded standard fonts…',
        PdfEditService.instance.unembedStandardFonts,
      );

  Future<void> fillForm() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final fields = await PdfReadService.instance.formFields(document.bytes);
    if (fields.isEmpty) {
      ToolDialogs.message(context, 'This PDF has no interactive form fields.');
      return;
    }
    final fieldName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose a form field'),
        children: [for (final field in fields)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, field.name),
            child: Text('${field.name} · ${field.kind.name}'),
          )],
      ),
    );
    if (fieldName == null) return;
    final selected = fields.firstWhere((field) => field.name == fieldName);
    if (selected.kind == PdfFormFieldKind.checkbox) {
      final checked = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Set $fieldName'),
          content: const Text('Should this checkbox be checked?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Unchecked')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Checked')),
          ],
        ),
      );
      if (checked == null) return;
      await controller.applyCustom('Filling form field…', (bytes) => PdfEditService.instance.fillCheckboxField(
        bytes, fieldName: fieldName, checked: checked,
      ));
      return;
    }
    final value = await ToolDialogs.ask(context, 'Fill $fieldName', 'Field value');
    if (value == null) return;
    if (selected.kind == PdfFormFieldKind.listBox && selected.value is PdfMultiChoiceValue) {
      final values = value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
      await controller.applyCustom('Filling form field…', (bytes) => PdfEditService.instance.fillMultiChoiceField(
        bytes, fieldName: fieldName, values: values,
      ));
    } else if (selected.kind == PdfFormFieldKind.comboBox ||
        selected.kind == PdfFormFieldKind.listBox ||
        selected.kind == PdfFormFieldKind.radioGroup) {
      await controller.applyCustom('Filling form field…', (bytes) => PdfEditService.instance.fillChoiceField(
        bytes, fieldName: fieldName, value: value,
      ));
    } else if (selected.kind == PdfFormFieldKind.textField) {
      await controller.applyCustom('Filling form field…', (bytes) => PdfEditService.instance.fillTextField(
        bytes, fieldName: fieldName, value: value,
      ));
    } else {
      ToolDialogs.message(context, 'This field type cannot be filled with a text value.');
    }
  }

  Future<String?> _choose(String title, List<String> choices) => showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(title),
          children: [for (final value in choices)
            SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, value), child: Text(value))],
        ),
      );
}
