import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../widgets/home/dashboard_header.dart';
import '../../widgets/home/tool_catalog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller, required this.onTool});
  final AppController controller;
  final ValueChanged<ToolEntry> onTool;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DashboardHeader(
            title: 'All PDF tools',
            subtitle: 'Everything you need to work with PDF documents.',
            onOpen: controller.openPdf,
          ),
          const SizedBox(height: 30),
          const Text('Popular PDF tools', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF292D33))),
          const SizedBox(height: 5),
          const Text('Everything you need to work with documents.', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ToolCatalog(onTool: onTool),
        ]),
      );

}
