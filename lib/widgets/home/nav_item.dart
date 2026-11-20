import 'package:flutter/material.dart';

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Tooltip(
          message: label,
          child: Material(
            color: selected ? const Color(0xFFE53935) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 46,
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? const Color(0xFFE84B3C)
                        : const Color(0xFF737B86),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        selected: selected,
        selectedTileColor: const Color(0xFFE53935),
        leading: Icon(
          icon,
          size: 19,
          color: selected ? Colors.white : const Color(0xFFBDBDBD),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFFE0E0E0),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
