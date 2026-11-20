import 'package:flutter/material.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/conversion/pdf_standards_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class StandardsWorkflow implements ToolWorkflow {
  final _standards = PdfStandardsService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes!;
    if (tool.id == 'convertpdfa') {
      await WorkflowOutput.updateCurrent(context, await _standards.convertToPdfA(bytes));
      return;
    }
    final report = tool.id == 'pdfa'
        ? await _standards.validatePdfA(bytes)
        : await _standards.validatePdfUa(bytes);
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text('${tool.title} report'),
      content: SelectableText(report.toString()),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }
}
