import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageProcessingService {
  img.Image decode(List<int> bytes) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));

    if (decoded == null) {
      throw const FormatException(
        'The selected file is not a supported image.',
      );
    }

    return decoded;
  }

  Uint8List resize(List<int> bytes, {required int width}) {
    final source = decode(bytes);

    final output = img.copyResize(source, width: width);

    return Uint8List.fromList(img.encodePng(output));
  }

  Uint8List rotate(List<int> bytes, {required int degrees}) {
    final source = decode(bytes);

    final output = img.copyRotate(source, angle: degrees);

    return Uint8List.fromList(img.encodePng(output));
  }

  Uint8List crop(
    List<int> bytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final source = decode(bytes);

    final left = x.clamp(0, source.width - 1).toInt();
    final top = y.clamp(0, source.height - 1).toInt();

    final cropWidth = width.clamp(1, source.width - left).toInt();

    final cropHeight = height.clamp(1, source.height - top).toInt();

    final output = img.copyCrop(
      source,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );

    return Uint8List.fromList(img.encodePng(output));
  }

  Uint8List centerCropSquare(List<int> bytes) {
    final source = decode(bytes);

    final side = source.width < source.height ? source.width : source.height;

    final x = (source.width - side) ~/ 2;
    final y = (source.height - side) ~/ 2;

    final output = img.copyCrop(source, x: x, y: y, width: side, height: side);

    return Uint8List.fromList(img.encodePng(output));
  }

  Uint8List flipHorizontal(List<int> bytes) {
    final output = img.flipHorizontal(decode(bytes));

    return Uint8List.fromList(img.encodePng(output));
  }

  Uint8List encode(
    List<int> bytes, {
    required String format,
    int quality = 88,
  }) {
    final source = decode(bytes);

    final encoded =
        format.toLowerCase() == 'jpg' || format.toLowerCase() == 'jpeg'
        ? img.encodeJpg(source, quality: quality)
        : img.encodePng(source);

    return Uint8List.fromList(encoded);
  }
}
