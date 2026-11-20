import 'package:flutter/material.dart';

class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key, required this.message, this.isError = false});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFEEEE) : const Color(0xFFEAF6EF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message, style: TextStyle(color: isError ? Colors.red.shade800 : Colors.green.shade800)),
      );
}
