import 'package:flutter/material.dart';
import '../../core/models/tool_category.dart';
import '../../core/models/tool_definition.dart';
import '../../core/state/studio_scope.dart';
import 'workflows/tool_workflow.dart';
import 'workflows/organization_workflow.dart';
import 'workflows/editing_workflow.dart';
import 'workflows/reading_workflow.dart';
import 'workflows/security_workflow.dart';
import 'workflows/optimization_workflow.dart';
import 'workflows/conversion_workflow.dart';
import 'workflows/creation_workflow.dart';
import 'workflows/forms_workflow.dart';
import 'workflows/standards_workflow.dart';

class ToolWorkflowExecutor {
  static Future<void> execute(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    if (tool.requiresDocument && controller.activeDocumentBytes == null) {
      await controller.openPdf();
      if (controller.activeDocumentBytes == null) return;
    }
    final ToolWorkflow workflow = switch (tool.category) {
      ToolCategory.organize => OrganizationWorkflow(),
      ToolCategory.edit => EditingWorkflow(),
      ToolCategory.read => ReadingWorkflow(),
      ToolCategory.security => SecurityWorkflow(),
      ToolCategory.optimize => OptimizationWorkflow(),
      ToolCategory.convert => ConversionWorkflow(),
      ToolCategory.create => CreationWorkflow(),
      ToolCategory.forms => FormsWorkflow(),
      ToolCategory.standards => StandardsWorkflow(),
    };
    await workflow.run(context, tool, value);
  }
}
