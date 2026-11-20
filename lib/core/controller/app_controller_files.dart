part of '../app_controller.dart';

extension AppControllerFiles on AppController {
  Future<void> openPdf() async {
    final picked = await this.files.pickPdf();
    if (picked == null) return;
    await this.openBytes(picked.name, picked.bytes);
  }

  Future<void> openBytes(String name, Uint8List bytes) async {
    await this._run('Opening PDF…', () async {
      int? pageCount;
      var passwordProtected = false;
      try {
        final info = await PdfReadService.instance.inspect(bytes);
        pageCount = info['pageCount'] as int?;
      } on PdfPasswordRequired {
        passwordProtected = true;
      }
      final item = PdfDocumentItem(name: name, bytes: bytes, pageCount: pageCount);
      this.currentDocument = item;
      this.recentDocuments.removeWhere((doc) => doc.name == name);
      this.recentDocuments.insert(0, item);
      this.status = passwordProtected ? 'Password-protected PDF · decrypt before editing' : 'Opened $name';
    });
  }

  Future<void> saveCurrent() async {
    final document = this.currentDocument;
    if (document == null) return;
    await this.files.saveBytes(
      this._outputName(document.name),
      document.bytes,
      mimeType: 'application/pdf',
    );
  }

  Future<void> mergePdfs() async {
    final picked = await this.files.pickPdfs();
    if (picked.length < 2) return;
    await this._run('Merging PDFs…', () async {
      final bytes = await PdfOrganizeService.instance.merge(picked.map((file) => file.bytes).toList());
      await this._replaceCurrent('merged.pdf', bytes);
    });
  }
}
