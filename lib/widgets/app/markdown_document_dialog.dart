import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownDocumentDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String markdown,
  }) async {
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 760,
            height: MediaQuery.sizeOf(context).height * .82,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                  child: Row(children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close)),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Markdown(
                    data: markdown,
                    selectable: true,
                    padding: const EdgeInsets.all(22),
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      h1: Theme.of(context).textTheme.headlineSmall,
                      h2: Theme.of(context).textTheme.titleLarge,
                      a: const TextStyle(color: Color(0xFF1565C0), decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
