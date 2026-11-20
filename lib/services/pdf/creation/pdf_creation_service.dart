import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfCreationService {
  Future<Uint8List> fromText(String title, String body) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.buildTo(sink, (builder) async {
      final page = await builder.addPage();
      await page.heading(1, title);
      await page.paragraph(body);
    });
    return sink.takeBytes();
  }


  Future<Uint8List> fromMarkdown(String title, String markdown) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.buildTo(sink, (builder) async {
      var page = await builder.addPage();
      await page.heading(1, title);
      var linesOnPage = 0;

      for (final rawLine in markdown.split(RegExp(r'\r?\n'))) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          await page.space(6);
          linesOnPage++;
          continue;
        }

        if (linesOnPage >= 32) {
          page = await builder.addPage();
          linesOnPage = 0;
        }

        final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
        if (heading != null) {
          await page.heading(
            heading.group(1)!.length,
            heading.group(2)!,
          );
          linesOnPage++;
          continue;
        }

        if (line == '---' || line == '***') {
          await page.horizontalRule();
          linesOnPage++;
          continue;
        }

        if (line.startsWith('> ')) {
          await page.text(
            line.substring(2),
            style: const PdfTextStyle(italic: true),
          );
          await page.newline();
          linesOnPage++;
          continue;
        }

        final bullet = line.startsWith('- ') ||
            line.startsWith('* ') ||
            RegExp(r'^\d+\. ').hasMatch(line);
        final content = bullet
            ? line.replaceFirst(RegExp(r'^(- |\* |\d+\. )'), '• ')
            : line;

        final inlinePattern = RegExp(r'(\*\*.+?\*\*|==.+?==|\*.+?\*)');
        var cursor = 0;
        for (final match in inlinePattern.allMatches(content)) {
          if (match.start > cursor) {
            await page.text(content.substring(cursor, match.start));
          }

          final token = match.group(0)!;
          if (token.startsWith('**')) {
            await page.text(
              token.substring(2, token.length - 2),
              style: const PdfTextStyle(bold: true),
            );
          } else if (token.startsWith('==')) {
            await page.text(
              token.substring(2, token.length - 2),
              markup: const PdfMarkup(PdfMarkupKind.highlight),
            );
          } else {
            await page.text(
              token.substring(1, token.length - 1),
              style: const PdfTextStyle(italic: true),
            );
          }
          cursor = match.end;
        }

        if (cursor < content.length) {
          await page.text(content.substring(cursor));
        }
        await page.newline();
        linesOnPage++;
      }
    });
    return sink.takeBytes();
  }

  Future<Uint8List> fromTable(List<List<String>> rows) async {
    if (rows.isEmpty || rows.first.length < 2) {
      throw const FormatException('A table needs at least two columns.');
    }
    final sink = MemorySink();
    await PdfEngine.instance.pdf.buildTo(sink, (builder) async {
      final page = await builder.addPage();
      await page.heading(1, 'Generated table');
      final header = rows.first;
      final columns = [
        for (var index = 0; index < header.length; index++)
          PdfTableColumn(
            header[index].trim().isEmpty ? 'Column ${index + 1}' : header[index].trim(),
          ),
      ];
      final cells = [
        for (final row in rows.skip(1))
          [
            for (var index = 0; index < header.length; index++)
              PdfTableCell(index < row.length ? row[index] : ''),
          ],
      ];
      await page.table(columns, cells);
    });
    return sink.takeBytes();
  }

  Future<Uint8List> fromShapes() async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.buildTo(sink, (builder) async {
      final page = await builder.addPage();
      await page.heading(1, 'Shapes');
      await page.rect(
        const PdfRect(x: 72, y: 500, width: 220, height: 90),
        fill: PdfColor.red,
        stroke: const PdfStroke(color: PdfColor.black, width: 2),
      );
      await page.line(
        const PdfPoint(72, 420), const PdfPoint(292, 460),
        stroke: const PdfStroke(color: PdfColor.black, width: 1),
      );
    });
    return sink.takeBytes();
  }

  Future<Uint8List> fromForm(String fieldName) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.buildTo(sink, (builder) async {
      final page = await builder.addPage();
      await page.heading(1, 'Fillable form');
      await page.textField(fieldName, const PdfRect(x: 72, y: 650, width: 320, height: 32));
    });
    return sink.takeBytes();
  }

  Future<Uint8List> fromFormTemplate({
    required String title,
    required List<Map<String, String>> fields,
  }) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.buildTo(sink, (builder) async {
      var page = await builder.addPage();
      await page.heading(1, title);
      await page.paragraph('Complete the fields below.');
      var y = 690.0;
      var fieldIndex = 0;

      for (final field in fields) {
        final label = (field['label'] ?? 'Field ${fieldIndex + 1}').trim().isEmpty
            ? 'Field ${fieldIndex + 1}'
            : (field['label'] ?? 'Field ${fieldIndex + 1}').trim();
        final type = field['type'] ?? 'text';

        if (y < 120) {
          page = await builder.addPage();
          y = 690;
        }

        await page.text(label);

        if (type == 'checkbox') {
          await page.checkbox(
            'field_${fieldIndex + 1}',
            PdfRect(x: 72, y: y - 4, width: 16, height: 16),
          );
          y -= 42;
        } else {
          await page.textField(
            'field_${fieldIndex + 1}',
            PdfRect(
              x: 72,
              y: y - (type == 'multiline' ? 70 : 30),
              width: 420,
              height: type == 'multiline' ? 58 : 28,
            ),
          );
          y -= type == 'multiline' ? 92 : 54;
        }

        fieldIndex++;
      }
    });
    return sink.takeBytes();
  }

  Future<Uint8List> fromImages(List<Uint8List> images) async {
    final sink = MemorySink();
    await PdfEngine.instance.pdf.imagesToPdf(
      images.map((bytes) => MemorySource(bytes)).toList(), sink,
    );
    return sink.takeBytes();
  }
}
