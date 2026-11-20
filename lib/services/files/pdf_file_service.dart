import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'picked_file.dart';

class PdfFileService {
  Future<PickedFile?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return null;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  }

  Future<List<PickedFile>> pickPdfs() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    return _convertFiles(files);
  }

  Future<List<PickedFile>> pickFiles(List<String> extensions) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return _convertFiles(files);
  }

  Future<List<PickedFile>> pickManyFiles({
    List<String>? extensions,
  }) async {
    final files = extensions == null || extensions.isEmpty
        ? await FilePicker.pickFiles(type: FileType.any)
        : await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: extensions,
          );
    return _convertFiles(files);
  }

  Future<PickedFile?> pickAnyFile({
    List<String>? extensions,
  }) async {
    final file = extensions == null || extensions.isEmpty
        ? await FilePicker.pickFile(type: FileType.any)
        : await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: extensions,
          );
    if (file == null) return null;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  }

  Future<PickedFile?> pickFile(List<String> extensions) =>
      pickAnyFile(extensions: extensions);

  Future<void> savePdf(String name, List<int> bytes) =>
      saveBytes(name, bytes, mimeType: 'application/pdf');

  Future<void> saveBytes(
    String name,
    List<int> bytes, {
    required String mimeType,
  }) async {
    await FilePicker.saveFile(
      fileName: name,
      bytes: Uint8List.fromList(bytes),
      mimeType: mimeType,
    );
  }

  Future<List<PickedFile>> _convertFiles(List<PlatformFile> files) async {
    final result = <PickedFile>[];
    for (final file in files) {
      result.add(
        PickedFile(
          name: file.name,
          bytes: await file.readAsBytes(),
        ),
      );
    }
    return result;
  }
}
