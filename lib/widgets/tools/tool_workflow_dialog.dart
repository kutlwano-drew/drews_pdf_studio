import 'package:flutter/material.dart';

import '../../core/models/tool_definition.dart';
import '../../core/state/studio_scope.dart';
import '../common/app_error_dialog.dart';
import 'tool_workflow_form.dart';

class ToolWorkflowDialog {
  static Future<void> open(BuildContext context, ToolDefinition tool) async {
    final controller = StudioScope.read(context);

    if (tool.requiresDocument && controller.activeDocumentBytes == null) {
      controller.clearMessages();
      await controller.openPdf();
      if (!context.mounted) return;
      if (controller.activeDocumentBytes == null) {
        final message = controller.errorMessage;
        if (message != null) {
          await AppErrorDialog.show(
            context,
            title: 'Could not open PDF',
            message: message,
          );
          controller.clearMessages();
        }
        return;
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ToolWorkflowForm(tool: tool),
      ),
    );
  }
}
