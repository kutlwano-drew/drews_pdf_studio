import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE84B3C),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 21),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            const Text("Drew's\nPDF Studio", style: TextStyle(fontSize: 16, height: 1.05, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ],
      );
}
