import 'package:dio/dio.dart';

import 'app_update_config.dart';
import 'app_update_release.dart';

class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  bool get isConfigured {
    final uri = Uri.tryParse(AppUpdateConfig.feedBaseUrl);
    return uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        !AppUpdateConfig.feedBaseUrl.contains(r'$enter url here $');
  }

  Future<AppUpdateRelease?> checkForUpdate() async {
    if (!isConfigured) throw StateError('The update feed URL has not been configured.');
    final base = AppUpdateConfig.feedBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final versionsText = await _getText('$base/versions.txt');
    final versionFolders = versionsText
        .split(RegExp(r'[\r\n,;]+'))
        .map((value) => value.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((value) => _isVersion(_normaliseVersion(value)))
        .toList();
    versionFolders.sort(_compareVersions);
    final newestFolder = versionFolders.isEmpty ? null : versionFolders.last;
    if (newestFolder == null) return null;
    final newest = _normaliseVersion(newestFolder);
    if (_compareVersions(newest, AppUpdateConfig.currentVersion) <= 0) return null;
    final releaseBase = '$base/$newestFolder';
    final values = await Future.wait([
      _getText('$releaseBase/release.md'),
      _getText('$releaseBase/whats_new.md'),
      _getText('$releaseBase/downloads.md'),
    ]);
    return AppUpdateRelease(
      version: newest,
      releaseNotes: values[0],
      whatsNew: values[1],
      downloads: _parseDownloads(values[2]),
      checksums: _parseChecksums(values[0]),
    );
  }

  Future<String> _getText(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Map<String, String> _parseDownloads(String source) {
    final result = <String, String>{};
    String? currentKey;
    for (final raw in source.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) {
        if (line.startsWith('###')) {
          currentKey = line.replaceFirst(RegExp(r'^#+\s*'), '').trim().toLowerCase();
        }
        continue;
      }
      final normalizedLine = line.replaceFirst(RegExp(r'^[-*]\s*'), '');
      final colon = RegExp(r'^([a-zA-Z0-9_\-]+)\s*:\s*(https?://\S+)$').firstMatch(normalizedLine);
      if (colon != null) {
        result[colon.group(1)!.toLowerCase()] = colon.group(2)!;
      } else if (line.startsWith('http://') || line.startsWith('https://')) {
        if (currentKey != null) result[currentKey] = line;
      }
    }
    return result;
  }

  Map<String, String> _parseChecksums(String source) {
    final result = <String, String>{};
    final expression = RegExp(r'sha256_([a-zA-Z0-9_]+)\s*:\s*([a-fA-F0-9]{64})');
    for (final match in expression.allMatches(source)) {
      result[match.group(1)!.toLowerCase()] = match.group(2)!.toLowerCase();
    }
    return result;
  }

  String _normaliseVersion(String value) => value.replaceFirst(RegExp(r'^[vV]'), '');

  bool _isVersion(String value) =>
      RegExp(r'^\d+(\.\d+){1,3}([\-+][0-9A-Za-z.-]+)?$').hasMatch(value);

  int _compareVersions(String a, String b) {
    final left = _normaliseVersion(a).split(RegExp(r'[+-]')).first.split('.').map(int.parse).toList();
    final right = _normaliseVersion(b).split(RegExp(r'[+-]')).first.split('.').map(int.parse).toList();
    for (var index = 0; index < 4; index++) {
      final x = index < left.length ? left[index] : 0;
      final y = index < right.length ? right[index] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
