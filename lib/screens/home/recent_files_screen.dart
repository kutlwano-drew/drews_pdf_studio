import 'package:flutter/material.dart';
import '../../core/app_controller.dart';

class RecentFilesScreen extends StatelessWidget {
  const RecentFilesScreen({super.key, required this.controller, required this.onOpen});
  final AppController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(30),
        children: [
          const Text('Recent files', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (controller.recentDocuments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 70),
              child: Center(child: Text('PDFs you open will appear here.', style: TextStyle(color: Color(0xFF777E87)))),
            ),
          for (final document in controller.recentDocuments)
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE53935)),
                title: Text(document.name),
                subtitle: Text('${document.pageCount ?? '—'} pages${document.modified ? ' · Edited' : ''}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async { await controller.openBytes(document.name, document.bytes); onOpen(); },
              ),
            ),
        ],
      );
}
