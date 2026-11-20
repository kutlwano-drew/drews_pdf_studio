import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../services/app/app_download_manager.dart';

class DownloadStatusButton extends StatelessWidget {
  const DownloadStatusButton({super.key, required this.manager});
  final AppDownloadManager manager;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: manager,
        builder: (context, _) {
          if (!manager.isDownloading && !manager.isComplete && manager.error == null) {
            return const SizedBox.shrink();
          }
          return IconButton(
            tooltip: 'download.status'.tr(),
            onPressed: () => _showDetails(context),
            icon: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.download_rounded),
              if (manager.isDownloading)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(value: manager.progress == 0 ? null : manager.progress, strokeWidth: 2),
                ),
              if (manager.isComplete && manager.error == null)
                const Positioned(right: 0, bottom: 0, child: Icon(Icons.check_circle, size: 11, color: Colors.green)),
            ]),
          );
        },
      );

  Future<void> _showDetails(BuildContext context) async {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AnimatedBuilder(
          animation: manager,
          builder: (context, _) => AlertDialog(
            title: Row(children: [
              const Icon(Icons.download_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text(manager.isDownloading ? 'download.downloading'.tr() : 'download.status'.tr())),
              IconButton(onPressed: () { manager.dismiss(); Navigator.pop(dialogContext); }, tooltip: 'download.dismiss'.tr(), icon: const Icon(Icons.close)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(manager.fileName ?? 'download.installer'.tr()),
                const SizedBox(height: 12),
                if (manager.isDownloading) ...[
                  LinearProgressIndicator(value: manager.progress == 0 ? null : manager.progress),
                  const SizedBox(height: 8),
                  Text('${(manager.progress * 100).round()}%'),
                ],
                if (manager.isComplete) Text('common.download_complete'.tr()),
                if (manager.error != null) Text(manager.error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
            actions: [
              if (manager.isDownloading)
                TextButton(onPressed: manager.cancel, child: Text('download.cancel'.tr())),
              TextButton(onPressed: () { manager.dismiss(); Navigator.pop(dialogContext); }, child: Text('common.close'.tr())),
            ],
          ),
        ),
      );
  }
}
