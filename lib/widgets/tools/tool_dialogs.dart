import 'package:flutter/material.dart';

class ToolDialogs {
  static Future<String?> ask(
    BuildContext context,
    String title,
    String label, {
    String initial = '',
    int maxLines = 1,
  }) async {
    final input = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: input,
          autofocus: true,
          minLines: maxLines > 1 ? 4 : 1,
          maxLines: maxLines,
          keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
          decoration: InputDecoration(labelText: label, alignLabelWithHint: maxLines > 1),
          onSubmitted: maxLines == 1 ? (value) => Navigator.pop(dialogContext, value) : null,
        ),
        actions: [
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white), onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), onPressed: () => Navigator.pop(dialogContext, input.text), child: const Text('Continue')),
        ],
      ),
    );
    input.dispose();
    return result;
  }

  static Future<void> showText(BuildContext context, String title, String text) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(child: SelectableText(text.isEmpty ? 'No results.' : text)),
          ),
          actions: [FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white), onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
        ),
      );

  static void message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
