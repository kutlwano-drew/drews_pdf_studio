import 'tool_category.dart';

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconCode,
    this.requiresDocument = true,
  });

  final String id;
  final String title;
  final String description;
  final ToolCategory category;
  final int iconCode;
  final bool requiresDocument;
}
