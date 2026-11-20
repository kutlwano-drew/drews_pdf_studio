import 'package:flutter/material.dart';

import '../../core/state/studio_scope.dart';
import 'visual_crop_dialog_view.dart';

class VisualCropDialog {
  static Future<List<double>?> show(BuildContext context) async {
    if (StudioScope.read(context).currentDocument == null) return null;
    return showDialog<List<double>>(context: context, builder: (dialogContext) => const VisualCropDialogView());
  }
}
