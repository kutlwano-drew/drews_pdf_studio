import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

import '../../core/models/pdf_document_asset.dart';
import '../../core/state/studio_controller.dart';
import '../../core/state/studio_scope.dart';
import '../../services/pdf/pdf_engine.dart';
import '../../services/pdf/reading/pdf_render_service.dart';
import '../../services/pdf/reading/pdf_text_service.dart';
import '../../services/pdf/organization/pdf_page_service.dart';
import '../common/app_error_dialog.dart';
import 'page_preview_dialog.dart';
import 'page_thumbnail_grid.dart';
import 'pdf_changes_preview_dialog.dart';
import 'tool_workflow_executor.dart';
import 'tool_dialogs.dart';
import 'workflows/workflow_output.dart';
import '../../services/pdf/organization/page_selection_parser.dart';
import '../workspace/visual_crop_dialog.dart';
import 'tool_workflow_form.dart';

class ToolWorkflowFormState extends State<ToolWorkflowForm> {
  final _value = TextEditingController();
  final _createTitle = TextEditingController(text: 'Untitled document');
  final _createBody = TextEditingController();
  final _cropTop = TextEditingController(text: '0');
  final _cropRight = TextEditingController(text: '0');
  final _cropBottom = TextEditingController(text: '0');
  final _cropLeft = TextEditingController(text: '0');
  final _render = PdfRenderService();
  final Map<String, Future<Uint8List>> _thumbnailCache = {};
  final Set<int> _selectedPages = {};
  List<PdfSearchHit> _redactHits = <PdfSearchHit>[];
  bool _redactHighlightMode = false;
  final List<int> _selectionOrder = [];
  List<int> _pageOrder = [];
  int? _pageCount;
  Uint8List? _sourceBytes;
  Uint8List? _selectionOutputBytes;
  int? _sourcePageCount;
  int? _lastBytesHash;
  double _thumbnailWidth = 176;
  String? _startingMessage;
  String? _lastExtractedText;
  bool _lastExtractedTextCopied = false;
  String _compressionPolicy = 'ebook';
  String _stampType = 'draft';
  Color _watermarkColor = const Color(0xFF808080);
  double _watermarkSize = 48;
  double _watermarkOpacity = 0.3;
  String _renderFormat = 'png';

  final List<List<String>> _tableRows = <List<String>>[
    <String>['Item', 'Quantity', 'Notes'],
    <String>['Paper', '3', 'A4'],
    <String>['Ink', '2', 'Black'],
  ];
  String _formTemplate = 'Contact';
  final List<Map<String, String>> _formFields = <Map<String, String>>[
    <String, String>{'label': 'Full name', 'type': 'text'},
    <String, String>{'label': 'Email address', 'type': 'email'},
    <String, String>{'label': 'Message', 'type': 'multiline'},
  ];

  bool get _isPageSelectionTool => const {
    'remove',
    'extract',
    'split',
    'duplicate',
    'rotate',
  }.contains(widget.tool.id);

