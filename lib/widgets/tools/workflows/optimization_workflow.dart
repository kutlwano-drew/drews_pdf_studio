import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/optimization/pdf_compression_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class OptimizationWorkflow implements ToolWorkflow {
  final _compression = PdfCompressionService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final bytes = StudioScope.read(context).activeDocumentBytes!;
    final policy = switch (value.toLowerCase()) {
      'screen' => PdfImagePolicy.screen,
      'print' => PdfImagePolicy.print,
      'lossless' => PdfImagePolicy.lossless,
      _ => PdfImagePolicy.ebook,
    };
    final result = tool.id == 'unembed'
        ? await _compression.unembedFonts(bytes)
        : await _compression.compress(bytes, policy);
    await WorkflowOutput.updateCurrent(context, result);
  }
}
