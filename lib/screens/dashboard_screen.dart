import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/state/studio_scope.dart';
import '../widgets/home/dashboard_header.dart';
import '../widgets/home/tool_grid.dart';
import '../widgets/home/upload_banner.dart';
import '../widgets/common/section_title.dart';
import '../widgets/tools/tool_workflow_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = StudioScope.watch(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const DashboardHeader(),
        const SizedBox(height: 26),
        UploadBanner(onOpen: onOpen),
        const SizedBox(height: 30),
        SectionTitle('dashboard.popular'.tr(), subtitle: 'dashboard.choose'.tr()),
        const SizedBox(height: 16),
        ToolGrid(onToolTap: (tool) => ToolWorkflowDialog.open(context, tool)),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(controller.errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
      ]),
    );
  }
}
