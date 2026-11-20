import 'package:flutter/material.dart';
import '../../../core/app_controller.dart';
import '../../../services/pdf/pdf_conversion_service.dart';
import '../../../services/pdf/pdf_standards_service.dart';
import '../tool_dialogs.dart';

class ConversionActions {
  ConversionActions(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> toOffice(OfficeDocumentFormat format) => controller.convertToOffice(format);

  Future<void> officeToPdf() async {
    final format = await showDialog<OfficeDocumentFormat>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Office file type'),
        children: [
          _option(dialogContext, 'Word document', OfficeDocumentFormat.docx),
          _option(dialogContext, 'PowerPoint presentation', OfficeDocumentFormat.pptx),
          _option(dialogContext, 'Excel spreadsheet', OfficeDocumentFormat.xlsx),
        ],
      ),
    );
    if (format == null) return;
    final file = await controller.files.pickAnyFile(extensions: [format.name]);
    if (file == null) return;
    final bytes = await PdfConversionService.instance.officeToPdf(file.bytes, format);
    await controller.saveExport('${_base(file.name)}.pdf', bytes, mimeType: 'application/pdf');
  }

  Future<void> xfa() async => controller.applyCustom(
        'Converting XFA form…',
        PdfConversionService.instance.xfaToAcroForm,
      );

  Future<void> validatePdfA() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final report = await PdfStandardsService.instance.validatePdfA(document.bytes);
    await ToolDialogs.showText(context, 'PDF/A validation', report.toString());
  }

  Future<void> validatePdfUa() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final report = await PdfStandardsService.instance.validatePdfUa(document.bytes);
    await ToolDialogs.showText(context, 'PDF/UA validation', report.toString());
  }

  Future<void> convertPdfA() => controller.convertToPdfA();

  SimpleDialogOption _option(BuildContext context, String label, OfficeDocumentFormat format) =>
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, format),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(label)),
      );

  String _base(String name) => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
}
