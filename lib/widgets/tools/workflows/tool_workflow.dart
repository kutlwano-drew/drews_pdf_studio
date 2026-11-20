import 'package:flutter/widgets.dart';
import '../../../core/models/tool_definition.dart';

abstract interface class ToolWorkflow {
  Future<void> run(BuildContext context, ToolDefinition tool, String value);
}
