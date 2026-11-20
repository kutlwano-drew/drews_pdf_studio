import 'package:flutter/material.dart';

import '../core/state/studio_scope.dart';
import '../widgets/common/empty_document_state.dart';
import '../widgets/common/app_error_dialog.dart';
import '../widgets/workspace/document_details_panel.dart';
import '../widgets/workspace/document_toolbar.dart';
import '../widgets/workspace/pdf_preview.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StudioScope.watch(context);
    final source = controller.currentDocument;
    if (source == null) {
      return EmptyDocumentState(onOpen: () async {
        await controller.openPdf();
        if (!context.mounted) return;
        if (controller.errorMessage != null) {
          await AppErrorDialog.show(context, title: 'Could not open PDF', message: controller.errorMessage!);
          controller.clearMessages();
        }
      });
    }

    final document = source.copyWith(
      bytes: controller.activeDocumentBytes ?? source.bytes,
      pageCount: controller.workingPageCount ?? source.pageCount,
      isModified: controller.hasWorkingCopy || source.isModified,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final showDetails = constraints.maxWidth >= 760;
      return Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: const DocumentToolbar(),
        ),
        Expanded(child: Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(18), child: PdfPreview(document: document))),
          if (showDetails) DocumentDetailsPanel(document: document),
        ])),
      ]);
    });
  }
}
