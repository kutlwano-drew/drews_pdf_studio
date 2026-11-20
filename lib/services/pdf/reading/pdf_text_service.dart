import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfTextService {
  Future<String> extract(List<int> bytes, {String? password}) =>
      PdfEngine.instance.pdf.readOnce(
        PdfEngine.instance.input(bytes, password: password),
      ).text();

  Future<List<PdfSearchHit>> search(List<int> bytes, String query, {String? password}) =>
      PdfEngine.instance.pdf.readOnce(
        PdfEngine.instance.input(bytes, password: password),
      ).search(query);
}
