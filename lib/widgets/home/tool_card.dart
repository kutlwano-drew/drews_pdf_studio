import 'package:flutter/material.dart';

class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.title, required this.description, required this.icon, required this.onTap, this.accent = const Color(0xFFE53935)});
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF2A2A2A))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(height: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF25282D))),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35)),
            ]),
          ),
        ),
      );
}
