import 'package:flutter/material.dart';

import '../../core/state/studio_scope.dart';
import 'workspace_action_dialog.dart';

class WorkspaceActionOverlay {
  static Future<void> show(BuildContext context) async {
    final controller = StudioScope.read(context);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.42),
      builder: (dialogContext) => WorkspaceActionDialog(
        controller: controller,
        hostContext: context,
      ),
    );
  }
}
