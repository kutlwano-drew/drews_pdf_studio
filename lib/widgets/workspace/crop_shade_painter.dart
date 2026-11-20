import 'package:flutter/material.dart';

class CropShadePainter extends CustomPainter {
  const CropShadePainter({required this.left, required this.right, required this.top, required this.bottom});

  final double left;
  final double right;
  final double top;
  final double bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final crop = Rect.fromLTRB(size.width * left, size.height * top, size.width * (1 - right), size.height * (1 - bottom));
    final shadePath = Path()..fillType = PathFillType.evenOdd..addRect(Offset.zero & size)..addRect(crop);
    final shade = Paint()..color = Colors.black.withOpacity(.42);
    canvas.drawPath(shadePath, shade);
    final border = Paint()..color = const Color(0xFFE84B3C)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(crop, border);
  }

  @override
  bool shouldRepaint(covariant CropShadePainter oldDelegate) => left != oldDelegate.left || right != oldDelegate.right || top != oldDelegate.top || bottom != oldDelegate.bottom;
}
