import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/state/studio_scope.dart';
import '../../services/images/image_processing_service.dart';
import 'image_tools_dialog_view.dart';

class ImageToolsDialogViewState extends State<ImageToolsDialogView> {
  final _service = ImageProcessingService();
  Uint8List? _source;
  Uint8List? _output;
  String _name = 'image.png';
  int _width = 1200;
  int _rotation = 0;
  int _quality = 88;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    final file = await StudioScope.read(context).files.pickAnyFile(
      extensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
    );
    if (file == null || !mounted) return;
    setState(() { _source = file.bytes; _output = file.bytes; _name = file.name; _error = null; });
  }

  void _transform(Uint8List Function(List<int>) action) {
    final source = _source;
    if (source == null) return;
    try {
      setState(() { _output = action(source); _error = null; });
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _save({String format = 'png'}) async {
    final bytes = _output;
    if (bytes == null) return;
    setState(() => _busy = true);
    try {
      final nameWithoutExtension = _name.contains('.') ? _name.substring(0, _name.lastIndexOf('.')) : _name;
      final output = format == 'jpg' ? _service.encode(bytes, format: 'jpg', quality: _quality) : _service.encode(bytes, format: 'png');
      await StudioScope.read(context).files.saveBytes('$nameWithoutExtension.$format', output, mimeType: format == 'jpg' ? 'image/jpeg' : 'image/png');
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: SizedBox(
          width: 900,
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(children: [
            ListTile(title: Text('image.title'.tr()), subtitle: Text('image.subtitle'.tr()), trailing: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))),
            const Divider(height: 1),
            Expanded(child: Row(children: [
              SizedBox(width: 280, child: ListView(padding: const EdgeInsets.all(18), children: [
                FilledButton.icon(onPressed: _busy ? null : _pick, icon: const Icon(Icons.image_search), label: Text('image.open'.tr())),
                const SizedBox(height: 18),
                Text('image.resize_width'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
                Slider(value: _width.toDouble(), min: 200, max: 3000, divisions: 28, label: '$_width px', onChanged: _source == null ? null : (value) => setState(() => _width = value.round())),
                OutlinedButton.icon(onPressed: _source == null ? null : () => _transform((bytes) => _service.resize(bytes, width: _width)), icon: const Icon(Icons.photo_size_select_large), label: Text('image.apply_resize'.tr())),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: _source == null ? null : () => _transform(_service.centerCropSquare), icon: const Icon(Icons.crop_square), label: Text('image.square_crop'.tr())),
                OutlinedButton.icon(onPressed: _source == null ? null : () => _transform(_service.flipHorizontal), icon: const Icon(Icons.flip), label: Text('image.flip_horizontal'.tr())),
                const SizedBox(height: 14),
                Text('image.rotate'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
                Wrap(spacing: 6, children: [
                  for (final degrees in [90, 180, 270])
                    ChoiceChip(label: Text('$degrees°'), selected: _rotation == degrees, onSelected: _source == null ? null : (_) => setState(() => _rotation = degrees)),
                ]),
                OutlinedButton.icon(onPressed: _source == null ? null : () => _transform((bytes) => _service.rotate(bytes, degrees: _rotation)), icon: const Icon(Icons.rotate_right), label: Text('image.apply_rotation'.tr())),
                const SizedBox(height: 14),
                Text('image.jpeg_quality'.tr() + ' · $_quality', style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(value: _quality.toDouble(), min: 30, max: 100, divisions: 14, onChanged: (value) => setState(() => _quality = value.round())),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
              ])),
              const VerticalDivider(width: 1),
              Expanded(child: Container(color: const Color(0xFFF2F4F7), alignment: Alignment.center, padding: const EdgeInsets.all(18), child: _output == null ? Text('image.open_to_begin'.tr()) : InteractiveViewer(child: Image.memory(_output!, fit: BoxFit.contain)))),
            ])),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('image.cancel'.tr())),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _output == null || _busy ? null : () => _save(format: 'jpg'), child: Text('image.export_jpeg'.tr())),
              const SizedBox(width: 8),
              FilledButton(onPressed: _output == null || _busy ? null : () => _save(format: 'png'), child: Text('image.export_png'.tr())),
            ])),
          ]),
        ),
      );
}
