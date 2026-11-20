import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app/app_download_manager.dart';
import '../../services/app/app_update_release.dart';
import '../../services/app/app_update_service.dart';
import '../../services/app/device_architecture.dart';

class AppUpdateDialogs {
  static const _formats = <String, String>{
    'windows_x64_exe': 'Windows x64 (.exe)',
    'windows_x64_zip': 'Windows portable (.zip)',
    'windows_x64_msi': 'Windows x64 (.msi)',
    'windows_x64': 'Windows x64 installer',
    'windows_arm64': 'Windows ARM64 portable (.zip) ',
    'linux_snap_store': 'Snapcraft download (Snap Store)',
    'linux_snap_binary': 'Linux snap binary (.snap)',
    'linux_appimage': 'Linux AppImage binary',
    'linux_amd64_deb': 'Linux amd64 (.deb)',
    'linux_x64_tar_gz': 'Linux x64 (.tar.gz)',
    'linux_x86_64_tar_gz': 'Linux x86_64 (.tar.gz)',
    'linux_x86_64_rpm': 'Linux x86_64 (.rpm)',
    'linux_x64': 'Linux x64 package',
    'linux_arm64': 'Linux ARM64 package',
    'macos_arm64_dmg': 'macOS arm64 (.dmg)',
    'macos_x64_zip': 'macOS x64 (.zip)',
    'macos_x64_dmg': 'macOS x64 (.dmg)',
    'macos_universal': 'macOS Universal (.dmg)',
    'android_apk': 'Android APK',
    'android_play_store': 'Google Play Store',
    'ios_ipa': 'iOS (.ipa)',
    'ios_app_store': 'Apple App Store',
  };

