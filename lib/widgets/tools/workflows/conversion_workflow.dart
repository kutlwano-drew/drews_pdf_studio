import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/conversion/pdf_office_conversion_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class ConversionWorkflow implements ToolWorkflow {
  final _conversion = PdfOfficeConversionService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    if (tool.id == 'officetopdf') {
      final file = await controller.files.pickFile(['docx', 'pptx', 'xlsx']);
      if (file == null) return;
      final format = _formatFromName(file.name);
      final pdf = await _conversion.fromOffice(file.bytes, format);
      await WorkflowOutput.updateCurrent(
        context,
        pdf,
        name: '${_baseName(file.name)}.pdf',
      );
      return;
    }
    final bytes = controller.activeDocumentBytes!;
    final format = switch (tool.id) {
      'docx' => PdfOfficeFormat.docx,
      'pptx' => PdfOfficeFormat.pptx,
      _ => PdfOfficeFormat.xlsx,
    };
    final output = await _conversion.toOffice(bytes, format);
    final extension = tool.id;
    final mime = switch (extension) {
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      _ => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    await WorkflowOutput.save(context, 'converted.$extension', output, mimeType: mime);
  }

  PdfOfficeFormat _formatFromName(String name) => switch (name.split('.').last.toLowerCase()) {
    'docx' => PdfOfficeFormat.docx,
    'pptx' => PdfOfficeFormat.pptx,
    _ => PdfOfficeFormat.xlsx,
  };

  String _baseName(String name) => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
}
