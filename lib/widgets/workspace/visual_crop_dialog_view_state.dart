import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image/image.dart' as img;

import '../../core/state/studio_scope.dart';
import '../../services/pdf/editing/pdf_page_box_service.dart';
import '../../services/pdf/reading/pdf_render_service.dart';
import '../../services/pdf/reading/pdf_analysis_service.dart';
import 'crop_shade_painter.dart';
import 'visual_crop_dialog_view.dart';

class VisualCropDialogViewState extends State<VisualCropDialogView> {
  final _render = PdfRenderService();

  double _top = 0;
  double _right = 0;
  double _bottom = 0;
  double _left = 0;
  double _pageWidth = 612;
  double _pageHeight = 792;

  final _topController = TextEditingController(text: '0');
  final _rightController = TextEditingController(text: '0');
  final _bottomController = TextEditingController(text: '0');
  final _leftController = TextEditingController(text: '0');

  Future<Uint8List>? _preview;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final bytes = StudioScope.read(context).activeDocumentBytes;

    if (bytes != null) {
      _preview = _render.renderPage(bytes, 0);
      _loadPageDimensions(bytes);
    }
  }

  @override
  void dispose() {
    _topController.dispose();
    _rightController.dispose();
    _bottomController.dispose();
    _leftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 980,
      height: MediaQuery.sizeOf(context).height * .82,
      child: Column(
        children: [
          ListTile(
            title: Text('crop.title'.tr()),
            subtitle: Text('crop.subtitle'.tr()),
            trailing: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F2F5),
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: FutureBuilder<Uint8List>(
                      future: _preview,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return snapshot.hasError
                              ? const Text('Could not render the first page.')
                              : const CircularProgressIndicator();
                        }

                        final imageBytes = snapshot.data!;

                        // Decode the rendered bytes to obtain dimensions.
                        final decodedImage = img.decodeImage(imageBytes);

                        if (decodedImage == null) {
                          return const Text(
                            'Could not decode the page preview.',
                          );
                        }

                        final cropLeft = (_left / _pageWidth).clamp(0.0, 0.45).toDouble();

                        final cropRight = (_right / _pageWidth).clamp(0.0, 0.45).toDouble();

                        final cropTop = (_top / _pageHeight).clamp(0.0, 0.45).toDouble();

                        final cropBottom = (_bottom / _pageHeight).clamp(0.0, 0.45).toDouble();

                        return Center(
                          child: AspectRatio(
                            aspectRatio:
                                decodedImage.width / decodedImage.height,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final height = constraints.maxHeight;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(imageBytes, fit: BoxFit.contain),
                                    CustomPaint(
                                      painter: CropShadePainter(
                                        left: cropLeft,
                                        right: cropRight,
                                        top: cropTop,
                                        bottom: cropBottom,
                                      ),
                                    ),
                                    _cropHandle(
                                      left: cropLeft * width,
                                      top: cropTop * height,
                                      onMove: (delta) => _updateCrop(
                                        left: _left + delta.dx * _pageWidth / width,
                                        top: _top + delta.dy * _pageHeight / height,
                                      ),
                                    ),
                                    _cropHandle(
                                      left: (1 - cropRight) * width,
                                      top: cropTop * height,
                                      onMove: (delta) => _updateCrop(
                                        right: _right - delta.dx * _pageWidth / width,
                                        top: _top + delta.dy * _pageHeight / height,
                                      ),
                                    ),
                                    _cropHandle(
                                      left: cropLeft * width,
                                      top: (1 - cropBottom) * height,
                                      onMove: (delta) => _updateCrop(
                                        left: _left + delta.dx * _pageWidth / width,
                                        bottom: _bottom - delta.dy * _pageHeight / height,
                                      ),
                                    ),
                                    _cropHandle(
                                      left: (1 - cropRight) * width,
                                      top: (1 - cropBottom) * height,
                                      onMove: (delta) => _updateCrop(
                                        right: _right - delta.dx * _pageWidth / width,
                                        bottom: _bottom - delta.dy * _pageHeight / height,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 290,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _marginSlider(
                        'crop.top'.tr(),
                        _top,
                        _topController,
                        (value) => setState(() => _top = value),
                      ),
                      _marginSlider(
                        'crop.right'.tr(),
                        _right,
                        _rightController,
                        (value) => setState(() => _right = value),
                      ),
                      _marginSlider(
                        'crop.bottom'.tr(),
                        _bottom,
                        _bottomController,
                        (value) => setState(() => _bottom = value),
                      ),
                      _marginSlider(
                        'crop.left'.tr(),
                        _left,
                        _leftController,
                        (value) => setState(() => _left = value),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'crop.measurements'.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('crop.cancel'.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _apply,
                  icon: const Icon(Icons.crop),
                  label: Text(_busy ? 'crop.applying'.tr() : 'crop.apply'.tr()),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _loadPageDimensions(List<int> bytes) async {
    try {
      final pages = await PdfAnalysisService().pageInfo(bytes);
      if (pages is List && pages.isNotEmpty && mounted) {
        final first = pages.first;
        setState(() {
          _pageWidth = (first.width as num).toDouble();
          _pageHeight = (first.height as num).toDouble();
        });
      }
    } catch (_) {
      // Keep the standard Letter-size fallback when page metadata is unavailable.
    }
  }

  Widget _cropHandle({
    required double left,
    required double top,
    required ValueChanged<Offset> onMove,
  }) {
    return Positioned(
      left: left - 10,
      top: top - 10,
      child: GestureDetector(
        onPanUpdate: (details) => onMove(details.delta),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCrop({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) {
    setState(() {
      if (top != null) {
        _top = top.clamp(0.0, _pageHeight * 0.45).toDouble();
        _topController.text = _top.round().toString();
      }
      if (right != null) {
        _right = right.clamp(0.0, _pageWidth * 0.45).toDouble();
        _rightController.text = _right.round().toString();
      }
      if (bottom != null) {
        _bottom = bottom.clamp(0.0, _pageHeight * 0.45).toDouble();
        _bottomController.text = _bottom.round().toString();
      }
      if (left != null) {
        _left = left.clamp(0.0, _pageWidth * 0.45).toDouble();
        _leftController.text = _left.round().toString();
      }
    });
  }

  Widget _marginSlider(
    String label,
    double value,
    TextEditingController controller,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(
              width: 82,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  suffixText: 'pt',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (text) {
                  final parsed = double.tryParse(text);
                  if (parsed != null && parsed >= 0 && parsed <= 180) {
                    onChanged(parsed);
                  }
                },
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0.0, 180.0).toDouble(),
          min: 0,
          max: 180,
          divisions: 36,
          onChanged: (nextValue) {
            onChanged(nextValue);
            controller.text = nextValue.round().toString();
          },
        ),
      ],
    );
  }

  Future<void> _apply() async {
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes;

    if (bytes == null) return;

    final entered = [
      double.tryParse(_topController.text),
      double.tryParse(_rightController.text),
      double.tryParse(_bottomController.text),
      double.tryParse(_leftController.text),
    ];
    if (entered.any((value) => value == null || !value.isFinite || value < 0 || value > 180) ||
        entered[0]! + entered[2]! >= _pageHeight * 0.9 ||
        entered[1]! + entered[3]! >= _pageWidth * 0.9) {
      setState(() {
        _error = 'Enter margins between 0 and 180 points.';
      });
      return;
    }
    _top = entered[0]!;
    _right = entered[1]!;
    _bottom = entered[2]!;
    _left = entered[3]!;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final output = await PdfPageBoxService().cropMargins(
        bytes,
        top: _top,
        right: _right,
        bottom: _bottom,
        left: _left,
      );

      await controller.setWorkingCopy(output);

      if (mounted) {
        Navigator.pop(context, <double>[_top, _right, _bottom, _left]);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = controller.friendlyError(error, action: 'crop the document');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
