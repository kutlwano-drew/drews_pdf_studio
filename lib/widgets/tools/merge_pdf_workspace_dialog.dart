import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/models/pdf_document_asset.dart';
import '../../core/state/studio_controller.dart';
import '../../services/files/picked_file.dart';
import '../../services/pdf/organization/pdf_merge_service.dart';
import '../../services/pdf/reading/pdf_text_service.dart';
import '../workspace/pdf_preview.dart';
import 'pdf_changes_preview_dialog.dart';

class MergePdfWorkspaceDialog extends StatefulWidget {
  const MergePdfWorkspaceDialog({
    super.key,
    required this.files,
    required this.controller,
  });

  final List<PickedFile> files;
  final StudioController controller;

  static Future<Uint8List?> show(
    BuildContext context, {
    required List<PickedFile> files,
    required StudioController controller,
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MergePdfWorkspaceDialog(
        files: files,
        controller: controller,
      ),
    );
  }

  @override
  State<MergePdfWorkspaceDialog> createState() =>
      _MergePdfWorkspaceDialogState();
}

class _MergePdfWorkspaceDialogState extends State<MergePdfWorkspaceDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _merge = PdfMergeService();
  late List<PickedFile> _files;
  final Map<PickedFile, int> _pageCounts = {};
  Uint8List? _mergedBytes;
  int? _mergedPageCount;
  bool _busy = false;
  String? _error;
  int _refreshGeneration = 0;
  int _selectedFileIndex = 0;

  int get _totalPages =>
      _pageCounts.values.fold<int>(0, (total, count) => total + count);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _files = List<PickedFile>.of(widget.files);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshPreview() async {
    final generation = ++_refreshGeneration;
    if (_files.length < 2) {
      setState(() {
        _mergedBytes = null;
        _mergedPageCount = null;
        _error = 'Add at least one more PDF to create a merge.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final counts = <PickedFile, int>{};
      for (final file in _files) {
        counts[file] = await widget.controller.documents.pageCount(file.bytes);
      }
      final merged = await _merge.merge(
        _files.map((file) => file.bytes).toList(),
      );

      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _pageCounts
          ..clear()
          ..addAll(counts);
        _mergedBytes = merged;
        _mergedPageCount = counts.values.fold<int>(
          0,
          (total, count) => total + count,
        );
        _busy = false;
      });
    } catch (error) {
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _busy = false;
        _mergedBytes = null;
        _mergedPageCount = null;
        _error = widget.controller.friendlyError(
          error,
          action: 'build the merged PDF preview',
        );
      });
    }
  }

  Future<void> _addFiles() async {
    final added = await widget.controller.files.pickPdfs();
    if (added.isEmpty || !mounted) return;

    setState(() {
      _files.addAll(added);
      if (_files.length > added.length) {
        _selectedFileIndex = _files.length - added.length;
      } else {
        _selectedFileIndex = 0;
      }
    });
    await _refreshPreview();
  }

  Future<void> _previewFile(PickedFile file) async {
    final count = _pageCounts[file] ??
        await widget.controller.documents.pageCount(file.bytes);
    if (!mounted) return;

    await PdfChangesPreviewDialog.show(
      context,
      title: file.name,
      document: PdfDocumentAsset(
        name: file.name,
        bytes: file.bytes,
        pageCount: count,
      ),
    );
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex < 0 ||
        oldIndex >= _files.length ||
        newIndex < 0 ||
        newIndex >= _files.length) {
      return;
    }

    setState(() {
      final selectedFile = _files.isEmpty ? null : _files[_selectedFileIndex.clamp(0, _files.length - 1).toInt()];
      final file = _files.removeAt(oldIndex);
      _files.insert(newIndex, file);
      if (selectedFile != null) _selectedFileIndex = _files.indexOf(selectedFile);
    });
    await _refreshPreview();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: size.width * .94,
        height: size.height * .92,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE53935),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Merge PDF documents',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
            ),
            Center(
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                indicatorColor: const Color(0xFFE53935),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Merge PDF documents'),
                  Tab(text: 'Preview merge'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildFilesTab(),
                  _buildPreviewTab(),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_files.length} documents · $_totalPages total pages',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy || _mergedBytes == null
                        ? null
                        : _exportMarkdown,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Export MD'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy || _mergedBytes == null
                        ? null
                        : () => Navigator.pop(
                              context,
                              Uint8List.fromList(_mergedBytes!),
                            ),
                    icon: const Icon(Icons.merge_type),
                    label: const Text('Use merged PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportMarkdown() async {
    final bytes = _mergedBytes;
    if (bytes == null) return;

    setState(() => _busy = true);
    try {
      final text = await PdfTextService().extract(bytes);
      await widget.controller.files.saveBytes(
        'merged_document.md',
        Uint8List.fromList(utf8.encode('# Merged PDF document\n\n$text')),
        mimeType: 'text/markdown',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = widget.controller.friendlyError(
          error,
          action: 'export the merged document as Markdown',
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildFilesTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selected = _files.isEmpty
            ? null
            : _files[_selectedFileIndex.clamp(0, _files.length - 1).toInt()];
        final fileList = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Drag files to set the final page order.',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _addFiles,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add PDFs'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IgnorePointer(
                ignoring: _busy,
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _files.length,
                  onReorder: _reorder,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final isSelected = index == _selectedFileIndex;
                    return Card(
                      key: ValueKey('merge-${identityHashCode(file)}-${file.bytes.length}'),
                      margin: const EdgeInsets.only(bottom: 7),
                      color: isSelected ? const Color(0xFFFFF4F2) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFE53935) : const Color(0xFFE3E6EB),
                          width: isSelected ? 1.4 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selectedFileIndex = index),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFCE9E7),
                          foregroundColor: const Color(0xFFE53935),
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('${_pageCounts[file] ?? 0} pages', style: const TextStyle(color: Colors.black87)),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Open full document preview',
                              onPressed: () => _previewFile(file),
                              icon: const Icon(Icons.open_in_full, size: 18, color: Colors.black),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(Icons.drag_handle, color: Colors.black),
                                ),
                            ),
                            IconButton(
                              tooltip: 'Remove from merge',
                              onPressed: _files.length <= 2 ? null : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Remove PDF?'),
                                    content: Text('Remove "${file.name}" from this merge?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep')),
                                      FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
                                    ],
                                  ),
                                );
                                if (confirmed != true || !mounted) return;
                                setState(() {
                                  final selectedFile = _files.isEmpty ? null : _files[_selectedFileIndex.clamp(0, _files.length - 1).toInt()];
                                  final removedIndex = _files.indexOf(file);
                                  _files.remove(file);
                                  if (identical(selectedFile, file)) {
                                    _selectedFileIndex = removedIndex.clamp(0, _files.length - 1).toInt();
                                  } else if (selectedFile != null) {
                                    _selectedFileIndex = _files.indexOf(selectedFile).clamp(0, _files.length - 1).toInt();
                                  }
                                });
                                await _refreshPreview();
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );

        final preview = selected == null
            ? const Center(child: Text('Add a PDF to preview it.'))
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(children: [
                      const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFE53935), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${_pageCounts[selected] ?? 0} pages', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                    ]),
                  ),
                  Expanded(
                    child: _busy
                        ? const Center(child: CircularProgressIndicator())
                        : PdfPreview(
                            document: PdfDocumentAsset(
                              name: selected.name,
                              bytes: selected.bytes,
                              pageCount: _pageCounts[selected],
                            ),
                          ),
                  ),
                ],
              );

        if (constraints.maxWidth >= 760) {
          return Row(children: [
            Expanded(flex: 5, child: fileList),
            const VerticalDivider(width: 1),
            Expanded(flex: 6, child: preview),
          ]);
        }
        return Column(children: [
          Expanded(flex: 5, child: fileList),
          const Divider(height: 1),
          Expanded(flex: 6, child: preview),
        ]);
      },
    );
  }

  Widget _buildPreviewTab() {
    final bytes = _mergedBytes;
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bytes == null) {
      return Center(
        child: Text(
          _error ?? 'Add PDFs to preview the merged document.',
          style: const TextStyle(color: Colors.black87),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: PdfPreview(
        document: PdfDocumentAsset(
          name: 'merged_preview.pdf',
          bytes: bytes,
          pageCount: _mergedPageCount,
          isModified: true,
        ),
      ),
    );
  }

}
