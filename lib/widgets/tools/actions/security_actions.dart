import 'package:flutter/material.dart';
import '../../../core/app_controller.dart';
import '../../../services/pdf/pdf_read_service.dart';
import '../../../services/pdf/pdf_security_service.dart';
import '../tool_dialogs.dart';

class SecurityActions {
  SecurityActions(this.context, this.controller);
  final BuildContext context;
  final AppController controller;

  Future<void> password({required bool encrypt}) async {
    final password = await ToolDialogs.ask(context, encrypt ? 'Encrypt PDF' : 'Decrypt PDF', 'Password');
    if (password == null || password.isEmpty) return;
    if (encrypt) {
      await controller.encrypt(password);
    } else {
      await controller.decrypt(password);
    }
  }

  Future<void> sign() async {
    final certificate = await controller.files.pickAnyFile(extensions: const ['p12', 'pfx']);
    if (certificate == null) return;
    final password = await ToolDialogs.ask(context, 'Sign PDF', 'Certificate password');
    if (password == null) return;
    await controller.applyCustom(
      'Signing PDF…',
      (bytes) => PdfSecurityService.instance.sign(
        bytes,
        pkcs12Certificate: certificate.bytes,
        certificatePassword: password,
      ),
    );
  }

  Future<void> signatures() async {
    final document = controller.currentDocument;
    if (document == null) return;
    final signatures = await PdfReadService.instance.signatures(document.bytes);
    final valid = await PdfReadService.instance.verifySignatures(document.bytes);
    final detail = signatures.map((signature) => signature.toString()).join('\n\n');
    await ToolDialogs.showText(
      context,
      'Digital signatures',
      'Cryptographic verification: $valid\n\n$detail\n\nCertificate trust and revocation are not checked by this verification.',
    );
  }
}
