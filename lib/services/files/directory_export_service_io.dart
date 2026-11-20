import 'dart:io';
import 'dart:typed_data';

Future<bool> exportFilesToDirectory(
  String directory,
  Map<String, Uint8List> files,
) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  for (final entry in files.entries) {
    await File('${dir.path}${Platform.pathSeparator}${entry.key}')
        .writeAsBytes(entry.value, flush: true);
  }
  return true;
}
