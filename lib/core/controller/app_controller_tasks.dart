part of '../app_controller.dart';

extension AppControllerTasks on AppController {
  Future<void> convertToOffice(OfficeDocumentFormat format) async {
    final document = this.currentDocument;
    if (document == null) return;
    await this._run('Converting PDF…', () async {
      final output = await PdfConversionService.instance.pdfToOffice(document.bytes, format);
      await this.files.saveBytes(
        '${this._baseName(document.name)}.${format.name}',
        output,
        mimeType: 'application/octet-stream',
      );
    });
  }

  Future<void> extractText() async {
    final document = this.currentDocument;
    if (document == null) return;
    await this._run('Extracting text…', () async {
      this.extractedText = await PdfReadService.instance.extractText(document.bytes);
      this.status = 'Text extracted';
    });
  }

  Future<void> validateStandards() async {
    final document = this.currentDocument;
    if (document == null) return;
    await this._run('Validating PDF standards…', () async {
      final pdfA = await PdfStandardsService.instance.validatePdfA(document.bytes);
      final pdfUa = await PdfStandardsService.instance.validatePdfUa(document.bytes);
      this.status = 'PDF/A: $pdfA · PDF/UA: $pdfUa';
    });
  }

  Future<void> createDocument(String title, String body) async {
    await this._run('Creating PDF…', () async {
      final bytes = await PdfCreationService.instance.createTextDocument(title: title, body: body);
      await this._replaceCurrent('$title.pdf', bytes);
    });
  }
}
