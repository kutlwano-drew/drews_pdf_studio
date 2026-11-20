import 'dart:typed_data';

import 'package:pdf_manipulator/pdf_manipulator.dart';

import 'pdf_runtime.dart';

class PdfSecurityService {
  PdfSecurityService._();

  static final instance = PdfSecurityService._();

  final _runtime = PdfRuntime.instance;

  Future<Uint8List> encrypt(Uint8List bytes, String password) =>
      _runtime.output(
        (sink) => _runtime.engine.resave(
          _runtime.input(bytes),
          sink,
          save: PdfSave.full(
            encryption: PdfEncryption.password(
              ownerPassword: password,
              algorithm: PdfEncryptionAlgorithm.aesKey256,
            ),
          ),
        ),
      );

  Future<Uint8List> decrypt(Uint8List bytes, String password) =>
      _runtime.output(
        (sink) => _runtime.engine.resave(
          _runtime.input(bytes, password: password),
          sink,
          save: PdfSave.full(encryption: PdfEncryption.remove()),
        ),
      );

  Future<Uint8List> sign(
    Uint8List bytes, {
    required Uint8List pkcs12Certificate,
    required String certificatePassword,
  }) => _runtime.output(
    (sink) => _runtime.engine.sign(
      _runtime.input(bytes),
      sink,
      credentials: PdfSigningCredentials.pkcs12(
        MemorySource(pkcs12Certificate),
        certificatePassword,
      ),
    ),
  );
}
