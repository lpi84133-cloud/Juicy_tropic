// ignore_for_file: avoid_print
import 'dart:io';

import 'package:image/image.dart' as img;

/// Builds launcher layers from icon2.jpg.
/// Adaptive canvas is 108dp; artwork sits in the centre 72dp safe box
/// so the launcher mask does not clip the crown / fruit.
void main() {
  const String srcPath = r'C:\Users\vitya\Downloads\icon2.jpg';
  const int canvas = 1024;
  const double safeRatio = 72 / 108;
  final int artSize = (canvas * safeRatio).round();

  final File src = File(srcPath);
  if (!src.existsSync()) {
    stderr.writeln('Missing source: $srcPath');
    exit(1);
  }

  final img.Image? decoded = img.decodeImage(src.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode $srcPath');
    exit(1);
  }

  final img.Image square = _square(decoded, canvas);
  final img.Image backdrop = img.Image.from(square);
  final img.Image plate = img.Image(width: canvas, height: canvas);

  final img.Pixel sample = square.getPixel(8, 8);
  img.fill(
    plate,
    color: img.ColorRgba8(
      sample.r.toInt(),
      sample.g.toInt(),
      sample.b.toInt(),
      0,
    ),
  );

  final img.Image inset = img.copyResize(
    square,
    width: artSize,
    height: artSize,
    interpolation: img.Interpolation.cubic,
  );
  final int origin = ((canvas - artSize) / 2).round();
  img.compositeImage(plate, inset, dstX: origin, dstY: origin);

  final Directory out = Directory('assets/generated')..createSync(recursive: true);
  File('${out.path}/app_icon.png').writeAsBytesSync(img.encodePng(square));
  File('${out.path}/app_icon_background.png')
      .writeAsBytesSync(img.encodePng(backdrop));
  File('${out.path}/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(plate));

  print('Wrote adaptive layers ($artSize px art on $canvas px / 72dp of 108dp)');
}

img.Image _square(img.Image src, int size) {
  final int side = src.width < src.height ? src.width : src.height;
  final int x = ((src.width - side) / 2).round();
  final int y = ((src.height - side) / 2).round();
  final img.Image cropped = img.copyCrop(src, x: x, y: y, width: side, height: side);
  return img.copyResize(
    cropped,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
}
