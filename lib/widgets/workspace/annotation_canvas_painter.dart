import 'package:flutter/material.dart';

class AnnotationCanvasPainter extends CustomPainter {
  const AnnotationCanvasPainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF192337)..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) canvas.drawCircle(stroke.first, 1.5, paint);
      for (var index = 1; index < stroke.length; index++) {
        canvas.drawLine(stroke[index - 1], stroke[index], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationCanvasPainter oldDelegate) => true;
}
