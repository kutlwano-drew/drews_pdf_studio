import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image/image.dart' as img;

import '../../core/state/studio_scope.dart';
import '../../services/pdf/editing/pdf_mark_service.dart';
import 'annotation_canvas_painter.dart';
import 'annotation_drawing_dialog_view.dart';

class AnnotationDrawingDialogViewState extends State<AnnotationDrawingDialogView> {
  final List<List<Offset>> _strokes = [];
  final _page = TextEditingController(text: '1');
  double _x = 48;
  double _y = 480;
  double _width = 420;
  double _height = 220;
  Size _canvasSize = const Size(420, 280);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: SizedBox(
          width: 900,
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(children: [
            ListTile(title: Text('annotation.title'.tr()), subtitle: Text('annotation.subtitle'.tr()), trailing: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))),
            const Divider(height: 1),
            Expanded(child: Row(children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
                Expanded(child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFCDD3DC)), borderRadius: BorderRadius.circular(12)),
                  child: LayoutBuilder(builder: (context, constraints) {
                    _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onPanStart: (details) => setState(() => _strokes.add([details.localPosition])),
                      onPanUpdate: (details) => setState(() { if (_strokes.isNotEmpty) _strokes.last.add(details.localPosition); }),
                      child: CustomPaint(painter: AnnotationCanvasPainter(_strokes), child: const SizedBox.expand()),
                    );
                  }),
                )),
                const SizedBox(height: 8),
                Row(children: [
                  Text('annotation.canvas_hint'.tr(), style: TextStyle(fontSize: 11, color: Colors.black54)),
                  const Spacer(),
                  TextButton.icon(onPressed: () => setState(_strokes.clear), icon: const Icon(Icons.delete_outline, size: 16), label: Text('annotation.clear'.tr())),
                ]),
              ]))),
              SizedBox(width: 280, child: ListView(padding: const EdgeInsets.all(18), children: [
                TextField(controller: _page, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'annotation.target_page'.tr())),
                const SizedBox(height: 14),
                _slider('annotation.horizontal'.tr(), _x, 0, 500, (value) => setState(() => _x = value)),
                _slider('annotation.vertical'.tr(), _y, 0, 740, (value) => setState(() => _y = value)),
                _slider('annotation.width'.tr(), _width, 40, 550, (value) => setState(() => _width = value)),
                _slider('annotation.height'.tr(), _height, 30, 400, (value) => setState(() => _height = value)),
                Text('annotation.description'.tr(), style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4)),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
              ])),
            ])),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('annotation.cancel'.tr())),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _busy || _strokes.isEmpty ? null : _apply, icon: const Icon(Icons.draw_outlined), label: Text(_busy ? 'annotation.applying'.tr() : 'annotation.apply'.tr())),
            ])),
          ]),
        ),
      );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> changed) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label · ${value.round()} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Slider(value: value, min: min, max: max, onChanged: changed),
        ],
      );

  Future<void> _apply() async {
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes;
    final pageNumber = int.tryParse(_page.text.trim());
    if (bytes == null || pageNumber == null || pageNumber < 1) {
      setState(() => _error = 'annotation.invalid_page'.tr());
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final image = _renderDrawing();
      final output = await PdfMarkService().imageStampOnPage(
        bytes,
        image,
        pageNumber: pageNumber,
        x: _x,
        y: _y,
        width: _width,
        height: _height,
      );
      await controller.setWorkingCopy(output);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = controller.friendlyError(error, action: 'apply the annotation'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Uint8List _renderDrawing() {
    final canvas = img.Image(width: 900, height: 600, numChannels: 4, backgroundColor: img.ColorRgba8(0, 0, 0, 0));
    final ink = img.ColorRgba8(25, 35, 55, 255);
    for (final stroke in _strokes) {
      if (stroke.length == 1) {
        img.drawCircle(canvas, x: (stroke.first.dx / _canvasSize.width * 900).round(), y: (stroke.first.dy / _canvasSize.height * 600).round(), radius: 4, color: ink);
      }
      for (var index = 1; index < stroke.length; index++) {
        final from = stroke[index - 1];
        final to = stroke[index];
        img.drawLine(
          canvas,
          x1: (from.dx / _canvasSize.width * 900).round(),
          y1: (from.dy / _canvasSize.height * 600).round(),
          x2: (to.dx / _canvasSize.width * 900).round(),
          y2: (to.dy / _canvasSize.height * 600).round(),
          color: ink,
          thickness: 7,
        );
      }
    }
    return Uint8List.fromList(img.encodePng(canvas));
  }
}
