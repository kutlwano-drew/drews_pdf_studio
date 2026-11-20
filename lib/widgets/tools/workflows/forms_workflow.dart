import 'package:flutter/material.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/forms/pdf_form_export_service.dart';
import '../../../services/pdf/forms/pdf_form_service.dart';
import '../../../services/pdf/security/pdf_sanitize_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class FormsWorkflow implements ToolWorkflow {
  final _forms = PdfFormService();
  final _export = PdfFormExportService();
  final _sanitize = PdfSanitizeService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes!;
    switch (tool.id) {
      case 'forms':
        await _show(context, 'Interactive form fields', await _forms.fields(bytes));
        break;
      case 'fillform':
        final parts = value.split('|');
        if (parts.length < 2) throw const FormatException('Use fieldName|value.');
        await WorkflowOutput.updateCurrent(context, await _forms.setTextField(bytes, parts.first.trim(), parts.sublist(1).join('|')));
        break;
      case 'formexport':
        final data = await _export.export(bytes);
        await WorkflowOutput.save(context, 'form_data.xfdf', data, mimeType: 'application/vnd.adobe.xfdf');
        break;
      case 'xfa':
        await _show(context, 'XFA data', await _forms.xfa(bytes));
        break;
      case 'flattenforms':
        await WorkflowOutput.updateCurrent(context, await _sanitize.flattenForms(bytes));
        break;
      case 'convertxfa':
        final converted = await _forms.convertXfa(bytes);
        await WorkflowOutput.updateCurrent(context, converted, name: 'converted_form.pdf');
        break;
    }
  }

  Future<void> _show(BuildContext context, String title, Object result) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 540, child: SingleChildScrollView(child: SelectableText(result.toString()))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}
