import 'dart:io';

import 'package:crypto/crypto.dart';

Future<bool> verifyAndDeleteOnMismatch(String path, String expectedSha256) async {
  final file = File(path);
  final digest = sha256.convert(await file.readAsBytes()).toString();
  if (digest.toLowerCase() == expectedSha256.toLowerCase()) return true;
  await file.delete();
  return false;
}
