import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../widgets/home/navigation.dart';
import '../../widgets/home/tool_catalog.dart';
import '../../widgets/tools/tool_action_handler.dart';
import '../workspace/pdf_workspace_screen.dart';
import 'dashboard_screen.dart';
import 'recent_files_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = AppController();
  int selected = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Scaffold(
          body: LayoutBuilder(builder: (context, constraints) {
            final showNavigation = constraints.maxWidth >= 900;
            return Row(children: [
              if (showNavigation)
                HomeNavigation(selected: selected, onSelected: (value) => setState(() => selected = value)),
              Expanded(child: Column(children: [
                _topBar(showNavigation),
                if (controller.busy) const LinearProgressIndicator(minHeight: 2),
                if (controller.error != null) _errorBanner(controller.error!),
                Expanded(child: _content()),
              ])),
            ]);
          }),
        ),
      );

  Widget _topBar(bool showNavigation) => Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(color: Colors.black, border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A)))),
        child: Row(children: [
          if (!showNavigation)
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE53935)),
          const Text("Drew's \nPDF Studio", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          if (controller.status != null && !controller.busy)
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(controller.status!, maxLines: 1, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
              ),
            ),
          TextButton.icon(
            onPressed: _openPdf,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Open PDF'),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFFFE9E8),
            child: const Text('D', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w800)),
          ),
        ]),
      );

  Widget _content() {
    if (controller.currentDocument != null && selected == 0) {
      return PdfWorkspaceScreen(controller: controller, onBack: () => setState(() => selected = 1));
    }
    if (selected == 2) return RecentFilesScreen(controller: controller, onOpen: () => setState(() => selected = 0));
    if (selected == 1) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 36),
        child: ToolCatalog(onTool: _runTool),
      );
    }
    return DashboardScreen(controller: controller, onTool: _runTool);
  }

  Future<void> _openPdf() async {
    await controller.openPdf();
    if (controller.currentDocument != null && mounted) setState(() => selected = 0);
  }

  Future<void> _runTool(ToolEntry entry) async {
    await ToolActionHandler(context, controller).run(entry);
    if (mounted && controller.currentDocument != null) {
      setState(() => selected = 0);
    }
  }

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        color: const Color(0xFFFFEEEE),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF9E2525), fontSize: 12))),
          IconButton(onPressed: controller.clearError, icon: const Icon(Icons.close, size: 16)),
        ]),
      );
}
