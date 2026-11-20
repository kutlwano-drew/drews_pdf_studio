import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../services/files/picked_file.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/creation/pdf_creation_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class CreationWorkflow implements ToolWorkflow {
  final _creation = PdfCreationService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    if (tool.id == 'images') {
      final files = await controller.files.pickFiles(['png', 'jpg', 'jpeg']);
      if (files.isEmpty) return;
      final orderedFiles = await _arrangeImages(context, files);
      if (orderedFiles == null || orderedFiles.isEmpty) return;
      final bytes = await _creation.fromImages(
        orderedFiles.map((file) => file.bytes).toList(),
      );
      await _openResult(context, 'images.pdf', bytes);
      return;
    }
    if (tool.id == 'createtable') {
      final decoded = jsonDecode(value);
      final rows = (decoded as List)
          .map((row) => (row as List).map((cell) => '$cell').toList())
          .toList();
      final bytes = await _creation.fromTable(rows);
      await _openResult(context, 'table.pdf', bytes);
      return;
    }
    if (tool.id == 'createshapes') {
      await _openResult(context, 'shapes.pdf', await _creation.fromShapes());
      return;
    }
    if (tool.id == 'createform') {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final template = decoded['template']?.toString() ?? 'Custom';
      final fields = (decoded['fields'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, String>.from(
                (item as Map).map(
                  (key, value) => MapEntry('$key', '$value'),
                ),
              ))
          .toList();
      final bytes = await _creation.fromFormTemplate(
        title: '$template form',
        fields: fields,
      );
      await _openResult(context, 'fillable_form.pdf', bytes);
      return;
    }
    final parts = value.split('|');
    final title = parts.first.trim().isEmpty ? 'New document' : parts.first.trim();
    final body = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';
    await _openResult(context, 'created_document.pdf', await _creation.fromMarkdown(title, body));
  }

  Future<void> _openResult(BuildContext context, String name, List<int> bytes) async {
    await WorkflowOutput.updateCurrent(context, bytes, name: name);
  }
}

  Future<List<PickedFile>?> _arrangeImages(
    BuildContext context,
    List<PickedFile> files,
  ) async {
    final ordered = List<PickedFile>.of(files);
    return showDialog<List<PickedFile>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(children: [
            Expanded(child: Text('Arrange images · ${ordered.length} pages')),
            TextButton.icon(
              onPressed: () async {
                final added = await StudioScope.read(context).files.pickFiles(['png', 'jpg', 'jpeg']);
                if (!dialogContext.mounted || added.isEmpty) return;
                setDialogState(() => ordered.addAll(added));
              },
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add images'),
            ),
          ]),
          content: SizedBox(
            width: 600,
            height: 460,
            child: ordered.isEmpty
                ? const Center(child: Text('Add at least one image to create the PDF.'))
                : ReorderableListView.builder(
                    itemCount: ordered.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < 0 || oldIndex >= ordered.length || newIndex < 0 || newIndex > ordered.length) return;
                      if (newIndex > oldIndex) newIndex--;
                      if (newIndex < 0 || newIndex >= ordered.length) return;
                      setDialogState(() {
                        final item = ordered.removeAt(oldIndex);
                        ordered.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final file = ordered[index];
                      return Card(
                        key: ValueKey('${identityHashCode(file)}-${file.bytes.length}'),
                        child: ListTile(
                          leading: SizedBox(
                            width: 52,
                            height: 58,
                            child: Image.memory(file.bytes, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
                          ),
                          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                          subtitle: Text('PDF page ${index + 1}'),
                          trailing: Wrap(spacing: 0, children: [
                            IconButton(
                              tooltip: 'Preview image',
                              onPressed: () => showDialog<void>(context: context, builder: (previewContext) => Dialog(child: InteractiveViewer(child: Image.memory(file.bytes, fit: BoxFit.contain)))),
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                            ),
                            ReorderableDragStartListener(index: index, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle))),
                            IconButton(tooltip: 'Remove image', onPressed: () => setDialogState(() => ordered.removeAt(index)), icon: const Icon(Icons.close, size: 18)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: ordered.isEmpty ? null : () => Navigator.pop(
                dialogContext,
                List<PickedFile>.of(ordered),
              ),
              child: const Text('Create PDF'),
            ),
          ],
        ),
      ),
    );
  }

