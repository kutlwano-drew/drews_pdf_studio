import 'package:flutter/material.dart';
import '../../core/catalog/tool_catalog.dart';
import '../../core/models/tool_category.dart';
import '../../core/models/tool_definition.dart';
import 'tool_tile.dart';

class ToolGrid extends StatelessWidget {
  const ToolGrid({super.key, this.category, required this.onToolTap});
  final ToolCategory? category;
  final ValueChanged<ToolDefinition> onToolTap;

  @override
  Widget build(BuildContext context) {
    final tools = category == null ? ToolCatalog.all : ToolCatalog.inCategory(category!);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / 190).floor().clamp(2, 5).toInt();
      return GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: tools.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.18,
        ),
        itemBuilder: (context, index) => ToolTile(tool: tools[index], onTap: () => onToolTap(tools[index])),
      );
    });
  }
}
