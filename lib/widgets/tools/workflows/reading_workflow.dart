import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/editing/pdf_attachment_service.dart';
import '../../../services/pdf/forms/pdf_form_service.dart';
import '../../../services/pdf/reading/pdf_analysis_service.dart';
import '../../../services/pdf/reading/pdf_render_service.dart';
import '../../../services/pdf/reading/pdf_text_service.dart';
import '../../../services/files/directory_export_service.dart';

import 'tool_workflow.dart';
import 'workflow_output.dart';

class ReadingWorkflow implements ToolWorkflow {
  final _text = PdfTextService();
  final _analysis = PdfAnalysisService();
  final _render = PdfRenderService();
  final _forms = PdfFormService();
  final _attachments = PdfAttachmentService();

  @override
  Future<void> run(
    BuildContext context,
    ToolDefinition tool,
    String value,
  ) async {
    final bytes = StudioScope.read(context).activeDocumentBytes!;

    if (tool.id == 'renderpage') {
      final parts = value.split('|');
      final page = (int.tryParse(parts.first) ?? 1) - 1;
      final format = parts.length > 1 ? parts[1] : 'png';
      final image = await _render.renderPage(bytes, page, format: format);
      final extension = format == 'jpg' ? 'jpg' : format;
      final mime = format == 'jpg' ? 'image/jpeg' : 'image/png';

      await WorkflowOutput.save(
        context,
        'page_preview.$extension',
        image,
        mimeType: mime,
      );
      return;
    }

    if (tool.id == 'extractimages') {
      final images = await _render.extractImages(bytes);
      final pngFiles = <String, Uint8List>{};

      for (var index = 0; index < images.length; index++) {
        pngFiles['extracted_image_${index + 1}.png'] =
            _render.convertImageFormat(images[index], 'png');
      }

      if (pngFiles.isEmpty) {
        await _show(context, 'Extract images', 'No embedded images were found.');
        return;
      }

      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Choose a folder for extracted PNG images',
      );

      if (directory != null) {
        final exported = await exportFilesToDirectory(directory, pngFiles);
        if (exported) {
          await _show(
            context,
            'Extract images',
            'Exported ${pngFiles.length} PNG image${pngFiles.length == 1 ? '' : 's'} to the selected folder.',
          );
          return;
        }
      }

      for (final entry in pngFiles.entries) {
        await WorkflowOutput.save(
          context,
          entry.key,
          entry.value,
          mimeType: 'image/png',
        );
      }
      return;
    }

    if (tool.id == 'attachments') {
      if (value.isNotEmpty) {
        final file = await _attachments.extract(bytes, value);

        await WorkflowOutput.save(
          context,
          value,
          file,
          mimeType: 'application/octet-stream',
        );
      } else {
        final result = await _analysis.attachments(bytes);
        await _show(context, tool.title, result);
      }

      return;
    }

    if (tool.id == 'forms') {
      await _show(context, tool.title, await _forms.fields(bytes));

      return;
    }

    if (tool.id == 'xfa') {
      await _show(context, tool.title, await _analysis.xfa(bytes));

      return;
    }

    // Search is handled here, before the general result switch.
    if (tool.id == 'search') {
      if (value.trim().isEmpty) {
        throw const FormatException('Enter a word or phrase to search for.');
      }

      final hits = await _text.search(bytes, value.trim());

      await _showSearchResults(context, tool.title, value, hits, bytes);

      return;
    }

    if (tool.id == 'renderall') {
      final parts = value.split('|');
      final format = parts.length > 1 ? parts[1] : 'png';
      final pages = await _render.renderAllPages(bytes, format: format);
      final extension = format == 'jpg' ? 'jpg' : format;
      final mime = format == 'jpg' ? 'image/jpeg' : 'image/png';
      for (var index = 0; index < pages.length; index++) {
        await WorkflowOutput.save(
          context,
          '${'rendered_page'}_page_${index + 1}.$extension',
          pages[index],
          mimeType: mime,
        );
      }
      await _show(context, 'Render all pages', 'Rendered ${pages.length} pages as ${format.toUpperCase()}.');
      return;
    }

    final result = switch (tool.id) {
      'text' => await _text.extract(bytes),
      'info' => await _analysis.info(bytes),
      'pageinfo' => await _analysis.pageInfo(bytes),
      'classify' => await _analysis.classifyDocument(bytes),
      'annotations' => await _analysis.annotations(
        bytes,
        (int.tryParse(value) ?? 1) - 1,
      ),
      'bookmarks' => await _analysis.bookmarks(bytes),
      _ => await _analysis.classifyPages(bytes),
    };