  bool get _isReorderTool => widget.tool.id == 'reorder';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPages());
  }

  @override
  void dispose() {
    _value.dispose();
    _createTitle.dispose();
    _createBody.dispose();
    _cropTop.dispose();
    _cropRight.dispose();
    _cropBottom.dispose();
    _cropLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = StudioScope.watch(context);
    final bytes = controller.activeDocumentBytes;
    final isExtractOrSplit =
        widget.tool.id == 'extract' || widget.tool.id == 'split';
    final count = isExtractOrSplit
        ? (_sourcePageCount ??
              _pageCount ??
              controller.currentDocument?.pageCount ??
              0)
        : (controller.workingPageCount ??
              controller.currentDocument?.pageCount ??
              _pageCount ??
              0);

    if (bytes != null && _lastBytesHash != bytes.hashCode) {
      _lastBytesHash = bytes.hashCode;
      _thumbnailCache.clear();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to tools',
          onPressed: controller.isBusy || _startingMessage != null
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tool.title),
            Text(
              widget.tool.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (controller.hasWorkingCopy)
            if (MediaQuery.of(context).size.width < 560)
              IconButton(
                tooltip: 'Discard changes',
                onPressed: controller.isBusy || _startingMessage != null
                    ? null
                    : _discardChanges,
                icon: const Icon(Icons.undo),
              )
            else
              TextButton.icon(
                onPressed: controller.isBusy || _startingMessage != null
                    ? null
                    : _discardChanges,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Discard changes'),
              ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          if (controller.isBusy || _startingMessage != null) ...[
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Color(0xFFF7D9D6),
              color: Color(0xFFE53935),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _startingMessage ??
                          controller.statusMessage ??
                          'Working…',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555D69),
                      ),
                    ),
                  ),
                  if (controller.isBusy)
                    TextButton.icon(
                      onPressed: controller.cancelCurrentTask,
                      icon: const Icon(Icons.stop_circle_outlined, size: 16),
                      label: Text('workflow.cancel_operation'.tr()),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final options = _optionsPanel(controller, count);
                final previewBytes = isExtractOrSplit
                    ? (_sourceBytes ?? bytes)
                    : bytes;
                final pages = _pagesPanel(previewBytes, count);

                if (constraints.maxWidth >= 920) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 330, child: options),
                      Expanded(child: pages),
                    ],
                  );
                }

                return Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight < 650 ? 230 : 270,
                      ),
                      child: options,
                    ),
                    Expanded(child: pages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsPanel(StudioController controller, int pageCount) {
    final pageTool = _isPageSelectionTool || _isReorderTool;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Operation settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF202938),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pageTool
                  ? _pageInstruction(pageCount)
                  : 'Set the options for this operation, then apply them to the document preview.',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if (widget.tool.id == 'split') ...[
              const SizedBox(height: 14),
              _splitInfoPanel(controller, pageCount),
            ],
            if (!pageTool) ...[
              const SizedBox(height: 16),
              if (widget.tool.id == 'crop')
                _cropMarginFields()
              else if (widget.tool.id == 'watermark')
                _watermarkOptions()
              else if (widget.tool.id == 'compress')
                _compressionOptions()
              else if (widget.tool.id == 'stamp')
                _stampOptions()
              else if (widget.tool.id == 'create')
                _createDocumentEditor()
              else if (widget.tool.id == 'createtable')
                _createTableEditor()
              else if (widget.tool.id == 'createform')
                _createFormEditor()
              else if (widget.tool.id == 'redact')
                _redactOptions()
              else if (widget.tool.id == 'renderpage' ||
                  widget.tool.id == 'renderall')
                _renderOptions()
              else if (_hasNoTextInput)
                _actionInfoPanel()
              else
                TextField(
                  controller: _value,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: _label,
                    hintText: _hint,
                    alignLabelWithHint: true,
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E8ED)),
                ),
                child: Text(
                  _isReorderTool
                      ? 'Press and hold a page, then drag it to its new position.'
                      : 'Selected pages: ${_selectionOrder.map((page) => page + 1).join(', ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF48515E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.isBusy || _startingMessage != null
                  ? null
                  : _run,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_applyLabel),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed:
                  controller.isBusy ||
                      _startingMessage != null ||
                      !controller.hasWorkingCopy
                  ? null
                  : _previewChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.black,
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.visibility_outlined, color: Colors.black),
              label: const Text('Preview changes'),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed:
                  controller.isBusy ||
                      _startingMessage != null ||
                      !controller.hasWorkingCopy
                  ? null
                  : _exportCopy,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.black,
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFFE53935),
              ),
              label: const Text('Export PDF copy'),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed:
                  controller.isBusy ||
                      _startingMessage != null ||
                      !controller.hasWorkingCopy
                  ? null
                  : _exportTextCopy,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.black,
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(
                Icons.text_snippet_outlined,
                color: Color(0xFF1565C0),
              ),
              label: const Text('Export TXT copy'),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed:
                  controller.isBusy ||
                      _startingMessage != null ||
                      !controller.hasWorkingCopy
                  ? null
                  : _exportMarkdownCopy,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.black,
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black),
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(
                Icons.description_outlined,
                color: Color(0xFF6A1B9A),
              ),
              label: const Text('Export MD copy'),
            ),
            if (widget.tool.id == 'extract' && _lastExtractedText != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showExtractedPagesText,
                icon: const Icon(Icons.article_outlined),
                label: const Text('View extracted text'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
              ),
              if (_lastExtractedTextCopied)
                OutlinedButton.icon(
                  onPressed: _showCopiedExtractedText,
                  icon: const Icon(Icons.content_paste_search_outlined),
                  label: const Text('View copied text'),
                ),
              OutlinedButton.icon(
                onPressed: () => WorkflowOutput.save(
                  context,
                  'extracted_pages.txt',
                  Uint8List.fromList(utf8.encode(_lastExtractedText!)),
                  mimeType: 'text/plain',
                ),
                icon: const Icon(
                  Icons.text_snippet_outlined,
                  color: Color(0xFF1565C0),
                ),
                label: const Text('Export text as TXT'),
              ),
              OutlinedButton.icon(
                onPressed: () => WorkflowOutput.save(
                  context,
                  'extracted_pages.md',
                  Uint8List.fromList(
                    utf8.encode('# Extracted pages\n\n${_lastExtractedText!}'),
                  ),
                  mimeType: 'text/markdown',
                ),
                icon: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF6A1B9A),
                ),
                label: const Text('Export text as MD'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pagesPanel(Uint8List? bytes, int pageCount) {
    if (widget.tool.id == 'create') {
      return _createCanvasPreview();
    }

    if (bytes == null || pageCount == 0) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(28),
        child: const Text(
          'Open a PDF to see its pages here.',
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    final order = _pageOrder.length == pageCount
        ? _pageOrder
        : List<int>.generate(pageCount, (index) => index);

    return Container(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 7,
              runSpacing: 4,
              children: [
                Text(
                  'workspace.pages'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'workflow.total'.tr(namedArgs: {'count': '$pageCount'}),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                PopupMenuButton<double>(
                  tooltip: 'workflow.grid_density'.tr(),
                  icon: const Icon(Icons.grid_view_rounded, size: 17),
                  onSelected: (value) =>
                      setState(() => _thumbnailWidth = value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 140,
                      child: Text('workflow.compact'.tr()),
                    ),
                    PopupMenuItem(
                      value: 176,
                      child: Text('workflow.comfortable'.tr()),
                    ),
                    PopupMenuItem(
                      value: 220,
                      child: Text('workflow.large'.tr()),
                    ),
                  ],
                ),
                if (_isPageSelectionTool) ...[
                  _pageAction('workflow.all'.tr(), _selectAll),
                  _pageAction('workflow.none'.tr(), _selectNone),
                  _pageAction('workflow.invert'.tr(), _invertSelection),
                  _pageAction(
                    'workflow.range'.tr(),
                    () => _selectRange(pageCount),
                  ),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'workflow.eye_hint'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child:
                (_isPageSelectionTool &&
                    (widget.tool.id == 'extract' || widget.tool.id == 'split'))
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Original document · Select pages',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Expanded(
                              child: PageThumbnailGrid(
                                pageOrder: order,
                                selectedPages: _selectedPages,
                                selectionEnabled: true,
                                reorderEnabled: true,
                                loadThumbnail: (page) =>
                                    _loadThumbnail(bytes, page),
                                onPageTap: _togglePage,
                                onReorder: _setPageOrder,
                                tileWidth: _thumbnailWidth,
                                onPreview: (page) {
                                  final position = order.indexOf(page) + 1;
                                  PagePreviewDialog.show(
                                    context,
                                    pageNumber: position,
                                    pageCount: pageCount,
                                    image: _loadThumbnail(bytes, page),
                                    loadPage: (number) => _loadThumbnail(
                                      bytes,
                                      order[number - 1],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 320,
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.tool.id == 'split'
                                            ? 'Split PDF preview'
                                            : 'Extracted pages',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_selectionOrder.length} pages',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Preview selected PDF',
                                      onPressed: _selectionOrder.isEmpty
                                          ? null
                                          : _previewSelectedPages,
                                      icon: const Icon(
                                        Icons.open_in_full,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: _selectionOrder.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Select pages on the left.',
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      )
                                    : ReorderableListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: _selectionOrder.length,
                                        onReorder: (oldIndex, newIndex) {
                                          final length = _selectionOrder.length;
                                          if (oldIndex < 0 ||
                                              oldIndex >= length ||
                                              newIndex < 0 ||
                                              newIndex > length)
                                            return;
                                          if (newIndex > oldIndex) newIndex--;
                                          if (newIndex < 0 ||
                                              newIndex >= length)
                                            return;
                                          setState(() {
                                            final next = List<int>.of(
                                              _selectionOrder,
                                            );
                                            final page = next.removeAt(
                                              oldIndex,
                                            );
                                            next.insert(newIndex, page);
                                            if (next.length !=
                                                    _selectedPages.length ||
                                                next.toSet().length !=
                                                    next.length ||
                                                !next.toSet().containsAll(
                                                  _selectedPages,
                                                ))
                                              return;
                                            _selectionOrder
                                              ..clear()
                                              ..addAll(next);
                                            _selectionOutputBytes = null;
                                            _value.text = _selectionOrder
                                                .map((item) => item + 1)
                                                .join(',');
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          final page = _selectionOrder[index];
                                          return Container(
                                            key: ValueKey('selected-$page'),
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.picture_as_pdf_rounded,
                                                  color: Color(0xFFE53935),
                                                  size: 26,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Page ${page + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Preview page',
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                    color: Colors.black,
                                                    size: 18,
                                                  ),
                                                  onPressed: () =>
                                                      PagePreviewDialog.show(
                                                        context,
                                                        pageNumber: page + 1,
                                                        pageCount: pageCount,
                                                        image: _loadThumbnail(
                                                          bytes,
                                                          page,
                                                        ),
                                                        loadPage: (number) =>
                                                            _loadThumbnail(
                                                              bytes,
                                                              number - 1,
                                                            ),
                                                      ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Remove page',
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Color(0xFFE53935),
                                                    size: 19,
                                                  ),
                                                  onPressed: () async {
                                                    final confirmed = await showDialog<bool>(
                                                      context: context,
                                                      builder: (dialogContext) => AlertDialog(
                                                        title: const Text(
                                                          'Remove selected page?',
                                                        ),
                                                        content: Text(
                                                          'Remove page ${page + 1} from the output? It will also be unchecked in the original document.',
                                                        ),
                                                        actions: [
                                                          FilledButton(
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFFE53935,
                                                                  ),
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Keep page',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFF2E7D32,
                                                                  ),
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Remove page',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirmed != true ||
                                                        !mounted)
                                                      return;
                                                    setState(() {
                                                      _selectionOrder.remove(
                                                        page,
                                                      );
                                                      _selectedPages.remove(
                                                        page,
                                                      );
                                                      _selectionOutputBytes =
                                                          null;
                                                      _value.text =
                                                          _selectionOrder
                                                              .map(
                                                                (item) =>
                                                                    item + 1,
                                                              )
                                                              .join(',');
                                                    });
                                                  },
                                                ),
                                                const Icon(
                                                  Icons.drag_handle,
                                                  color: Colors.black,
                                                  size: 19,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : PageThumbnailGrid(
                    pageOrder: order,
                    selectedPages: _selectedPages,
                    selectionEnabled: _isPageSelectionTool,
                    reorderEnabled: true,
                    loadThumbnail: (page) => _loadThumbnail(bytes, page),
                    onPageTap: _togglePage,
                    onReorder: _setPageOrder,
                    tileWidth: _thumbnailWidth,
                    onPreview: (page) {
                      final position = order.indexOf(page) + 1;
                      PagePreviewDialog.show(
                        context,
                        pageNumber: position,
                        pageCount: pageCount,
                        image: _loadThumbnail(bytes, page),
                        loadPage: (number) =>
                            _loadThumbnail(bytes, order[number - 1]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isIdentityPageOrder(List<int> order) {
    for (var index = 0; index < order.length; index++) {
      if (order[index] != index) return false;
    }
    return true;
  }

  Future<Uint8List> _loadThumbnail(Uint8List bytes, int page) {
    final key = '${bytes.hashCode}:$page';
    return _thumbnailCache.putIfAbsent(
      key,
      () => _render.renderPage(bytes, page),
    );
  }

  Widget _createCanvasPreview() {
    final title = _createTitle.text.trim().isEmpty
        ? 'Untitled document'
        : _createTitle.text.trim();

    return Container(
      color: const Color(0xFFF0F2F5),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(56, 58, 56, 58),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 18,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                if (_createBody.text.trim().isEmpty)
                  const Text(
                    'Your document starts here…',
                    style: TextStyle(color: Colors.black38, fontSize: 15),
                  )
                else
                  MarkdownBody(
                    data: _createBody.text,
                    styleSheet: MarkdownStyleSheet(
                      a: const TextStyle(
                        color: Color(0xFF1565C0),
                        decoration: TextDecoration.underline,
                      ),
                      p: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        height: 1.65,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createDocumentEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _createTitle,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Document title',
            hintText: 'Untitled document',
          ),
        ),
        const SizedBox(height: 10),
        _markdownToolbar(),
        TextField(
          controller: _createBody,
          minLines: 7,
          maxLines: 14,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Document content',
            hintText:
                'Start writing here. Use the toolbar to format your content.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Live document preview',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            border: Border.all(color: const Color(0xFFE1E4EA)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: _createBody.text.isEmpty
                  ? '_Your document preview will appear here._'
                  : _createBody.text,
              styleSheet: MarkdownStyleSheet(
                a: const TextStyle(
                  color: Color(0xFF1565C0),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _renderOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tool.id == 'renderpage')
          TextField(
            controller: _value,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'Page number',
              hintText: '1',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        if (widget.tool.id == 'renderpage') const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _renderFormat,
          decoration: const InputDecoration(
            labelText: 'Image format',
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'png', child: Text('PNG · lossless')),
            DropdownMenuItem(value: 'jpg', child: Text('JPG · smaller files')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _renderFormat = value);
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Rendered pages are converted with the image package before export.',
          style: TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _redactOptions() {
    final controller = StudioScope.read(context);
    final query = _value.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Search and redact',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Search the PDF for sensitive text. Search hits are shown as black redaction bars; choosing the redaction action permanently removes the matched content.',
          style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _value,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: 'Text to find',
            hintText: 'e.g. passport number, email, account number',
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () => _searchRedactionHits(),
            ),
          ),
          onSubmitted: (_) => _searchRedactionHits(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: query.isEmpty ? null : _searchRedactionHits,
                icon: const Icon(Icons.search),
                label: const Text('Find text'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Highlight and permanently redact matches',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: _redactHits.isEmpty
                  ? null
                  : () => _redactFoundText(controller),
              icon: const Icon(Icons.highlight_alt_outlined),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Redact all found text',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _redactHits.isEmpty
                  ? null
                  : () => _redactFoundText(controller),
              icon: const Icon(Icons.block),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_redactHits.isEmpty)
          const Text(
            'No matches yet. Search for text above.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _redactHits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final hit = _redactHits[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.block, color: Colors.black),
                  title: Text(
                    'Page ${hit.page + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    color: Colors.black,
                    child: Text(
                      hit.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'View highlighted page',
                    icon: const Icon(
                      Icons.visibility_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () => _showRedactionPagePreview(hit.page),
                  ),
                );
              },
            ),
          ),
        if (_redactHits.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_redactHits.length} match${_redactHits.length == 1 ? '' : 'es'} found',
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Future<void> _searchRedactionHits() async {
    final bytes = StudioScope.read(context).activeDocumentBytes;
    final query = _value.text.trim();
    if (bytes == null || query.isEmpty) return;

    try {
      final hits = await PdfEngine.instance.pdf
          .readOnce(PdfEngine.instance.input(bytes))
          .search(query);
      if (!mounted) return;
      setState(() {
        _redactHits = hits;
        _redactHighlightMode = true;
      });
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'Redaction search failed',
        message: error.toString(),
      );
    }
  }

  Future<void> _redactFoundText(StudioController controller) async {
    final bytes = controller.activeDocumentBytes;
    if (bytes == null || _redactHits.isEmpty) return;

    final grouped = <int, List<PdfRect>>{};
    for (final hit in _redactHits) {
      grouped.putIfAbsent(hit.page, () => <PdfRect>[]).add(hit.bounds);
    }

    setState(() => _startingMessage = 'Applying permanent redactions…');
    try {
      final sink = MemorySink();
      await PdfEngine.instance.rewrite(PdfEngine.instance.input(bytes), sink, (
        editor,
      ) async {
        for (final entry in grouped.entries) {
          await editor.redact(entry.key, entry.value);
        }
      });
      await controller.setWorkingCopy(
        sink.takeBytes(),
        name: controller.currentDocument?.name ?? 'redacted.pdf',
      );
      if (!mounted) return;
      setState(() {
        _redactHits = <PdfSearchHit>[];
        _redactHighlightMode = false;
      });
      await _refreshPages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Found text was permanently redacted.')),
      );
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'Redaction failed',
        message: controller.friendlyError(
          error,
          action: 'redact the found text',
        ),
      );
    } finally {
      if (mounted) setState(() => _startingMessage = null);
    }
  }

  Future<void> _showRedactionPagePreview(int page) async {
    final bytes = StudioScope.read(context).activeDocumentBytes;
    if (bytes == null) return;
    final hits = _redactHits.where((hit) => hit.page == page).toList();
    final image = await _render.renderPage(bytes, page);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        child: SizedBox(
          width: 900,
          height: MediaQuery.sizeOf(context).height * .84,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Page ${page + 1} · Redaction preview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: .5,
                    maxScale: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final pageWidth = 595.0;
                        final pageHeight = 842.0;
                        final scale = (constraints.maxWidth / pageWidth).clamp(
                          0.1,
                          constraints.maxHeight / pageHeight,
                        );
                        return SizedBox(
                          width: pageWidth * scale,
                          height: pageHeight * scale,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(image, fit: BoxFit.fill),
                              CustomPaint(
                                painter: _RedactionPreviewPainter(
                                  hits: hits,
                                  pageWidth: pageWidth,
                                  pageHeight: pageHeight,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Black bars show the text that will be permanently removed.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createTableEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Table editor',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Build the table visually. The PDF uses a real rendered table layout, not drawing lines by hand.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  final columns = _tableRows.isEmpty
                      ? 3
                      : _tableRows.first.length;
                  _tableRows.add(List<String>.filled(columns, ''));
                }),
                icon: const Icon(Icons.add),
                label: const Text('Add row'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  for (final row in _tableRows) {
                    row.add('');
                  }
                }),
                icon: const Icon(Icons.view_column_outlined),
                label: const Text('Add column'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFEDEDED)),
              columns: [
                for (
                  var column = 0;
                  column < (_tableRows.isEmpty ? 0 : _tableRows.first.length);
                  column++
                )
                  DataColumn(
                    label: Text(
                      'Column ${column + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const DataColumn(label: SizedBox(width: 20)),
              ],
              rows: [
                for (var rowIndex = 0; rowIndex < _tableRows.length; rowIndex++)
                  DataRow(
                    cells: [
                      for (
                        var column = 0;
                        column < _tableRows[rowIndex].length;
                        column++
                      )
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              initialValue: _tableRows[rowIndex][column],
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                              ),
                              onChanged: (value) =>
                                  _tableRows[rowIndex][column] = value,
                            ),
                          ),
                        ),
                      DataCell(
                        IconButton(
                          tooltip: 'Remove row',
                          onPressed: _tableRows.length <= 1
                              ? null
                              : () => setState(
                                  () => _tableRows.removeAt(rowIndex),
                                ),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rendered preview',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.black26),
                children: [
                  for (final row in _tableRows)
                    TableRow(
                      children: [
                        for (final cell in row)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              cell.isEmpty ? ' ' : cell,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createFormEditor() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Form templates',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _formTemplate,
            decoration: const InputDecoration(
              labelText: 'Template',
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Contact', child: Text('Contact form')),
              DropdownMenuItem(
                value: 'Registration',
                child: Text('Registration form'),
              ),
              DropdownMenuItem(value: 'Feedback', child: Text('Feedback form')),
              DropdownMenuItem(value: 'Custom', child: Text('Custom form')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _formTemplate = value;
                if (value == 'Contact') {
                  _formFields
                    ..clear()
                    ..addAll([
                      {'label': 'Full name', 'type': 'text'},
                      {'label': 'Email address', 'type': 'email'},
                      {'label': 'Message', 'type': 'multiline'},
                    ]);
                } else if (value == 'Registration') {
                  _formFields
                    ..clear()
                    ..addAll([
                      {'label': 'Full name', 'type': 'text'},
                      {'label': 'Email address', 'type': 'email'},
                      {'label': 'Date of birth', 'type': 'date'},
                      {'label': 'I agree to the terms', 'type': 'checkbox'},
                    ]);
                } else if (value == 'Feedback') {
                  _formFields
                    ..clear()
                    ..addAll([
                      {'label': 'Name', 'type': 'text'},
                      {'label': 'Rating', 'type': 'choice'},
                      {'label': 'Comments', 'type': 'multiline'},
                    ]);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _formFields.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _formFields[index]['label'],
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Field label',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _formFields[index]['label'] = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      value: _formFields[index]['type'],
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text')),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                        DropdownMenuItem(
                          value: 'multiline',
                          child: Text('Long text'),
                        ),
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(
                          value: 'checkbox',
                          child: Text('Checkbox'),
                        ),
                        DropdownMenuItem(
                          value: 'choice',
                          child: Text('Choice'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        if (value != null) _formFields[index]['type'] = value;
                      }),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove field',
                    onPressed: _formFields.length <= 1
                        ? null
                        : () => setState(() => _formFields.removeAt(index)),
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _formTemplate = 'Custom';
              _formFields.add({'label': 'New field', 'type': 'text'});
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add field'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Live form preview',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$_formTemplate form',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final field in _formFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _formPreviewField(field),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formPreviewField(Map<String, String> field) {
    final label = field['label']?.trim().isEmpty == false
        ? field['label']!.trim()
        : 'Untitled field';
    switch (field['type']) {
      case 'checkbox':
        return CheckboxListTile(
          value: false,
          onChanged: (_) {},
          title: Text(label, style: const TextStyle(color: Colors.black)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      case 'choice':
        return DropdownButtonFormField<String>(
          value: null,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
            DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
            DropdownMenuItem(value: 'Option 3', child: Text('Option 3')),
          ],
          onChanged: (_) {},
        );
      case 'date':
        return TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black,
            ),
          ),
          onTap: () {},
        );
      case 'multiline':
        return TextFormField(
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
          ),
        );
      default:
        return TextFormField(
          keyboardType: field['type'] == 'email'
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
          ),
        );
    }
  }

  Widget _markdownToolbar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Title',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('# ', ''),
            icon: const Icon(Icons.title),
          ),
          IconButton(
            tooltip: 'Heading',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('## ', ''),
            icon: const Icon(Icons.format_size),
          ),
          IconButton(
            tooltip: 'Subheading',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('### ', ''),
            icon: const Icon(Icons.text_fields),
          ),
          IconButton(
            tooltip: 'Bold',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('**', '**'),
            icon: const Icon(Icons.format_bold),
          ),
          IconButton(
            tooltip: 'Italic',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('*', '*'),
            icon: const Icon(Icons.format_italic),
          ),
          IconButton(
            tooltip: 'Highlight',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('==', '=='),
            icon: const Icon(Icons.highlight),
          ),
          IconButton(
            tooltip: 'Bullet list',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('- ', ''),
            icon: const Icon(Icons.format_list_bulleted),
          ),
          IconButton(
            tooltip: 'Numbered list',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('1. ', ''),
            icon: const Icon(Icons.format_list_numbered),
          ),
          IconButton(
            tooltip: 'Quote',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('> ', ''),
            icon: const Icon(Icons.format_quote),
          ),
          IconButton(
            tooltip: 'Horizontal rule',
            visualDensity: VisualDensity.compact,
            onPressed: () => _insertMarkdown('\n---\n', ''),
            icon: const Icon(Icons.horizontal_rule),
          ),
          IconButton(
            tooltip: 'Link',
            visualDensity: VisualDensity.compact,
            onPressed: _insertMarkdownLink,
            icon: const Icon(Icons.link),
          ),
        ],
      ),
    );
  }

  Future<void> _insertMarkdownLink() async {
    final url = await ToolDialogs.ask(
      context,
      'Insert link',
      'URL',
      initial: 'https://',
    );
    if (url == null || url.trim().isEmpty) return;
    final label = await ToolDialogs.ask(
      context,
      'Link text',
      'Text shown to the reader',
      initial: 'Open link',
    );
    if (label == null || label.trim().isEmpty) return;
    _insertMarkdown('[$label](${url.trim()})', '');
  }

  void _insertMarkdown(String prefix, String suffix) {
    final editor = _createBody;
    final selection = editor.selection;
    final text = editor.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selected = text.substring(start, end);
    final insertion = '$prefix$selected$suffix';
    final updated = text.replaceRange(start, end, insertion);
    setState(() {
      editor.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + insertion.length),
      );
    });
  }

  Widget _watermarkOptions() {
    const palette = <Color>[
      Color(0xFF111111),
      Color(0xFFE53935),
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFFF8F00),
      Color(0xFF6A1B9A),
      Color(0xFF808080),
      Colors.white,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _value,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Watermark text',
            hintText: 'CONFIDENTIAL',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Text colour',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _watermarkColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                var selected = _watermarkColor;
                final result = await showDialog<Color>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Choose watermark colour'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _watermarkColor,
                        onColorChanged: (color) => selected = color,
                        enableAlpha: false,
                        displayThumbColor: true,
                        pickerAreaHeightPercent: .72,
                        showLabel: true,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, selected),
                        child: const Text('Use colour'),
                      ),
                    ],
                  ),
                );
                if (result != null && mounted)
                  setState(() => _watermarkColor = result);
              },
              child: const Text('Choose colour'),
            ),
          ],
        ),
        Wrap(
          spacing: 9,
          children: [
            for (final color in palette)
              InkWell(
                onTap: () => setState(() => _watermarkColor = color),
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _watermarkColor == color
                          ? const Color(0xFFE53935)
                          : Colors.black26,
                      width: _watermarkColor == color ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Text size',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('${_watermarkSize.round()} pt'),
          ],
        ),
        Slider(
          value: _watermarkSize,
          min: 8,
          max: 120,
          divisions: 28,
          onChanged: (value) => setState(() => _watermarkSize = value),
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Opacity',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('${(_watermarkOpacity * 100).round()}%'),
          ],
        ),
        Slider(
          value: _watermarkOpacity,
          min: 0.05,
          max: 1,
          divisions: 19,
          onChanged: (value) => setState(() => _watermarkOpacity = value),
        ),
        const SizedBox(height: 10),
        Container(
          height: 78,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            border: Border.all(color: const Color(0xFFE1E4EA)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Transform.rotate(
            angle: -0.55,
            child: Text(
              _value.text.trim().isEmpty ? 'CONFIDENTIAL' : _value.text.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _watermarkColor.withValues(alpha: _watermarkOpacity),
                fontSize: (_watermarkSize / 2.5).clamp(14, 34),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stampOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _stampType,
          decoration: const InputDecoration(labelText: 'Stamp type'),
          items: const [
            DropdownMenuItem(value: 'draft', child: Text('Draft')),
            DropdownMenuItem(value: 'approved', child: Text('Approved')),
            DropdownMenuItem(
              value: 'confidential',
              child: Text('Confidential'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _stampType = value);
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the label that should appear on the document.',
          style: TextStyle(color: Colors.black87, fontSize: 12),
        ),
      ],
    );
  }

  Widget _compressionOptions() {
    const descriptions = <String, String>{
      'screen':
          'Smallest files for on-screen reading. Image quality is reduced.',
      'ebook': 'Balanced size and quality for everyday sharing.',
      'print': 'Higher image quality for printing. Files are usually larger.',
      'lossless':
          'Preserves image quality where possible. Usually the largest output.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _compressionPolicy,
          decoration: const InputDecoration(labelText: 'Compression profile'),
          items: const [
            DropdownMenuItem(
              value: 'screen',
              child: Text('Small file · Screen'),
            ),
            DropdownMenuItem(
              value: 'ebook',
              child: Text('Balanced · Everyday use'),
            ),
            DropdownMenuItem(
              value: 'print',
              child: Text('High quality · Print'),
            ),
            DropdownMenuItem(
              value: 'lossless',
              child: Text('Preserve quality · Lossless'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _compressionPolicy = value);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          descriptions[_compressionPolicy]!,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  bool get _hasNoTextInput => const {
    'merge',
    'append',
    'images',
    'officetopdf',
    'imagestamp',
    'attachment',
    'text',
    'info',
    'pageinfo',
    'classify',
    'bookmarks',
    'extractimages',
    'renderall',
    'forms',
    'xfa',
    'signatures',
    'verify',
    'sanitize',
    'convertpdfa',
    'pdfa',
    'pdfua',
    'flattenforms',
    'flattenannotations',
    'formexport',
    'convertxfa',
    'unembed',
  }.contains(widget.tool.id);

  String get _applyLabel => switch (widget.tool.id) {
    'split' => 'Create split PDF',
    'extract' => 'Extract selected pages',
    'remove' => 'Remove selected pages',
    'reorder' => 'Apply page order',
    'duplicate' => 'Duplicate selected pages',
    'rotate' => 'Rotate selected pages',
    'merge' => 'Import PDFs and arrange order',
    'append' => 'Choose PDF to append',
    'images' => 'Import images',
    'officetopdf' => 'Choose Office document',
    'imagestamp' => 'Choose watermark image',
    'attachment' => 'Choose file to attach',
    'text' => 'Extract text',
    'info' => 'View document information',
    'pageinfo' => 'View page information',
    'classify' => 'Classify document',
    'bookmarks' => 'View bookmarks',
    'extractimages' => 'Extract images',
    'renderall' => 'Export all pages as images',
    'forms' => 'Inspect form fields',
    'xfa' => 'Inspect XFA data',
    'signatures' => 'Inspect signatures',
    'verify' => 'Verify signatures',
    'sanitize' => 'Sanitize document',
    'convertpdfa' => 'Convert to PDF/A',
    'pdfa' => 'Validate PDF/A',
    'pdfua' => 'Validate PDF/UA',
    'flattenforms' => 'Flatten form fields',
    'flattenannotations' => 'Flatten annotations',
    'unembed' => 'Optimize fonts',
    _ => 'Apply operation',
  };

  Widget _actionInfoPanel() {
    final message = switch (widget.tool.id) {
      'merge' =>
        'Your open PDF will be first. Add other PDFs, arrange their order, preview the merged result, then confirm.',
      'append' =>
        'Choose another PDF to add its pages to the end of your current document. You can review the change before exporting.',
      'images' =>
        'Choose multiple JPG or PNG images. Arrange their order before creating the PDF.',
      'officetopdf' =>
        'Choose a Word, PowerPoint or Excel file. The converted PDF will open in your workspace.',
      'imagestamp' => 'Choose a PNG or JPG logo to place on the PDF pages.',
      'attachment' => 'Choose a file to embed inside the PDF as an attachment.',
      'text' =>
        'Extract readable text from the document. Copy it or export it as TXT or Markdown.',
      'info' || 'pageinfo' || 'classify' || 'bookmarks' =>
        'View information from your document in a readable report.',
      'extractimages' ||
      'renderall' => 'Export the images or page previews from this document.',
      'forms' || 'xfa' => 'Inspect the form information stored in this PDF.',
      'signatures' || 'verify' =>
        'Review the digital signatures and their verification status.',
      'sanitize' =>
        'Remove document metadata and potentially unsafe embedded content.',
      'convertpdfa' || 'pdfa' || 'pdfua' =>
        'Check or convert the document using a PDF accessibility or archival standard.',
      'flattenforms' =>
        'Make form fields part of the page content so they can no longer be edited.',
      'flattenannotations' => 'Make annotations part of the page content.',
      'unembed' =>
        'Remove embedded copies of standard fonts to reduce document size.',
      _ =>
        'This action uses the current document and does not need extra text input.',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: const Color(0xFFE1E4EA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.touch_app_outlined, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitInfoPanel(StudioController controller, int pageCount) {
    final originalDocument = controller.currentDocument;
    final originalBytes = _sourceBytes ?? originalDocument?.bytes;
    final outputBytes = _selectionOutputBytes;
    final selectedCount = _selectionOrder.length;
    final splitHasBeenApplied = outputBytes != null;

    Widget infoSection(String title, List<(String, String)> values) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            for (final item in values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        item.$2,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: const Color(0xFFE1E4EA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoSection('Original document', [
            ('Name', originalDocument?.name ?? '-'),
            (
              'Pages',
              (_sourcePageCount ?? originalDocument?.pageCount)?.toString() ??
                  '-',
            ),
            (
              'File size',
              originalBytes == null ? '-' : _formatBytes(originalBytes.length),
            ),
          ]),
          const Divider(height: 1),
          const SizedBox(height: 10),
          infoSection('Split PDF', [
            (
              'Name',
              splitHasBeenApplied
                  ? 'split_pages.pdf'
                  : (selectedCount == 0 ? '-' : 'split_pages.pdf'),
            ),
            (
              'Pages',
              splitHasBeenApplied
                  ? '$selectedCount'
                  : (selectedCount == 0 ? '-' : '$selectedCount'),
            ),
            (
              'File size',
              outputBytes == null ? '-' : _formatBytes(outputBytes.length),
            ),
          ]),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _cropMarginFields() {
    final fields = <(String, TextEditingController)>[
      ('Top margin (pt)', _cropTop),
      ('Right margin (pt)', _cropRight),
      ('Bottom margin (pt)', _cropBottom),
      ('Left margin (pt)', _cropLeft),
    ];

    return Column(
      children: [
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: TextField(
              controller: field.$2,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                _value.text = [
                  _cropTop.text,
                  _cropRight.text,
                  _cropBottom.text,
                  _cropLeft.text,
                ].join(',');
              },
              decoration: InputDecoration(
                labelText: field.$1,
                suffixText: 'pt',
                isDense: true,
              ),
            ),
          ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Enter the amount to trim from each edge. The PDF preview updates after applying.',
            style: TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final margins = await VisualCropDialog.show(context);
            if (mounted) {
              final controller = StudioScope.read(context);
              final count =
                  controller.workingPageCount ??
                  controller.currentDocument?.pageCount;
              setState(() {
                if (count != null) _pageCount = count;
                if (margins != null && margins.length == 4) {
                  _cropTop.text = margins[0].round().toString();
                  _cropRight.text = margins[1].round().toString();
                  _cropBottom.text = margins[2].round().toString();
                  _cropLeft.text = margins[3].round().toString();
                  _value.text = margins.map((value) => value.round()).join(',');
                }
              });
            }
          },
          icon: const Icon(Icons.crop_free),
          label: const Text('Open visual crop editor'),
        ),
      ],
    );
  }

  Widget _pageAction(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        overlayColor: Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(32, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    ),
  );

  void _selectAll() => setState(() {
    _selectedPages
      ..clear()
      ..addAll(List<int>.generate(_pageCount ?? 0, (index) => index));
    _selectionOrder
      ..clear()
      ..addAll(_selectedPages.toList()..sort());
    _selectionOutputBytes = null;
    _value.text = _selectionOrder.map((page) => page + 1).join(',');
  });

  void _selectNone() => setState(() {
    _selectedPages.clear();
    _selectionOrder.clear();
    _selectionOutputBytes = null;
    _value.clear();
  });

  void _invertSelection() => setState(() {
    final count = _pageCount ?? 0;
    final next = <int>{
      for (var page = 0; page < count; page++)
        if (!_selectedPages.contains(page)) page,
    };
    _selectedPages
      ..clear()
      ..addAll(next);
    _selectionOrder
      ..clear()
      ..addAll(next.toList()..sort());
    _selectionOutputBytes = null;
    _value.text = _selectionOrder.map((page) => page + 1).join(',');
  });

  Future<void> _selectRange(int count) async {
    final from = TextEditingController(text: '1');
    final to = TextEditingController(text: '$count');
    final range = await showDialog<(int, int)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select page range'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: from,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'From'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: to,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'To'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final start = int.tryParse(from.text.trim());
              final end = int.tryParse(to.text.trim());
              if (start == null ||
                  end == null ||
                  start < 1 ||
                  end < start ||
                  end > count)
                return;
              Navigator.pop(dialogContext, (start, end));
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
    from.dispose();
    to.dispose();
    if (range == null || !mounted) return;
    setState(() {
      _selectedPages
        ..clear()
        ..addAll(
          List<int>.generate(
            range.$2 - range.$1 + 1,
            (index) => range.$1 - 1 + index,
          ),
        );
      _selectionOrder
        ..clear()
        ..addAll(_selectedPages.toList()..sort());
      _selectionOutputBytes = null;
      _value.text = _selectionOrder.map((page) => page + 1).join(',');
    });
  }

  void _togglePage(int page) {
    setState(() {
      if (_selectedPages.contains(page)) {
        _selectedPages.remove(page);
        _selectionOrder.remove(page);
      } else {
        _selectedPages.add(page);
        _selectionOrder.add(page);
      }
      _selectionOutputBytes = null;
      final pages = _selectionOrder;
      _value.text = pages.map((page) => page + 1).join(',');
    });
  }

  void _setPageOrder(List<int> order) {
    final count = _pageCount ?? 0;
    if (order.length != count ||
        order.toSet().length != count ||
        order.any((page) => page < 0 || page >= count)) {
      return;
    }

    setState(() {
      _pageOrder = List<int>.of(order);
      _value.text = order.map((page) => page + 1).join(',');
    });
  }

  Future<void> _refreshPages() async {
    if (!mounted) return;
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes;
    if (bytes == null) return;

    _sourceBytes ??= Uint8List.fromList(bytes);

    try {
      final count =
          controller.workingPageCount ??
          controller.currentDocument?.pageCount ??
          await controller.documents.pageCount(bytes);
      if (!mounted) return;
      _sourcePageCount ??= count;
      setState(() {
        _pageCount = count;
        _pageOrder = List<int>.generate(count, (index) => index);
        if (_isReorderTool) {
          _value.text = _pageOrder.map((page) => page + 1).join(',');
        }
        _selectedPages.clear();
        _selectionOrder.clear();
        _selectionOutputBytes = null;
        _thumbnailCache.clear();
        _lastBytesHash = bytes.hashCode;
      });
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'Could not load PDF pages',
        message: controller.friendlyError(error, action: 'load the PDF pages'),
      );
    }
  }

  Future<void> _run() async {
    final controller = StudioScope.read(context);
    if (_isPageSelectionTool &&
        _selectedPages.isEmpty &&
        widget.tool.id != 'rotate') {
      await AppErrorDialog.show(
        context,
        title: 'Select pages first',
        message:
            'Choose one or more page thumbnails before applying this operation.',
      );
      return;
    }
    var value = _value.text.trim();
    if (widget.tool.id == 'create') {
      final title = _createTitle.text.trim().isEmpty
          ? 'Untitled document'
          : _createTitle.text.trim();
      value = '$title|${_createBody.text}';
    } else if (widget.tool.id == 'createtable') {
      value = jsonEncode(_tableRows);
    } else if (widget.tool.id == 'createform') {
      value = jsonEncode({'template': _formTemplate, 'fields': _formFields});
    }
    if (widget.tool.id == 'compress') value = _compressionPolicy;
    if (widget.tool.id == 'stamp') value = _stampType;
    if (widget.tool.id == 'watermark') {
      value = [
        value,
        _watermarkSize.round(),
        _watermarkColor.toARGB32(),
        _watermarkOpacity,
      ].join('|');
    }
    if (widget.tool.id == 'crop') {
      value = [
        _cropTop.text,
        _cropRight.text,
        _cropBottom.text,
        _cropLeft.text,
      ].join(',');
    }
    if (widget.tool.id == 'renderpage' || widget.tool.id == 'renderall') {
      value = '${value.isEmpty ? '1' : value}|$_renderFormat';
    }
    value = value.trim();

    setState(() => _startingMessage = 'Preparing ${widget.tool.title}…');
    await WidgetsBinding.instance.endOfFrame;
    try {
      await controller.runTask('Applying ${widget.tool.title}…', () async {
        if (widget.tool.id == 'extract' || widget.tool.id == 'split') {
          final source = _sourceBytes ?? controller.activeDocumentBytes;
          if (source == null) {
            throw StateError('The original PDF is no longer available.');
          }
          final selected = PageSelectionParser().parse(
            value,
            pageCount: _sourcePageCount,
          );
          final output = await PdfPageService().extractInOrder(
            source,
            selected,
          );
          await controller.setWorkingCopy(
            output,
            name: widget.tool.id == 'split'
                ? 'split_pages.pdf'
                : 'extracted_pages.pdf',
          );
          if (widget.tool.id == 'split' && mounted)
            setState(() => _selectionOutputBytes = output);
        } else {
          final activeBytes = controller.activeDocumentBytes;
          if (activeBytes != null &&
              widget.tool.id != 'create' &&
              widget.tool.id != 'createtable' &&
              widget.tool.id != 'createform' &&
              _pageOrder.isNotEmpty &&
              !_isIdentityPageOrder(_pageOrder)) {
            final reordered = await PdfPageService().reorder(
              activeBytes,
              List<int>.of(_pageOrder),
            );
            await controller.setWorkingCopy(
              reordered,
              name: controller.currentDocument?.name ?? 'reordered.pdf',
            );
          }

          await ToolWorkflowExecutor.execute(context, widget.tool, value);
        }
      });
    } finally {
      if (mounted) setState(() => _startingMessage = null);
    }

    if (!mounted) return;
    if (controller.errorMessage != null) {
      await AppErrorDialog.show(
        context,
        title: 'Operation could not be completed',
        message: controller.errorMessage!,
      );
      controller.clearMessages();
      return;
    }

    if (widget.tool.id != 'extract' && widget.tool.id != 'split') {
      await _refreshPages();
    }
    if (!mounted) return;
    if (widget.tool.id == 'extract' && controller.activeDocumentBytes != null) {
      try {
        final extractedText = await PdfTextService().extract(
          controller.activeDocumentBytes!,
        );
        if (mounted) {
          setState(() {
            _lastExtractedText = extractedText;
            _lastExtractedTextCopied = false;
          });
          await _showExtractedPagesText();
        }
      } catch (error) {
        if (mounted) {
          await AppErrorDialog.show(
            context,
            title: 'Text extraction unavailable',
            message: controller.friendlyError(
              error,
              action: 'extract text from the selected pages',
            ),
          );
        }
      }
    }
    if (controller.hasWorkingCopy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Changes applied to the preview. Your original PDF is unchanged.',
          ),
        ),
      );
    }
  }

  Future<void> _showExtractedPagesText() async {
    final text = _lastExtractedText;
    if (text == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Extracted page text'),
        content: SizedBox(
          width: 760,
          height: 560,
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: text.isEmpty ? '_No selectable text was found._' : text,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) setState(() => _lastExtractedTextCopied = true);
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Text copied. Use “View copied text” in the left panel to inspect it.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy text'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _previewSelectedPages() async {
    final controller = StudioScope.read(context);
    final source = _sourceBytes ?? controller.activeDocumentBytes;
    if (source == null || _selectionOrder.isEmpty) return;
    try {
      final output = await PdfPageService().extractInOrder(
        source,
        List<int>.of(_selectionOrder),
      );
      final count = await controller.documents.pageCount(output);
      if (!mounted) return;
      if (widget.tool.id == 'split')
        setState(() => _selectionOutputBytes = output);
      await PdfChangesPreviewDialog.show(
        context,
        title: widget.tool.id == 'split'
            ? 'Split PDF preview'
            : 'Extracted pages preview',
        document: PdfDocumentAsset(
          name: 'selected_pages_preview.pdf',
          bytes: output,
          pageCount: count,
          isModified: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'Preview unavailable',
        message: controller.friendlyError(
          error,
          action: 'preview the selected pages',
        ),
      );
    }
  }

  Future<void> _showCopiedExtractedText() async {
    final text = _lastExtractedText;
    if (text == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Copied extracted text'),
        content: SizedBox(
          width: 720,
          height: 540,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(color: Colors.black87, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTextCopy() async {
    final controller = StudioScope.read(context);
    final bytes = controller.workingBytes;
    if (bytes == null) return;
    setState(() => _startingMessage = 'Preparing TXT export…');
    await WidgetsBinding.instance.endOfFrame;
    try {
      final text = await PdfTextService().extract(bytes);
      await WorkflowOutput.save(
        context,
        'document.txt',
        Uint8List.fromList(utf8.encode(text)),
        mimeType: 'text/plain',
      );
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'TXT export unavailable',
        message: controller.friendlyError(
          error,
          action: 'export the working PDF as TXT',
        ),
      );
    } finally {
      if (mounted) setState(() => _startingMessage = null);
    }
  }

  Future<void> _exportMarkdownCopy() async {
    final controller = StudioScope.read(context);
    final bytes = controller.workingBytes;
    if (bytes == null) return;
    setState(() => _startingMessage = 'Preparing Markdown export…');
    await WidgetsBinding.instance.endOfFrame;
    try {
      final text = await PdfTextService().extract(bytes);
      await WorkflowOutput.save(
        context,
        'document.md',
        Uint8List.fromList(utf8.encode('# Document $text')),
        mimeType: 'text/markdown',
      );
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'Markdown export unavailable',
        message: controller.friendlyError(
          error,
          action: 'export the working PDF as Markdown',
        ),
      );
    } finally {
      if (mounted) setState(() => _startingMessage = null);
    }
  }

  Future<void> _previewChanges() async {
    final controller = StudioScope.read(context);
    final bytes = controller.workingBytes;
    if (bytes == null) return;

    try {
      final count =
          controller.workingPageCount ??
          await controller.documents.pageCount(bytes);
      if (!mounted) return;

      await PdfChangesPreviewDialog.show(
        context,
        title: controller.workingName ?? widget.tool.title,
        document: PdfDocumentAsset(
          name: controller.workingName ?? 'preview.pdf',
          bytes: bytes,
          pageCount: count,
          isModified: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await AppErrorDialog.show(
        context,
        title: 'Preview unavailable',
        message: controller.friendlyError(
          error,
          action: 'preview the changed PDF',
        ),
      );
    }
  }

  Future<void> _exportCopy() async {
    final controller = StudioScope.read(context);
    setState(() => _startingMessage = 'Preparing PDF export…');
    await WidgetsBinding.instance.endOfFrame;
    try {
      await controller.runTask(
        'Exporting PDF copy…',
        controller.exportWorkingCopy,
      );
    } finally {
      if (mounted) setState(() => _startingMessage = null);
    }
    if (!mounted) return;

    if (controller.errorMessage != null) {
      await AppErrorDialog.show(
        context,
        title: 'Export failed',
        message: controller.errorMessage!,
      );
      controller.clearMessages();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF copy exported. The original file was not changed.'),
      ),
    );
  }

  void _discardChanges() {
    StudioScope.read(context).clearWorkingCopy();
    setState(() {
      _selectedPages.clear();
      _selectionOrder.clear();
      _pageOrder = [];
      _value.clear();
      _thumbnailCache.clear();
      _lastExtractedText = null;
      _lastExtractedTextCopied = false;
      _selectionOutputBytes = null;
      _sourceBytes = null;
      _sourcePageCount = null;
    });
    _refreshPages();
  }

  String _pageInstruction(int count) {
    if (_isReorderTool)
      return 'Drag and drop the page thumbnails to set their new order.';
    if (widget.tool.id == 'split') {
      return 'Select pages on the left, then drag them into the output order on the right.';
    }
    if (widget.tool.id == 'extract') {
      return 'Choose the pages to extract, then arrange their order in the output pane.';
    }
    if (widget.tool.id == 'duplicate')
      return 'Select one or more pages. A copy will be inserted immediately after each selected page.';
    if (widget.tool.id == 'rotate')
      return 'Select the pages to rotate. Leave every page unselected to rotate the entire document.';
    return 'Select the pages you want this operation to affect. $count pages are available.';
  }

  String get _label => switch (widget.tool.id) {
    'split' => 'Select pages to include in the split PDF',
    'watermark' => 'Watermark text',
    'stamp' => 'Stamp: draft, approved or confidential',
    'compress' => 'Compression policy',
    'encrypt' || 'decrypt' => 'Password',
    'search' => 'Search phrase',
    'crop' => 'Margins: top,right,bottom,left (points)',
    'resize' => 'Page width,height (points)',
    'create' => 'Document title | document text',
    'metadata' => 'Document title',
    'redact' => 'Page,x,y,width,height (points)',
    'annotations' || 'renderpage' => 'Page number',
    'fillform' => 'Field name | value',
    'moveimage' => 'Page,imageName,x,y,width,height',
    'sign' => 'Certificate password',
    'attachments' => 'Attachment name (blank to list)',
    'createtable' => 'Rows separated by ; and cells by ,',
    'createform' => 'Field name',
    _ => 'Options (if required)',
  };

  String get _hint => switch (widget.tool.id) {
    'split' => 'Select pages on the right',
    'watermark' => 'CONFIDENTIAL',
    'stamp' => 'draft',
    'compress' => 'ebook',
    'search' => 'invoice number',
    'crop' => '36,36,36,36',
    'resize' => '595,842',
    'create' => 'Invoice | Enter the body text here',
    'redact' => '1,50,700,200,24',
    'fillform' => 'customer_name|Drew',
    'moveimage' => '1,Im0,50,500,200,100',
    'createtable' => 'Item,Quantity;Paper,3;Ink,2',
    'createform' => 'customer_name',
    _ => '',
  };
}

class _RedactionPreviewPainter extends CustomPainter {
  const _RedactionPreviewPainter({
    required this.hits,
    required this.pageWidth,
    required this.pageHeight,
  });

  final List<PdfSearchHit> hits;
  final double pageWidth;
  final double pageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (pageWidth <= 0 || pageHeight <= 0) return;

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final hit in hits) {
      final bounds = hit.bounds;
      final rect = Rect.fromLTWH(
        bounds.x / pageWidth * size.width,
        (pageHeight - bounds.y - bounds.height) / pageHeight * size.height,
        bounds.width / pageWidth * size.width,
        bounds.height / pageHeight * size.height,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RedactionPreviewPainter oldDelegate) =>
      oldDelegate.hits != hits ||
      oldDelegate.pageWidth != pageWidth ||
      oldDelegate.pageHeight != pageHeight;
}
