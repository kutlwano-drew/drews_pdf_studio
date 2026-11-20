import 'package:flutter/material.dart';

class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        width: 224,
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 22, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: const Color(0xFFFFE9E8), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE53935)),
              ),
              const SizedBox(width: 10),
              const Text('Drew’s PDF Studio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 34),
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 10),
              child: Text('WORKSPACE', style: TextStyle(color: Color(0xFF8A9099), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ),
            _item(Icons.home_outlined, 'Home', 0),
            _item(Icons.grid_view_rounded, 'All PDF tools', 1),
            _item(Icons.history_rounded, 'Recent files', 2),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lock_outline_rounded, color: Color(0xFF737B86), size: 19),
                SizedBox(height: 8),
                Text('Your files stay yours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                SizedBox(height: 4),
                Text('PDF processing runs locally in this app.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35)),
              ]),
            ),
          ],
        ),
      );

  Widget _item(IconData icon, String label, int index) {
    final active = selected == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: () => onSelected(index),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE53935) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(children: [
            Icon(icon, size: 19, color: active ? Colors.white : const Color(0xFFBDBDBD)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.white : const Color(0xFFE0E0E0))),
          ]),
        ),
      ),
    );
  }
}