  static Future<void> check(BuildContext context, AppDownloadManager downloads) async {
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('menu.check_updates'.tr()),
        content: Row(children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 14),
          Expanded(child: Text('download.checking'.tr())),
        ]),
      ),
    ));

    AppUpdateRelease? release;
    Object? failure;
    try {
      release = await AppUpdateService().checkForUpdate();
    } catch (error) {
      failure = error;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (failure != null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('menu.check_updates'.tr()),
          content: Text(failure.toString().contains('not been configured')
              ? 'menu.update_unconfigured'.tr()
              : '${'download.check_failed'.tr()} $failure'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.close'.tr()))],
        ),
      );
      return;
    }
    if (release == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('menu.no_updates'.tr())));
      return;
    }
    await _showAvailable(context, release, downloads);
  }

  static Future<void> _showAvailable(
    BuildContext context,
    AppUpdateRelease release,
    AppDownloadManager downloads,
  ) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.6),
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF171717),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
        child: SizedBox(
          width: 620,
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 12),
              child: Row(children: [
                const Icon(Icons.system_update_alt_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${'menu.update_available'.tr()} · v${release.version}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
                IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: Markdown(
                data: release.whatsNew,
                selectable: true,
                padding: const EdgeInsets.all(22),
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: const TextStyle(color: Colors.white, height: 1.5),
                  h1: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  h3: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  listBullet: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(child: _darkButton('menu.cancel'.tr(), color: Colors.redAccent, onPressed: () => Navigator.pop(dialogContext))),
                const SizedBox(width: 10),
                Expanded(child: _darkButton('menu.release_info'.tr(), onPressed: () => _showReleaseInfo(context, release))),
                const SizedBox(width: 10),
                Expanded(child: _darkButton('menu.download'.tr(), onPressed: () => _showDownloads(context, release, downloads))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  static Widget _darkButton(String label, {Color color = Colors.white, required VoidCallback onPressed}) =>
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.black.withOpacity(.7),
          side: const BorderSide(color: Colors.white70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
        onPressed: onPressed,
        child: FittedBox(child: Text(label)),
      );

  static Future<void> _showReleaseInfo(BuildContext context, AppUpdateRelease release) async {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: SizedBox(
            width: 650,
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(children: [
              ListTile(title: Text('menu.release_info'.tr()), trailing: IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close))),
              const Divider(height: 1),
              Expanded(child: Markdown(data: release.releaseNotes, selectable: true, padding: const EdgeInsets.all(20))),
            ]),
          ),
        ),
      );
  }

  static Future<void> _showDownloads(
    BuildContext context,
    AppUpdateRelease release,
    AppDownloadManager manager,
  ) async {
    final recommended = await _recommendedKey(release.downloads);
    final entries = _formats.entries.toList();
    final recommendedMatches = entries.where((entry) => entry.key == recommended).toList();
    final recommendedEntry = recommendedMatches.isEmpty ? null : recommendedMatches.first;
    final others = entries.where((entry) => entry.key != recommended).toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 540,
          height: MediaQuery.sizeOf(context).height * .76,
          child: Column(children: [
            ListTile(title: Text('menu.download'.tr()), trailing: IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close))),
            const Divider(height: 1),
            Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('menu.recommended'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (recommendedEntry != null)
                _downloadTile(context, dialogContext, release, manager, recommendedEntry, featured: true)
              else
                ListTile(leading: const Icon(Icons.info_outline), title: Text('download.no_recommended'.tr())),
              const SizedBox(height: 18),
              Text('menu.other_downloads'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final entry in others)
                _downloadTile(context, dialogContext, release, manager, entry),
            ])),
          ]),
        ),
      ),
    );
  }

  static Widget _downloadTile(
    BuildContext context,
    BuildContext dialogContext,
    AppUpdateRelease release,
    AppDownloadManager manager,
    MapEntry<String, String> entry, {
    bool featured = false,
  }) {
    final url = release.downloads[entry.key];
    return ListTile(
      dense: true,
      leading: Icon(featured ? Icons.star_rounded : Icons.download_outlined, color: url == null ? Colors.grey : null),
      title: Text(entry.value),
      subtitle: url == null ? Text('download.not_configured'.tr()) : null,
      enabled: url != null,
      onTap: url == null ? null : () async {
        Navigator.pop(dialogContext);
        if (kIsWeb || entry.key.endsWith('_store')) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          return;
        }
        final checksumKey = _checksumKey(entry.key);
        final checksum = checksumKey == null ? null : release.checksums[checksumKey];
        final opened = await manager.downloadAndOpen(url, expectedSha256: checksum);
        if (!context.mounted || !opened) return;
        await _showInstallPrompt(context);
      },
    );
  }


  static String? _checksumKey(String downloadKey) {
    if (downloadKey == 'windows_arm64') return 'windows_arm64';
    if (downloadKey.startsWith('windows_')) return 'windows_x64';
    if (downloadKey.startsWith('linux_arm64')) return 'linux_arm64';
    if (downloadKey.startsWith('linux_')) return 'linux_x64';
    if (downloadKey.startsWith('macos_arm64')) return 'macos_arm64';
    if (downloadKey.startsWith('macos_')) return 'macos_x64';
    if (downloadKey.startsWith('android_')) return 'android';
    if (downloadKey.startsWith('ios_')) return 'ios';
    return null;
  }

  static Future<String> _recommendedKey(Map<String, String> downloads) async {
    if (kIsWeb) return '';
    final architecture = await currentDeviceArchitecture();
    final preferred = switch (defaultTargetPlatform) {
      TargetPlatform.windows => architecture == 'arm64'
          ? ['windows_arm64', 'windows_x64_exe', 'windows_x64']
          : ['windows_x64_exe', 'windows_x64', 'windows_arm64'],
      TargetPlatform.linux => architecture == 'arm64'
          ? ['linux_arm64', 'linux_snap_binary', 'linux_appimage', 'linux_snap_store']
          : ['linux_amd64_deb', 'linux_x64_tar_gz', 'linux_x86_64_rpm', 'linux_x64', 'linux_appimage', 'linux_snap_binary', 'linux_snap_store'],
      TargetPlatform.macOS => architecture == 'arm64'
          ? ['macos_arm64_dmg', 'macos_universal', 'macos_x64_dmg']
          : ['macos_x64_dmg', 'macos_x64_zip', 'macos_universal'],
      TargetPlatform.android => ['android_apk', 'android_play_store'],
      TargetPlatform.iOS => ['ios_ipa', 'ios_app_store'],
      _ => <String>[],
    };
    return preferred.firstWhere((key) => downloads.containsKey(key), orElse: () => '');
  }

  static Future<void> _showInstallPrompt(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('common.download_complete'.tr()),
        content: Text('common.install_prompt'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('menu.cancel'.tr())),
          FilledButton(onPressed: () {
            Navigator.pop(dialogContext);
            SystemNavigator.pop();
          }, child: Text('menu.close_update'.tr())),
        ],
      ),
    );
  }
}
