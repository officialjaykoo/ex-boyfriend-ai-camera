part of 'package:exbf_camera/screens/camera_screen.dart';

class _PhotoEffectProcessor {
  const _PhotoEffectProcessor._();

  static void apply(
    img.Image image, {
    required StyleEffect style,
    required SetEffect set,
    required RetouchEffect retouch,
    _FaceStickerAnchor? anchor,
  }) {
    if (style == StyleEffect.none &&
        set == SetEffect.none &&
        retouch == RetouchEffect.none) {
      return;
    }

    final centerX = image.width / 2;
    final centerY = image.height / 2;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        var r = pixel.r.toDouble();
        var g = pixel.g.toDouble();
        var b = pixel.b.toDouble();

        switch (style) {
          case StyleEffect.vivid:
            final luma = _luma(r, g, b);
            r = _mix(luma, r, 1.24) * 1.04 + 5;
            g = _mix(luma, g, 1.20) * 1.05 + 4;
            b = _mix(luma, b, 1.18) * 1.03 + 3;
          case StyleEffect.warm:
            r = r * 1.10 + 7;
            g = g * 1.04 + 2;
            b = b * 0.92;
          case StyleEffect.cool:
            r = r * 0.94;
            g = g * 1.04 + 2;
            b = b * 1.12 + 8;
          case StyleEffect.film:
            final luma = _luma(r, g, b);
            r = _mix(luma, r, 0.78) * 0.96 + 8;
            g = _mix(luma, g, 0.82) * 1.02 + 4;
            b = _mix(luma, b, 0.72) * 0.91 + 2;
          case StyleEffect.mono:
            final luma = _luma(r, g, b);
            r = luma * 1.05;
            g = luma * 1.05;
            b = luma * 1.05;
          case StyleEffect.none:
            break;
        }

        switch (set) {
          case SetEffect.solo:
            final d = _distanceFactor(x, y, centerX, centerY, maxDistance);
            final vignette = 1 - d * 0.22;
            r *= vignette;
            g *= vignette;
            b *= vignette;
          case SetEffect.cafe:
            r = r * 1.08 + 5;
            g = g * 1.02 + 3;
            b = b * 0.88;
            final d = _distanceFactor(x, y, centerX, centerY, maxDistance);
            final vignette = 1 - d * 0.16;
            r *= vignette;
            g *= vignette;
            b *= vignette;
          case SetEffect.travel:
            r = r * 1.04 + 3;
            g = g * 1.06 + 4;
            b = b * 1.10 + 6;
          case SetEffect.food:
            r = r * 1.11 + 8;
            g = g * 1.06 + 5;
            b = b * 0.88;
            final luma = _luma(r, g, b);
            r = _mix(luma, r, 1.12);
            g = _mix(luma, g, 1.08);
            b = _mix(luma, b, 1.02);
          case SetEffect.night:
            r = r * 0.90;
            g = g * 0.94;
            b = b * 1.10 + 8;
            final d = _distanceFactor(x, y, centerX, centerY, maxDistance);
            final vignette = 1 - d * 0.28;
            r *= vignette;
            g *= vignette;
            b *= vignette;
          case SetEffect.none:
            break;
        }

        switch (retouch) {
          case RetouchEffect.skin:
            final luma = _luma(r, g, b);
            r = _mix(r, luma + 18, 0.10);
            g = _mix(g, luma + 12, 0.08);
            b = _mix(b, luma + 16, 0.08);
          case RetouchEffect.bright:
            r = r * 1.08 + 14;
            g = g * 1.08 + 14;
            b = b * 1.08 + 14;
          case RetouchEffect.jaw:
            final amount = _faceZone(
              anchor,
              x,
              y,
              verticalOffset: 0.24,
              width: 0.46,
              height: 0.42,
            );
            final side =
                ((x - (anchor?.eyeCenter.dx ?? centerX)).abs() /
                        math.max(
                          1,
                          (anchor?.faceWidth ?? image.width * 0.35) * 0.38,
                        ))
                    .clamp(0, 1)
                    .toDouble();
            final shade = amount * side * 0.20;
            r *= 1 - shade;
            g *= 1 - shade;
            b *= 1 - shade;
          case RetouchEffect.eyes:
            final amount = _eyeZone(anchor, x, y);
            r = _mix(r, 255, amount * 0.10);
            g = _mix(g, 255, amount * 0.10);
            b = _mix(b, 255, amount * 0.14);
          case RetouchEffect.nose:
            final amount = _noseZone(anchor, x, y);
            r = _mix(r, 255, amount * 0.12);
            g = _mix(g, 245, amount * 0.10);
            b = _mix(b, 235, amount * 0.08);
          case RetouchEffect.none:
            break;
        }

        image.setPixelRgb(
          x,
          y,
          r.clamp(0, 255).round(),
          g.clamp(0, 255).round(),
          b.clamp(0, 255).round(),
        );
      }
    }
  }

  static double _faceZone(
    _FaceStickerAnchor? anchor,
    int x,
    int y, {
    required double verticalOffset,
    required double width,
    required double height,
  }) {
    if (anchor == null || !anchor.tracked) return 0;
    final center = anchor.eyeCenter.translate(
      0,
      anchor.faceWidth * verticalOffset,
    );
    final rx = math.max(1, anchor.faceWidth * width);
    final ry = math.max(1, anchor.faceWidth * height);
    final dx = (x - center.dx) / rx;
    final dy = (y - center.dy) / ry;
    return (1 - (dx * dx + dy * dy)).clamp(0, 1).toDouble();
  }

  static double _eyeZone(_FaceStickerAnchor? anchor, int x, int y) {
    if (anchor == null || !anchor.tracked) return 0;
    final left = anchor.eyeCenter.translate(-anchor.faceWidth * 0.16, 0);
    final right = anchor.eyeCenter.translate(anchor.faceWidth * 0.16, 0);
    return math.max(
      _ellipseZone(
        left,
        anchor.faceWidth * 0.18,
        anchor.faceWidth * 0.10,
        x,
        y,
      ),
      _ellipseZone(
        right,
        anchor.faceWidth * 0.18,
        anchor.faceWidth * 0.10,
        x,
        y,
      ),
    );
  }

  static double _noseZone(_FaceStickerAnchor? anchor, int x, int y) {
    if (anchor == null || !anchor.tracked) return 0;
    return _ellipseZone(
      anchor.noseCenter.translate(0, -anchor.faceWidth * 0.08),
      anchor.faceWidth * 0.11,
      anchor.faceWidth * 0.28,
      x,
      y,
    );
  }

  static double _ellipseZone(
    Offset center,
    double rx,
    double ry,
    int x,
    int y,
  ) {
    final dx = (x - center.dx) / math.max(1, rx);
    final dy = (y - center.dy) / math.max(1, ry);
    return (1 - (dx * dx + dy * dy)).clamp(0, 1).toDouble();
  }

  static double _luma(double r, double g, double b) {
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }

  static double _mix(double a, double b, double amount) {
    return a + (b - a) * amount;
  }

  static double _distanceFactor(
    int x,
    int y,
    double centerX,
    double centerY,
    double maxDistance,
  ) {
    final dx = x - centerX;
    final dy = y - centerY;
    return (math.sqrt(dx * dx + dy * dy) / maxDistance).clamp(0, 1).toDouble();
  }
}
