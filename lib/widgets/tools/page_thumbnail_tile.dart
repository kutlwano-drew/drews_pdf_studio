import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PageThumbnailTile extends StatelessWidget {
  const PageThumbnailTile({
    super.key,
    required this.pageNumber,
    required this.selected,
    required this.selectionEnabled,
    required this.thumbnail,
    required this.onPreview,
    this.onTap,
  });

  final int pageNumber;
  final bool selected;
  final bool selectionEnabled;
  final Future<Uint8List> thumbnail;
  final VoidCallback onPreview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFFE84B3C) : const Color(0xFFE1E5EB);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: selected ? 2 : 1)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Expanded(child: Stack(fit: StackFit.expand, children: [
              Container(
                color: const Color(0xFFF0F2F5),
                alignment: Alignment.center,
                child: FutureBuilder<Uint8List>(
                  future: thumbnail,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF9AA2AE), size: 38);
                    if (!snapshot.hasData) return const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2));
                    return Image.memory(snapshot.data!, fit: BoxFit.contain, gaplessPlayback: true);
                  },
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.96),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'workflow.preview_page'.tr(args: ['$pageNumber']),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                  ),
                ),
              ),
              if (selectionEnabled)
                Positioned(
                  top: 8,
                  left: 8,
                  child: selected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFFE84B3C),
                          size: 20,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.black87,
                          size: 20,
                        ),
                ),
            ])),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: Text(
                selectionEnabled && selected
                    ? 'workflow.selected_page'.tr(args: ['$pageNumber'])
                    : 'workflow.page'.tr(args: ['$pageNumber']),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF343A43)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
