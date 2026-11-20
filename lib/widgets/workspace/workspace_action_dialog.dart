import 'package:flutter/material.dart';

import '../../core/state/studio_controller.dart';
import 'workspace_action_dialog_state.dart';

class WorkspaceActionDialog extends StatefulWidget {
  const WorkspaceActionDialog({required this.controller, required this.hostContext});

  final StudioController controller;
  final BuildContext hostContext;

  @override
  WorkspaceActionDialogState createState() => WorkspaceActionDialogState();
}
