import 'package:flutter/material.dart';

import '../../core/state/studio_scope.dart';
import 'annotation_drawing_dialog_view.dart';

class AnnotationDrawingDialog {
  static Future<void> show(BuildContext context) async {
    if (StudioScope.read(context).currentDocument == null) return;
    await showDialog<void>(context: context, builder: (dialogContext) => const AnnotationDrawingDialogView());
  }
}
