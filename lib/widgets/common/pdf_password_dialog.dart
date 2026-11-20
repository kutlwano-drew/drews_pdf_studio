import 'package:flutter/material.dart';

class PdfPasswordDialog {
  static Future<String?> request(BuildContext context) async {
    final input = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Password-protected PDF'),
        content: TextField(
          controller: input,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Document password'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, input.text), child: const Text('Unlock')),
        ],
      ),
    );
    input.dispose();
    return password;
  }
}
