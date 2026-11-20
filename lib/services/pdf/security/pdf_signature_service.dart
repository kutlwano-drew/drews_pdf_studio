import 'dart:typed_data';

import 'package:pdf_manipulator/pdf_manipulator.dart';

import '../pdf_engine.dart';

class PdfSignatureService {
  Future<Uint8List> sign(
    Uint8List bytes,
    Uint8List certificate,
    String certificatePassword,
  ) async {
    final sink = MemorySink();

    await PdfEngine.instance.pdf.sign(
      PdfEngine.instance.input(bytes),
      sink,
      credentials: PdfSigningCredentials.pkcs12(
        MemorySource(certificate),
        certificatePassword,
      ),
    );

    return sink.takeBytes();
  }

  Future<dynamic> inspect(Uint8List bytes) {
    return PdfEngine.instance.pdf.read(
      PdfEngine.instance.input(bytes),
      (document) => document.signatures(),
    );
  }

  Future<dynamic> verify(Uint8List bytes) {
    return PdfEngine.instance.pdf.read(
      PdfEngine.instance.input(bytes),
      (document) => document.verifySignatures(),
    );
  }
}