    if (tool.id == 'text') {
      await _showExtractedText(context, tool.title, result.toString());
    } else {
      await _show(context, tool.title, result);
    }
  }

  Future<void> _showExtractedText(
    BuildContext context,
    String title,
    String text,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 760,
          height: 560,
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: text.isEmpty ? '_No text was found in this PDF._' : text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, height: 1.5),
                a: const TextStyle(
                  color: Color(0xFF1565C0),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));

              if (!dialogContext.mounted) return;

              final hostContext = Navigator.of(
                dialogContext,
                rootNavigator: true,
              ).context;

              Navigator.pop(dialogContext);

              if (!hostContext.mounted) return;

              await showDialog<void>(
                context: hostContext,
                builder: (copiedContext) => AlertDialog(
                  title: const Text('Copied extracted text'),
                  content: SizedBox(
                    width: 720,
                    height: 540,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(copiedContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy text'),
          ),
          TextButton.icon(
            onPressed: () => WorkflowOutput.save(
              dialogContext,
              'extracted_text.txt',
              Uint8List.fromList(utf8.encode(text)),
              mimeType: 'text/plain',
            ),
            icon: const Icon(Icons.text_snippet_outlined),
            label: const Text('Export TXT'),
          ),
          TextButton.icon(
            onPressed: () => WorkflowOutput.save(
              dialogContext,
              'extracted_text.md',
              Uint8List.fromList(utf8.encode(text)),
              mimeType: 'text/markdown',
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Export MD'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchResults(
    BuildContext context,
    String title,
    String query,
    List<PdfSearchHit> hits,
    Uint8List bytes,
  ) async {
    final pageInfo = await _analysis.pageInfo(bytes) as List<PdfPageInfo>;

    final resultText = hits
        .map((hit) => 'Page ${hit.page + 1}: ${hit.text}')
        .join('\n');

    final markdownText =
        '# Search results\n\n'
        'Query: **$query**\n\n'
        '${hits.asMap().entries.map((entry) => '## Match ${entry.key + 1} · Page ${entry.value.page + 1}\n\n'
            '${entry.value.text}').join('\n\n')}';

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$title · ${hits.length} matches'),
        content: SizedBox(
          width: 720,
          height: 540,
          child: hits.isEmpty
              ? Text('No matches found for "$query".')
              : ListView.separated(
                  itemCount: hits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hit = hits[index];

                    return ListTile(
                      title: Text(
                        'Page ${hit.page + 1}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: SelectableText.rich(
                        _highlightMatches(hit.text, query),
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'View highlighted page',
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () {
                          if (hit.page < 0 || hit.page >= pageInfo.length) {
                            return;
                          }

                          _showSearchPagePreview(
                            dialogContext,
                            bytes,
                            hit.page,
                            hits
                                .where((item) => item.page == hit.page)
                                .toList(),
                            pageInfo[hit.page],
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton.icon(
            onPressed: hits.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: resultText));

                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Search results copied.')),
                      );
                    }
                  },
            icon: const Icon(Icons.copy),
            label: const Text('Copy results'),
          ),
          TextButton.icon(
            onPressed: hits.isEmpty
                ? null
                : () => WorkflowOutput.save(
                    dialogContext,
                    'search_results.txt',
                    Uint8List.fromList(utf8.encode(resultText)),
                    mimeType: 'text/plain',
                  ),
            icon: const Icon(Icons.text_snippet_outlined),
            label: const Text('Export TXT'),
          ),
          TextButton.icon(
            onPressed: hits.isEmpty
                ? null
                : () => WorkflowOutput.save(
                    dialogContext,
                    'search_results.md',
                    Uint8List.fromList(utf8.encode(markdownText)),
                    mimeType: 'text/markdown',
                  ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Export MD'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchPagePreview(
    BuildContext context,
    Uint8List bytes,
    int page,
    List<PdfSearchHit> hits,
    PdfPageInfo info,
  ) async {
    final image = await _render.renderPage(bytes, page);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 900,
          height: MediaQuery.sizeOf(context).height * .88,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Page ${page + 1} · Search highlights',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: .5,
                    maxScale: 5,
                    child: AspectRatio(
                      aspectRatio: info.width / info.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(image, fit: BoxFit.contain),
                          CustomPaint(
                            painter: _SearchHighlightPainter(
                              hits: hits,
                              pageWidth: info.width,
                              pageHeight: info.height,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _highlightMatches(String text, String query) {
    final spans = <TextSpan>[];

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.isEmpty) {
      return TextSpan(text: text);
    }

    var cursor = 0;

    while (cursor < text.length) {
      final match = lowerText.indexOf(lowerQuery, cursor);

      if (match < 0) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }

      if (match > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match)));
      }

      spans.add(
        TextSpan(
          text: text.substring(match, match + query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE082),
            fontWeight: FontWeight.w800,
          ),
        ),
      );

      cursor = match + query.length;
    }

    return TextSpan(children: spans);
  }

  Future<void> _show(BuildContext context, String title, Object result) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(result.toString()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SearchHighlightPainter extends CustomPainter {
  const _SearchHighlightPainter({
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

    final fill = Paint()
      ..color = const Color(0x66FFFF00)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final hit in hits) {
      final bounds = hit.bounds;

      final rect = Rect.fromLTWH(
        bounds.x / pageWidth * size.width,
        (pageHeight - bounds.y - bounds.height) / pageHeight * size.height,
        bounds.width / pageWidth * size.width,
        bounds.height / pageHeight * size.height,
      );

      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }
  }

  @override
  bool shouldRepaint(covariant _SearchHighlightPainter oldDelegate) {
    return oldDelegate.hits != hits ||
        oldDelegate.pageWidth != pageWidth ||
        oldDelegate.pageHeight != pageHeight;
  }
}
