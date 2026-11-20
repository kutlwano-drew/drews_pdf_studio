import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class UploadBanner extends StatelessWidget {
  const UploadBanner({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity, padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 42, color: Color(0xFFE84B3C)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('dashboard.prompt'.tr(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            SizedBox(height: 5), Text('dashboard.upload'.tr(), style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)), onPressed: onOpen, child: Text('dashboard.select_pdf'.tr())),
        ]),
      );
}
