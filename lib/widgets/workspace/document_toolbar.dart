import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/state/studio_controller.dart';
import '../../core/state/studio_scope.dart';
import '../common/app_error_dialog.dart';
import 'workspace_action_overlay.dart';

class DocumentToolbar extends StatelessWidget {
  const DocumentToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StudioScope.watch(context);
    final document = controller.currentDocument;
    final displayedName = document?.name ?? 'No document';
    final displayedPageCount = controller.workingPageCount ?? document?.pageCount;

    return Row(children: [
      const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE84B3C), size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(displayedName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(
            'workspace.workspace'.tr(),
            style: const TextStyle(fontSize: 10, color: Colors.black),
          ),
        ]),
      ),
      if (displayedPageCount != null && MediaQuery.sizeOf(context).width > 520)
        Padding(padding: const EdgeInsets.only(right: 8), child: Text('$displayedPageCount pages', style: const TextStyle(color: Colors.black54, fontSize: 11))),
      IconButton(
        tooltip: 'workspace.undo'.tr(),
        onPressed: controller.canUndo && !controller.isBusy ? controller.undo : null,
        icon: const Icon(Icons.undo_rounded, size: 19),
      ),
      IconButton(
        tooltip: 'workspace.redo'.tr(),
        onPressed: controller.canRedo && !controller.isBusy ? controller.redo : null,
        icon: const Icon(Icons.redo_rounded, size: 19),
      ),
      IconButton(
        tooltip: 'workspace.compare'.tr(),
        onPressed: controller.hasWorkingCopy ? () => WorkspaceActionOverlay.show(context) : null,
        icon: const Icon(Icons.compare_arrows_rounded, size: 19),
      ),
      IconButton(
        tooltip: 'workspace.quick_actions'.tr(),
        onPressed: () => WorkspaceActionOverlay.show(context),
        icon: const Icon(Icons.tune_rounded, size: 19),
      ),
      IconButton(
        tooltip: 'workspace.save'.tr(),
        onPressed: document == null ? null : () => _save(context, controller),
        icon: const Icon(Icons.save_outlined, size: 19),
      ),
    ]);
  }

  Future<void> _save(BuildContext context, StudioController controller) async {
    await controller.runTask(
      'Saving PDF…',
      controller.hasWorkingCopy
          ? controller.exportWorkingCopy
          : () async {
              final document = controller.currentDocument;
              if (document != null) await controller.files.savePdf(document.name, document.bytes);
            },
    );
    if (!context.mounted) return;
    if (controller.errorMessage != null) {
      await AppErrorDialog.show(context, title: 'Could not save PDF', message: controller.errorMessage!);
      controller.clearMessages();
    }
  }
}
