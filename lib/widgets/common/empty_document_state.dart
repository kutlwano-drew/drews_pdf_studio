import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EmptyDocumentState extends StatelessWidget {
  const EmptyDocumentState({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 64, color: Color(0xFFB7BFCC)),
              const SizedBox(height: 18),
              Text('empty.title'.tr(), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('empty.body'.tr(), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                onPressed: onOpen,
                icon: const Icon(Icons.upload_file),
                label: Text('menu.open'.tr()),
              ),
            ],
          ),
        ),
      );
}
