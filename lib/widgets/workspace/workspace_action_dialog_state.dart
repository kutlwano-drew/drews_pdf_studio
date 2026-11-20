import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/catalog/tool_catalog.dart';
import '../../core/models/pdf_document_asset.dart';
import '../../core/models/tool_definition.dart';
import '../../core/state/studio_controller.dart';
import '../tools/tool_workflow_dialog.dart';
import 'annotation_drawing_dialog.dart';
import 'image_tools_dialog.dart';
import 'pdf_preview.dart';
import 'visual_crop_dialog.dart';
import 'workspace_action_dialog.dart';

class WorkspaceActionDialogState extends State<WorkspaceActionDialog> {
  final _search = TextEditingController();
  bool _compare = false;
  final Set<String> _favourites = {};
  List<String> _recent = [];
  bool _showFavourites = false;
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _loadToolPreferences();
  }

  Future<void> _loadToolPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favourites.addAll(prefs.getStringList('pdf_studio.favorite_tools') ?? const []);
      _recent = prefs.getStringList('pdf_studio.recent_tools') ?? const [];
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final query = _search.text.trim().toLowerCase();
    final tools = ToolCatalog.all
        .where((tool) => tool.title.toLowerCase().contains(query) || tool.description.toLowerCase().contains(query))
        .where((tool) => !_showFavourites || _favourites.contains(tool.id))
        .where((tool) => !_showRecent || _recent.contains(tool.id));
    final original = controller.currentDocument;
    final editedBytes = controller.activeDocumentBytes;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1050,
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 10, 12),
            child: Row(children: [
              if (_compare)
                IconButton(onPressed: () => setState(() => _compare = false), icon: const Icon(Icons.arrow_back))
              else
                const Icon(Icons.bolt_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text(_compare ? 'workspace.compare'.tr() : 'workspace.quick_actions'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              if (!_compare) ...[
                IconButton(tooltip: 'quick.favourites'.tr(), onPressed: () => setState(() { _showFavourites = !_showFavourites; _showRecent = false; }), icon: Icon(Icons.star_rounded, color: _showFavourites ? Colors.amber : null)),
                IconButton(tooltip: 'quick.recent'.tr(), onPressed: () => setState(() { _showRecent = !_showRecent; _showFavourites = false; }), icon: Icon(Icons.history_rounded, color: _showRecent ? Theme.of(context).colorScheme.primary : null)),
                SizedBox(width: 280, child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search, size: 18), hintText: 'workspace.search'.tr()),
                )),
              ],
              const SizedBox(width: 8),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _compare
                ? _compareView(original, editedBytes)
                : Row(children: [
                    SizedBox(
                      width: 245,
                      child: ListView(padding: const EdgeInsets.all(14), children: [
                        _actionTile(Icons.compare_arrows_rounded, 'workspace.compare'.tr(), () {
                          if (!controller.hasWorkingCopy) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('workspace.no_changes'.tr())));
                            return;
                          }
                          setState(() => _compare = true);
                        }),
                        _actionTile(Icons.undo_rounded, 'workspace.undo'.tr(), controller.canUndo ? () async { await controller.undo(); setState(() {}); } : null),
                        _actionTile(Icons.redo_rounded, 'workspace.redo'.tr(), controller.canRedo ? () async { await controller.redo(); setState(() {}); } : null),
                        _actionTile(Icons.save_alt_rounded, 'workspace.save'.tr(), controller.hasWorkingCopy ? () async { await controller.exportWorkingCopy(); if (mounted) Navigator.pop(context); } : null),
                        const Divider(),
                        Text('quick.document'.tr(), style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.black54)),
                        _actionTile(Icons.image_outlined, 'quick.image_tools'.tr(), () => ImageToolsDialog.show(widget.hostContext)),
                        _actionTile(Icons.crop, 'quick.visual_crop'.tr(), controller.currentDocument == null ? null : () => VisualCropDialog.show(widget.hostContext)),
                        _actionTile(Icons.draw_outlined, 'quick.draw_annotation'.tr(), controller.currentDocument == null ? null : () => AnnotationDrawingDialog.show(widget.hostContext)),
                        _actionTile(Icons.search_rounded, 'quick.search_pdf'.tr(), controller.currentDocument == null ? null : () => _openTool(context, 'search')),
                        _actionTile(Icons.text_snippet_outlined, 'quick.extract_text'.tr(), controller.currentDocument == null ? null : () => _openTool(context, 'text')),
                        _actionTile(Icons.info_outline_rounded, 'quick.document_info'.tr(), controller.currentDocument == null ? null : () => _openTool(context, 'info')),
                      ]),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(18),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 170,
                          mainAxisExtent: 92,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: tools.length,
                        itemBuilder: (context, index) => _toolCard(tools.elementAt(index)),
                      ),
                    ),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _compareView(PdfDocumentAsset? original, Uint8List? editedBytes) {
    if (original == null || editedBytes == null) return Center(child: Text('workspace.no_changes'.tr()));
    final edited = PdfDocumentAsset(
      name: widget.controller.workingName ?? original.name,
      bytes: editedBytes,
      pageCount: widget.controller.workingPageCount,
      isModified: true,
    );
    return Row(children: [
      Expanded(child: _comparePane('workspace.original'.tr(), original)),
      const VerticalDivider(width: 1),
      Expanded(child: _comparePane('workspace.edited'.tr(), edited)),
    ]);
  }

  Widget _comparePane(String title, PdfDocumentAsset document) => Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
        const Divider(height: 1),
        Expanded(child: Padding(padding: const EdgeInsets.all(10), child: PdfPreview(document: document))),
      ]);

  Widget _actionTile(IconData icon, String label, VoidCallback? onTap) => ListTile(
        dense: true,
        leading: Icon(icon, size: 19),
        title: Text(label, style: const TextStyle(fontSize: 12)),
        enabled: onTap != null,
        onTap: onTap,
      );

  Widget _toolCard(ToolDefinition tool) => InkWell(
        onTap: () => _openTool(context, tool.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E8ED))),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(IconData(tool.iconCode, fontFamily: 'MaterialIcons'), size: 21, color: const Color(0xFFE84B3C)),
              const Spacer(),
              Text(tool.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              Text(tool.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ]),
            Positioned(right: -8, top: -9, child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _favourites.contains(tool.id) ? 'quick.remove_favourite'.tr() : 'quick.add_favourite'.tr(),
              onPressed: () => _toggleFavourite(tool.id),
              icon: Icon(_favourites.contains(tool.id) ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: _favourites.contains(tool.id) ? Colors.amber : Colors.black38),
            )),
          ]),
        ),
      );

  Future<void> _toggleFavourite(String id) async {
    setState(() { if (!_favourites.add(id)) _favourites.remove(id); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pdf_studio.favorite_tools', _favourites.toList());
  }

  Future<void> _openTool(BuildContext context, String id) async {
    final matches = ToolCatalog.all.where((tool) => tool.id == id);
    if (matches.isEmpty) return;
    final tool = matches.first;
    _recent.remove(id);
    _recent.insert(0, id);
    if (_recent.length > 12) _recent = _recent.take(12).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pdf_studio.recent_tools', _recent);
    if (!mounted) return;
    Navigator.pop(context);
    await ToolWorkflowDialog.open(widget.hostContext, tool);
  }
}
