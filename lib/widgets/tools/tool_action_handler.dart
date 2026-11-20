import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../services/pdf/pdf_conversion_service.dart';
import '../home/tool_catalog.dart';
import 'actions/conversion_actions.dart';
import 'actions/creation_actions.dart';
import 'actions/editing_actions.dart';
import 'actions/optimization_actions.dart';
import 'actions/organisation_actions.dart';
import 'actions/reading_actions.dart';
import 'actions/security_actions.dart';
import 'tool_dialogs.dart';

class ToolActionHandler {
  ToolActionHandler(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> run(ToolEntry entry) async {
    final needsPdf = !{
      'merge',
      'create',
      'createform',
      'createtable',
      'createshapes',
      'createimagepage',
      'imagestopdf',
      'officetopdf',
    }.contains(entry.action);
    if (needsPdf && controller.currentDocument == null) {
      ToolDialogs.message(context, 'Open a PDF first to use ${entry.title}.');
      return;
    }
    final organisation = OrganisationActions(context, controller);
    final editing = EditingActions(context, controller);
    final reading = ReadingActions(context, controller);
    final security = SecurityActions(context, controller);
    final conversion = ConversionActions(context, controller);
    final creation = CreationActions(context, controller);
    final optimization = OptimizationActions(context, controller);

    try {
      switch (entry.action) {
        case 'merge':
          await organisation.merge();
          return;
        case 'append':
          await organisation.append();
          return;
        case 'split':
          await organisation.split();
          return;
        case 'rotate':
          await organisation.rotate();
          return;
        case 'remove':
          await organisation.removePages(keep: false);
          return;
        case 'extract':
          await organisation.removePages(keep: true);
          return;
        case 'reorder':
          await organisation.reorder();
          return;

        case 'movepage':
          ToolDialogs.message(
            context,
            'Move Page has been replaced by Reorder Pages.',
          );
          return;
        case 'compress':
          await optimization.compress();
          return;
        case 'watermark':
          await editing.watermark();
          return;
        case 'stamp':
          await editing.stamp();
          return;
        case 'imagestamp':
          await editing.imageStamp();
          return;
        case 'attachment':
          await editing.attachment();
          return;
        case 'crop':
          await editing.crop();
          return;
        case 'cropbox':
          await editing.cropBox();
          return;
        case 'resize':
          await editing.resizePages();
          return;
        case 'unembedfonts':
          await editing.unembedFonts();
          return;
        case 'redact':
          await editing.redact();
          return;
        case 'info':
          await reading.documentInfo();
          return;
        case 'text':
          await reading.extractText();
          return;
        case 'search':
          await reading.search();
          return;
        case 'pageinfo':
          await reading.pageInfo();
          return;
        case 'forms':
          await reading.forms();
          return;
        case 'xfainfo':
          await reading.xfaInfo();
          return;
        case 'formexport':
          await reading.exportFormData();
          return;
        case 'annotations':
          await reading.annotations();
          return;
        case 'bookmarks':
          await reading.bookmarks();
          return;
        case 'extractimages':
          await reading.extractImages();
          return;
        case 'renderpage':
          await reading.renderPage();
          return;
        case 'renderall':
          await reading.renderAllPages();
          return;
        case 'attachments':
          await reading.attachments();
          return;
        case 'flattenforms':
          await controller.flattenForms();
          return;
        case 'fillform':
          await editing.fillForm();
          return;
        case 'encrypt':
          await security.password(encrypt: true);
          return;
        case 'decrypt':
          await security.password(encrypt: false);
          return;
        case 'sanitize':
          await controller.sanitize();
          return;
        case 'sign':
          await security.sign();
          return;
        case 'signatures':
          await security.signatures();
          return;
        case 'docx':
          await conversion.toOffice(OfficeDocumentFormat.docx);
          return;
        case 'pptx':
          await conversion.toOffice(OfficeDocumentFormat.pptx);
          return;
        case 'xlsx':
          await conversion.toOffice(OfficeDocumentFormat.xlsx);
          return;
        case 'officetopdf':
          await conversion.officeToPdf();
          return;
        case 'xfa':
          await conversion.xfa();
          return;
        case 'pdfa':
          await conversion.validatePdfA();
          return;
        case 'pdfua':
          await conversion.validatePdfUa();
          return;
        case 'convertpdfa':
          await conversion.convertPdfA();
          return;
        case 'create':
          await creation.createTextPdf();
          return;
        case 'createtable':
          await creation.createTable();
          return;
        case 'createform':
          await creation.createForm();
          return;
        case 'createshapes':
          await creation.createShapes();
          return;
        case 'createimagepage':
          await creation.createImagePage();
          return;
        case 'imagestopdf':
          await creation.imagesToPdf();
          return;
        default:
          ToolDialogs.message(context, 'Unknown tool: ${entry.title}');
          return;
      }
    } catch (exception) {
      if (context.mounted) ToolDialogs.message(context, exception.toString());
    }
  }
}
