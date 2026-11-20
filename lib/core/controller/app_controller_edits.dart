part of '../app_controller.dart';

extension AppControllerPdfEdits on AppController {
  Future<void> rotate({int? page}) => this._edit('Rotating pages…', (bytes) => PdfOrganizeService.instance.rotatePages(bytes, page: page));
  Future<void> removePages(List<int> pages) => this._edit('Removing pages…', (bytes) => PdfOrganizeService.instance.removePages(bytes, pages));
  Future<void> keepPages(List<int> pages) => this._edit('Extracting selected pages…', (bytes) => PdfOrganizeService.instance.keepPages(bytes, pages));
  Future<void> reorderPages(List<int> order) => this._edit('Reordering pages…', (bytes) => PdfOrganizeService.instance.reorderPages(bytes, order));
  Future<void> watermark(String text) => this._edit('Adding watermark…', (bytes) => PdfEditService.instance.watermark(bytes, text));
  Future<void> stamp(String name) => this._edit('Applying stamp…', (bytes) => PdfEditService.instance.stamp(bytes, name));

  Future<void> cropMargins({double top = 24, double bottom = 24, double left = 24, double right = 24}) =>
      this._edit('Cropping page margins…', (bytes) => PdfEditService.instance.cropMargins(bytes, top: top, bottom: bottom, left: left, right: right));

  Future<void> flattenForms() => this._edit('Flattening form fields…', PdfEditService.instance.flattenForms);
  Future<void> convertToPdfA() => this._edit('Converting to PDF/A…', PdfStandardsService.instance.convertToPdfA);
  Future<void> applyCustom(String label, Future<Uint8List> Function(Uint8List) operation) => this._edit(label, operation);

  Future<void> saveExport(String fileName, Uint8List bytes, {String mimeType = 'application/octet-stream'}) =>
      this.files.saveBytes(fileName, bytes, mimeType: mimeType);

  Future<void> compress(PdfImagePolicy policy) async {
    final document = this.currentDocument;
    if (document == null) return;
    await this._run('Optimising PDF…', () async {
      final before = document.bytes.length;
      final bytes = await PdfEditService.instance.compress(document.bytes, policy: policy);
      await this._replaceCurrent(document.name, bytes);
      this.status = 'File size: ${this._formatBytes(before)} → ${this._formatBytes(bytes.length)}';
    });
  }

  Future<void> updateMetadata({String? title, String? author, String? subject, String? keywords}) =>
      this._edit('Updating document information…', (bytes) => PdfEditService.instance.updateMetadata(
        bytes, title: title, author: author, subject: subject, keywords: keywords,
      ));

  Future<void> sanitize() => this._edit('Removing hidden document data…', PdfEditService.instance.sanitize);

  Future<void> encrypt(String password) async {
    final document = this.currentDocument;
    if (document == null) return;
    await this._run('Encrypting PDF…', () async {
      final bytes = await PdfSecurityService.instance.encrypt(document.bytes, password);
      this.currentDocument = PdfDocumentItem(name: document.name, bytes: bytes, pageCount: document.pageCount, modified: true);
      this.recentDocuments.removeWhere((item) => item.name == document.name);
      this.recentDocuments.insert(0, this.currentDocument!);
      this.status = 'PDF encrypted';
    });
  }

  Future<void> decrypt(String password) => this._edit('Decrypting PDF…', (bytes) => PdfSecurityService.instance.decrypt(bytes, password));
}