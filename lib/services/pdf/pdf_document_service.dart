import 'pdf_engine.dart';

class PdfDocumentService {
  Future<int> pageCount(List<int> bytes, {String? password}) async {
    final info = await PdfEngine.instance.pdf.info(
      PdfEngine.instance.input(bytes, password: password),
    );
    return info.pageCount;
  }

  Future<dynamic> inspect(List<int> bytes, {String? password}) =>
      PdfEngine.instance.pdf.info(
        PdfEngine.instance.input(bytes, password: password),
      );
}
