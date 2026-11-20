import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../pdf_engine.dart';

class PdfAnalysisService {
  Future<dynamic> info(List<int> bytes) => PdfEngine.instance.pdf.info(PdfEngine.instance.input(bytes));
  Future<dynamic> pageInfo(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.pageInfo());
  Future<dynamic> classifyPages(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.classifyPages());
  Future<dynamic> classifyDocument(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.classifyDocument());
  Future<dynamic> bookmarks(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.bookmarkRanges());
  Future<dynamic> annotations(List<int> bytes, int page) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.annotations(page));
  Future<dynamic> attachments(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.attachments());
  Future<dynamic> signatures(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.signatures());
  Future<dynamic> verifySignatures(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.verifySignatures());
  Future<dynamic> xfa(List<int> bytes) => PdfEngine.instance.pdf.read(PdfEngine.instance.input(bytes), (document) => document.xfa());
}
