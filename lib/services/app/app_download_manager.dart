import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'download_file.dart' as file_ops;

class AppDownloadManager extends ChangeNotifier {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  bool isDownloading = false;
  bool isDismissed = false;
  bool isComplete = false;
  bool installerOpened = false;
  double progress = 0;
  String? fileName;
  String? savedPath;
  String? error;

  Future<bool> downloadAndOpen(String url, {String? expectedSha256}) async {
    if (kIsWeb) {
      error = 'Installer downloads are not supported in the web build.';
      notifyListeners();
      return false;
    }
    _cancelToken = CancelToken();
    isDownloading = true;
    isDismissed = false;
    isComplete = false;
    installerOpened = false;
    progress = 0;
    error = null;
    final uri = Uri.parse(url);
    fileName = (uri.pathSegments.isEmpty ? 'pdf-studio-update' : uri.pathSegments.last).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    notifyListeners();
    try {
      final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final destination = path.join(directory.path, fileName ?? 'pdf-studio-update');
      await _dio.download(
        url,
        destination,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) progress = received / total;
          notifyListeners();
        },
      );
      if (expectedSha256 != null && expectedSha256.isNotEmpty) {
        final valid = await file_ops.verifyAndDeleteOnMismatch(destination, expectedSha256);
        if (!valid) throw StateError('The downloaded file failed its SHA-256 integrity check.');
      }
      savedPath = destination;
      isDownloading = false;
      isComplete = true;
      notifyListeners();
      final result = await OpenFilex.open(destination);
      installerOpened = result.type == ResultType.done;
      if (!installerOpened) error = 'The download completed, but the system could not open the installer: ${result.message}';
      notifyListeners();
      return installerOpened;
    } catch (exception) {
      isDownloading = false;
      error = exception is DioException && CancelToken.isCancel(exception)
          ? 'Download cancelled.'
          : exception.toString();
      notifyListeners();
      return false;
    }
  }

  void cancel() {
    _cancelToken?.cancel('Cancelled by user');
    isDownloading = false;
    notifyListeners();
  }

  void dismiss() {
    isDismissed = true;
    notifyListeners();
  }

  void show() {
    isDismissed = false;
    notifyListeners();
  }

  void clear() {
    isDownloading = false;
    isDismissed = true;
    isComplete = false;
    installerOpened = false;
    progress = 0;
    error = null;
    fileName = null;
    savedPath = null;
    notifyListeners();
  }
}
