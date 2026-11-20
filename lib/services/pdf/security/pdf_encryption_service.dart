import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfEncryptionService {
  Future<Uint8List> encrypt(Uint8List bytes, String password) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.resave(
      PdfEngine.instance.input(bytes), sink,
      save: PdfSave.full(encryption: PdfEncryption.password(
        ownerPassword: password,
        algorithm: PdfEncryptionAlgorithm.aesKey256,
      )),
    );
    return sink.takeBytes();
  }

  Future<Uint8List> decrypt(Uint8List bytes, String password) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.resave(
      PdfEngine.instance.input(bytes, password: password), sink,
      save: PdfSave.full(encryption: PdfEncryption.remove()),
    );
    return sink.takeBytes();
  }
}
