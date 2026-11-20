import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/state/studio_scope.dart';
import '../common/app_error_dialog.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.title = '',
    this.subtitle = '',
    this.onOpen,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = StudioScope.watch(context);
    Future<void> openPdf() async {
      if (onOpen != null) {
        onOpen!();
        return;
      }
      await controller.openPdf();
      if (!context.mounted) return;
      if (controller.errorMessage != null) {
        await AppErrorDialog.show(
          context,
          title: 'Could not open PDF',
          message: controller.errorMessage!,
        );
        controller.clearMessages();
      }
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'dashboard.title'.tr() : title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle.isEmpty ? 'dashboard.subtitle'.tr() : subtitle,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
          onPressed: openPdf,
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text('menu.open'.tr()),
        ),
      ],
    );
  }
}
