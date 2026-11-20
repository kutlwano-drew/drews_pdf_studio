import 'dart:typed_data';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'pdf_runtime.dart';

class PdfCreationService {
  PdfCreationService._();
  static final instance = PdfCreationService._();
  final _runtime = PdfRuntime.instance;

  Future<Uint8List> createTextDocument({
    required String title,
    required String body,
    String? author,
  }) => _runtime.output((sink) => _runtime.engine.buildTo(sink, (builder) async {
        await builder.setMetadata(PdfMetadata(title: title, author: author));
        final page = await builder.addPage();
        await page.heading(1, title);
        await page.paragraph(body);
      }));

  Future<Uint8List> createTableDocument({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) => _runtime.output((sink) => _runtime.engine.buildTo(sink, (builder) async {
        await builder.setMetadata(PdfMetadata(title: title));
        final page = await builder.addPage();
        await page.heading(1, title);
        await page.table(
          headers.map((header) => PdfTableColumn(header)).toList(),
          rows.map((row) => row.map((cell) => PdfTableCell(cell)).toList()).toList(),
        );
      }));

  Future<Uint8List> createFillableForm({required String title}) =>
      _runtime.output((sink) => _runtime.engine.buildTo(sink, (builder) async {
        await builder.setMetadata(PdfMetadata(title: title));
        final page = await builder.addPage();
        await page.heading(1, title);
        await page.paragraph('Complete the fields below.');
        await page.text('Full name');
        await page.textField('full_name', const PdfRect(x: 72, y: 640, width: 420, height: 28));
        await page.text('Email address');
        await page.textField('email', const PdfRect(x: 72, y: 575, width: 420, height: 28));
        await page.checkbox('accept_terms', const PdfRect(x: 72, y: 520, width: 16, height: 16));
        await page.text('I accept the terms and conditions.');
        await page.signatureField('signature', const PdfRect(x: 72, y: 420, width: 240, height: 55));
      }));

  Future<Uint8List> createShapesDocument() =>
      _runtime.output((sink) => _runtime.engine.buildTo(sink, (builder) async {
        final page = await builder.addPage();
        await page.heading(1, 'Shapes and drawing');
        await page.rect(
          const PdfRect(x: 72, y: 500, width: 200, height: 80),
          fill: PdfColor.red,
          stroke: const PdfStroke(color: PdfColor.black, width: 2),
        );
        await page.line(
          const PdfPoint(72, 400),
          const PdfPoint(272, 480),
          stroke: const PdfStroke(dash: [3, 2]),
        );
      }));

  Future<Uint8List> createImagePage(Uint8List imageBytes, {String? altText}) =>
      _runtime.output((sink) => _runtime.engine.buildTo(sink, (builder) async {
        final page = await builder.addPage();
        await page.image(
          MemorySource(imageBytes),
          const PdfRect(x: 50, y: 100, width: 495, height: 640),
          altText: altText,
        );
      }));

  Future<Uint8List> photosToPdf(List<Uint8List> images) =>
      _runtime.output((sink) => _runtime.engine.imagesToPdf(
            images.map((bytes) => MemorySource(bytes)).toList(),
            sink,
          ));
}
