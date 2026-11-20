import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/state/studio_scope.dart';

class WorkflowOutput {
  static Future<void> updateCurrent(
    BuildContext context,
    List<int> bytes, {
    String? name,
  }) async {
    await StudioScope.read(context).setWorkingCopy(bytes, name: name);
  }

  static Future<void> save(
    BuildContext context,
    String name,
    List<int> bytes, {
    String mimeType = 'application/pdf',
  }) async {
    final controller = StudioScope.read(context);
    await controller.files.saveBytes(
      name,
      Uint8List.fromList(bytes),
      mimeType: mimeType,
    );
    controller.statusMessage = 'Saved $name';
    controller.notifyListeners();
  }
}
