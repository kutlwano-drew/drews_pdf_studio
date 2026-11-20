import 'dart:io';

Future<String> currentDeviceArchitecture() async {
  if (Platform.isWindows) {
    final value = (Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '').toLowerCase();
    return value.contains('arm') ? 'arm64' : 'x64';
  }
  if (Platform.isLinux || Platform.isMacOS) {
    try {
      final result = await Process.run('uname', ['-m']);
      final value = result.stdout.toString().trim().toLowerCase();
      if (value.contains('aarch64') || value.contains('arm64')) return 'arm64';
      if (value.contains('x86_64') || value.contains('amd64')) return 'x64';
    } catch (_) {}
  }
  return 'arm64';
}
