import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/models/tool_category.dart';
import '../widgets/home/dashboard_header.dart';
import '../widgets/home/tool_grid.dart';
import '../widgets/common/section_title.dart';
import '../widgets/tools/tool_workflow_dialog.dart';

class ToolLibraryScreen extends StatelessWidget {
  const ToolLibraryScreen({super.key, required this.category});
  final ToolCategory category;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(30),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DashboardHeader(title: category.titleKey.tr(), subtitle: category.subtitleKey.tr()),
      const SizedBox(height: 28),
      SectionTitle(category.titleKey.tr()),
      const SizedBox(height: 16),
      ToolGrid(category: category, onToolTap: (tool) => ToolWorkflowDialog.open(context, tool)),
    ]),
  );
}
