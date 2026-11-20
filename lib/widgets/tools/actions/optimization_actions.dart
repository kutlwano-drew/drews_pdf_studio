import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../../../core/app_controller.dart';

class OptimizationActions {
  OptimizationActions(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> compress() async {
    final policy = await showDialog<PdfImagePolicy>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Compression profile'),
        children: [
          _option(dialogContext, 'Screen · 72 PPI', PdfImagePolicy.screen),
          _option(dialogContext, 'Ebook · 150 PPI', PdfImagePolicy.ebook),
          _option(dialogContext, 'Print · 300 PPI', PdfImagePolicy.print),
          _option(dialogContext, 'Lossless · no quality loss', PdfImagePolicy.lossless),
        ],
      ),
    );
    if (policy != null) await controller.compress(policy);
  }

  SimpleDialogOption _option(BuildContext context, String label, PdfImagePolicy policy) =>
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, policy),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(label)),
      );
}
