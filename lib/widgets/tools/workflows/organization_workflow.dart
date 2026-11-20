import 'package:flutter/material.dart';
import '../../../core/models/tool_definition.dart';
import 'tool_workflow.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'dart:typed_data';
import '../../../core/state/studio_scope.dart';
import '../../../services/files/picked_file.dart';
import '../../../services/pdf/organization/pdf_page_service.dart';
import '../../../services/pdf/organization/page_selection_parser.dart';
import 'workflow_output.dart';
import '../merge_pdf_workspace_dialog.dart';
import '../append_pdf_workspace_dialog.dart';

class OrganizationWorkflow implements ToolWorkflow {
  final _pages = PdfPageService();
  final _parser = PageSelectionParser();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    switch (tool.id) {
      case 'merge':
        final currentBytes = controller.activeDocumentBytes;
        final currentDocument = controller.currentDocument;
        if (currentBytes == null || currentDocument == null) return;

        final additionalFiles = await controller.files.pickPdfs();
        if (additionalFiles.isEmpty) return;

        final mergeFiles = [
          PickedFile(
            name: controller.workingName ?? currentDocument.name,
            bytes: Uint8List.fromList(currentBytes),
          ),
          ...additionalFiles,
        ];

        final merged = await MergePdfWorkspaceDialog.show(
          context,
          files: mergeFiles,
          controller: controller,
        );
        if (merged == null) return;

        await WorkflowOutput.updateCurrent(
          context,
          merged,
          name: 'merged.pdf',
        );
        break;
      case 'split':
        final selected = _parser.parse(
          value,
          pageCount: controller.workingPageCount ??
              controller.currentDocument?.pageCount,
        );
        final splitBytes = await _pages.extractInOrder(
          controller.activeDocumentBytes!,
          selected,
        );
        await WorkflowOutput.updateCurrent(
          context,
          splitBytes,
          name: 'split_pages.pdf',
        );
        break;
      case 'duplicate':
        await WorkflowOutput.updateCurrent(context, await _pages.duplicate(controller.activeDocumentBytes!, _parser.parse(value)));
        break;
      case 'remove':
        await WorkflowOutput.updateCurrent(context, await _pages.remove(controller.activeDocumentBytes!, _parser.parse(value)));
        break;
      case 'extract':
        final result = await _pages.extractInOrder(
          controller.activeDocumentBytes!,
          _parser.parse(
            value,
            pageCount: controller.workingPageCount ??
                controller.currentDocument?.pageCount,
          ),
        );
        await WorkflowOutput.updateCurrent(context, result, name: 'extracted_pages.pdf');
        break;
      case 'reorder':
        final order = _parser.parse(value);
        await WorkflowOutput.updateCurrent(context, await _pages.reorder(controller.activeDocumentBytes!, order));
        break;
      case 'rotate':
        final selected = value.isEmpty ? null : _parser.parse(value);
        await WorkflowOutput.updateCurrent(context, await _pages.rotate(controller.activeDocumentBytes!, PdfRotation.r90, pages: selected));
        break;
      case 'append':
        final other = await controller.files.pickPdf();
        if (other == null) return;
        if (!context.mounted) return;
        final otherPageCount = await controller.documents.pageCount(other.bytes);
        if (!context.mounted) return;
        final shouldAppend = await AppendPdfWorkspaceDialog.show(
          context,
          controller: controller,
          appendix: other,
          appendixPageCount: otherPageCount,
        );
        if (!shouldAppend || !context.mounted) return;
        await WorkflowOutput.updateCurrent(
          context,
          await _pages.append(controller.activeDocumentBytes!, other.bytes),
        );
        break;
    }
  }
}

