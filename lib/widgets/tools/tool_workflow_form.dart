import 'package:flutter/material.dart';
import '../../core/models/tool_definition.dart';
import 'tool_workflow_form_state.dart';

class ToolWorkflowForm extends StatefulWidget {
  const ToolWorkflowForm({super.key, required this.tool});
  final ToolDefinition tool;
  @override
  ToolWorkflowFormState createState() => ToolWorkflowFormState();
}
