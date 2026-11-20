import 'package:flutter/material.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/security/pdf_encryption_service.dart';
import '../../../services/pdf/security/pdf_sanitize_service.dart';
import '../../../services/pdf/security/pdf_signature_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class SecurityWorkflow implements ToolWorkflow {
  final _encryption = PdfEncryptionService();
  final _sanitize = PdfSanitizeService();
  final _signatures = PdfSignatureService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes!;
    if (tool.id == 'signatures' || tool.id == 'verify') {
      final report = tool.id == 'verify'
          ? await _signatures.verify(bytes)
          : await _signatures.inspect(bytes);
      if (context.mounted) await _showReport(context, tool.title, report);
      return;
    }
    if (tool.id == 'sign') {
      final certificate = await controller.files.pickFile(['p12', 'pfx']);
      if (certificate == null) return;
      final signed = await _signatures.sign(bytes, certificate.bytes, value);
      await WorkflowOutput.updateCurrent(context, signed);
      return;
    }
    final result = switch (tool.id) {
      'encrypt' => await _encryption.encrypt(bytes, value),
      'decrypt' => await _encryption.decrypt(bytes, value),
      _ => await _sanitize.sanitize(bytes),
    };
    await WorkflowOutput.updateCurrent(context, result);
  }

  Future<void> _showReport(BuildContext context, String title, Object report) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: SelectableText(report.toString()))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}
