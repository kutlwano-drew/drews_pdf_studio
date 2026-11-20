import 'package:flutter/material.dart';

import 'image_tools_dialog_view.dart';

class ImageToolsDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => const ImageToolsDialogView(),
    );
  }
}
