// ignore_for_file: unused_element

part of 'package:exbf_camera/screens/camera_screen.dart';

class _FilteredCameraPreview extends StatelessWidget {
  const _FilteredCameraPreview({
    required this.textureId,
    required this.style,
    required this.set,
    required this.retouch,
  });

  final int textureId;
  final StyleEffect style;
  final SetEffect set;
  final RetouchEffect retouch;

  @override
  Widget build(BuildContext context) {
    final preview = _NativeCameraPreviewSurface(textureId: textureId);
    final matrix = _PreviewColorMatrix.resolve(
      style: style,
      set: set,
      retouch: retouch,
    );
    if (matrix == null) return preview;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: preview,
    );
  }
}

class _PreviewColorMatrix {
  const _PreviewColorMatrix._();

  static const List<double> _vivid = [
    1.18,
    -0.07,
    -0.04,
    0,
    8,
    -0.04,
    1.14,
    -0.03,
    0,
    6,
    -0.03,
    -0.04,
    1.12,
    0,
    4,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _warm = [
    1.10,
    0.03,
    0,
    0,
    7,
    0,
    1.04,
    0,
    0,
    2,
    0,
    0,
    0.92,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _cool = [
    0.94,
    0,
    0,
    0,
    0,
    0,
    1.04,
    0,
    0,
    2,
    0,
    0.02,
    1.12,
    0,
    8,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _film = [
    0.86,
    0.12,
    0.02,
    0,
    8,
    0.06,
    0.94,
    0.04,
    0,
    4,
    0.02,
    0.08,
    0.78,
    0,
    2,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _mono = [
    0.314,
    0.616,
    0.119,
    0,
    0,
    0.314,
    0.616,
    0.119,
    0,
    0,
    0.314,
    0.616,
    0.119,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _night = [
    0.86,
    0,
    0.05,
    0,
    -2,
    0,
    0.90,
    0.03,
    0,
    -2,
    0.02,
    0.06,
    1.14,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _bright = [
    1.08,
    0,
    0,
    0,
    14,
    0,
    1.08,
    0,
    0,
    14,
    0,
    0,
    1.08,
    0,
    14,
    0,
    0,
    0,
    1,
    0,
  ];

  static List<double>? resolve({
    required StyleEffect style,
    required SetEffect set,
    required RetouchEffect retouch,
  }) {
    final styleMatrix = switch (style) {
      StyleEffect.vivid => _vivid,
      StyleEffect.warm => _warm,
      StyleEffect.cool => _cool,
      StyleEffect.film => _film,
      StyleEffect.mono => _mono,
      StyleEffect.none => null,
    };
    if (styleMatrix != null) return styleMatrix;

    final setMatrix = switch (set) {
      SetEffect.cafe => _warm,
      SetEffect.travel => _cool,
      SetEffect.food => _vivid,
      SetEffect.night => _night,
      SetEffect.solo || SetEffect.none => null,
    };
    if (setMatrix != null) return setMatrix;

    return switch (retouch) {
      RetouchEffect.bright || RetouchEffect.skin => _bright,
      RetouchEffect.none ||
      RetouchEffect.jaw ||
      RetouchEffect.eyes ||
      RetouchEffect.nose => null,
    };
  }
}

class _EffectPreviewOverlay extends StatelessWidget {
  const _EffectPreviewOverlay({
    required this.style,
    required this.set,
    required this.retouch,
  });

  final StyleEffect style;
  final SetEffect set;
  final RetouchEffect retouch;

  @override
  Widget build(BuildContext context) {
    final overlays = <Widget>[];
    final tint = _tintColor;
    if (tint != null) {
      overlays.add(ColoredBox(color: tint));
    }
    if (set == SetEffect.solo ||
        set == SetEffect.cafe ||
        set == SetEffect.food ||
        set == SetEffect.night) {
      overlays.add(const _VignetteOverlay());
    }
    if (retouch == RetouchEffect.bright) {
      overlays.add(ColoredBox(color: Colors.white.withValues(alpha: 0.08)));
    }
    if (overlays.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(child: Stack(children: overlays)),
    );
  }

  Color? get _tintColor {
    if (style == StyleEffect.warm || set == SetEffect.cafe) {
      return const Color(0xffff8f40).withValues(alpha: 0.10);
    }
    if (style == StyleEffect.vivid || set == SetEffect.food) {
      return const Color(0xffff4d30).withValues(alpha: 0.06);
    }
    if (style == StyleEffect.cool) {
      return const Color(0xff00bcd4).withValues(alpha: 0.08);
    }
    if (style == StyleEffect.film) {
      return const Color(0xff193d2f).withValues(alpha: 0.12);
    }
    if (style == StyleEffect.mono) {
      return Colors.white.withValues(alpha: 0.06);
    }
    if (set == SetEffect.travel) {
      return const Color(0xff1e88e5).withValues(alpha: 0.06);
    }
    if (set == SetEffect.night) {
      return const Color(0xff24135f).withValues(alpha: 0.14);
    }
    if (retouch == RetouchEffect.skin) {
      return const Color(0xffffb3d7).withValues(alpha: 0.07);
    }
    return null;
  }
}

class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.78,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.18)],
          stops: const [0.62, 1],
        ),
      ),
    );
  }
}

class _StickerOverlay extends StatefulWidget {
  const _StickerOverlay({
    required this.sticker,
    required this.visionResult,
    required this.estimate,
  });

  final StickerEffect sticker;
  final VisionFrameResult? visionResult;
  final SubjectEstimate estimate;

  @override
  State<_StickerOverlay> createState() => _StickerOverlayState();
}

class _StickerOverlayState extends State<_StickerOverlay> {
  _FaceStickerAnchor? _stableAnchor;

  @override
  void didUpdateWidget(covariant _StickerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sticker != widget.sticker) {
      _stableAnchor = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final nextAnchor = _FaceStickerAnchor.from(
              widget.visionResult,
              widget.estimate,
              size,
            );
            final anchor = _stabilize(nextAnchor);
            return CustomPaint(
              painter: _StickerOverlayPainter(
                sticker: widget.sticker,
                anchor: anchor,
              ),
            );
          },
        ),
      ),
    );
  }

  _FaceStickerAnchor _stabilize(_FaceStickerAnchor next) {
    final previous = _stableAnchor;
    if (previous == null) {
      _stableAnchor = next;
      return next;
    }

    if (!next.tracked) {
      return previous;
    }

    const follow = 0.30;
    final smoothed = previous.lerp(next, follow);
    _stableAnchor = smoothed;
    return smoothed;
  }
}

class _StickerSamplePainter extends CustomPainter {
  const _StickerSamplePainter(this.sticker);

  final StickerEffect sticker;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceWidth = size.width * 0.52;
    switch (sticker) {
      case StickerEffect.bunnyEars:
        _StickerArt.drawBunnyEars(canvas, center, faceWidth);
      case StickerEffect.sunglasses:
        _StickerArt.drawSunglasses(canvas, center, faceWidth);
      case StickerEffect.pigNose:
        _StickerArt.drawPigNose(canvas, center, faceWidth);
      case StickerEffect.none:
        _StickerArt.drawNone(canvas, center, faceWidth);
    }
  }

  @override
  bool shouldRepaint(covariant _StickerSamplePainter oldDelegate) {
    return oldDelegate.sticker != sticker;
  }
}

class _StickerOverlayPainter extends CustomPainter {
  const _StickerOverlayPainter({required this.sticker, required this.anchor});

  final StickerEffect sticker;
  final _FaceStickerAnchor anchor;

  @override
  void paint(Canvas canvas, Size size) {
    if (sticker == StickerEffect.none) return;
    switch (sticker) {
      case StickerEffect.bunnyEars:
        _StickerArt.drawBunnyEars(
          canvas,
          anchor.eyeCenter.translate(0, -anchor.faceWidth * 0.37),
          anchor.faceWidth * 0.80,
        );
      case StickerEffect.sunglasses:
        _StickerArt.drawSunglasses(
          canvas,
          anchor.eyeCenter,
          anchor.faceWidth * 0.72,
        );
      case StickerEffect.pigNose:
        _StickerArt.drawPigNose(
          canvas,
          anchor.noseCenter,
          anchor.faceWidth * 0.62,
        );
      case StickerEffect.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StickerOverlayPainter oldDelegate) {
    return oldDelegate.sticker != sticker || oldDelegate.anchor != anchor;
  }
}

class _FaceStickerAnchor {
  const _FaceStickerAnchor({
    required this.eyeCenter,
    required this.noseCenter,
    required this.faceWidth,
    required this.tracked,
  });

  final Offset eyeCenter;
  final Offset noseCenter;
  final double faceWidth;
  final bool tracked;

  _FaceStickerAnchor lerp(_FaceStickerAnchor target, double amount) {
    return _FaceStickerAnchor(
      eyeCenter: Offset.lerp(eyeCenter, target.eyeCenter, amount)!,
      noseCenter: Offset.lerp(noseCenter, target.noseCenter, amount)!,
      faceWidth: faceWidth + (target.faceWidth - faceWidth) * amount,
      tracked: target.tracked,
    );
  }

  static _FaceStickerAnchor from(
    VisionFrameResult? result,
    SubjectEstimate estimate,
    Size size,
  ) {
    final face = _bestFace(result);
    if (face != null) {
      final fallbackEyeCenter = Offset(
        estimate.bodyCenterX.clamp(0, 1) * size.width,
        estimate.eyeLineY.clamp(0, 1) * size.height,
      );
      final eyeCenter =
          _averageFaceOffset([face.leftEye, face.rightEye], size) ??
          fallbackEyeCenter;
      final noseCenter =
          _facePointToOffset(face.nose, size) ??
          Offset(
            (face.x + face.width / 2).clamp(0, 1) * size.width,
            (face.y + face.height * 0.53).clamp(0, 1) * size.height,
          );
      final eyeWidth = _faceDistance(face.leftEye, face.rightEye, size);
      final faceWidth = ((eyeWidth ?? face.width * size.width * 0.58) * 2.15)
          .clamp(size.width * 0.24, size.width * 0.72)
          .toDouble();
      return _FaceStickerAnchor(
        eyeCenter: eyeCenter,
        noseCenter: noseCenter,
        faceWidth: faceWidth,
        tracked: true,
      );
    }

    final pose = {
      for (final point in result?.pose ?? <PoseKeypoint>[]) point.name: point,
    };
    final leftEye = _visiblePoint(pose['left_eye']);
    final rightEye = _visiblePoint(pose['right_eye']);
    final nose = _visiblePoint(pose['nose']);
    final leftEar = _visiblePoint(pose['left_ear']);
    final rightEar = _visiblePoint(pose['right_ear']);
    final tracked = leftEye != null || rightEye != null || nose != null;

    final fallbackEyeCenter = Offset(
      estimate.bodyCenterX.clamp(0, 1) * size.width,
      estimate.eyeLineY.clamp(0, 1) * size.height,
    );
    final eyeCenter =
        _averageOffset([leftEye, rightEye], size) ?? fallbackEyeCenter;
    final noseCenter =
        _pointToOffset(nose, size) ??
        eyeCenter.translate(0, size.height * 0.055);

    final earWidth = _distance(leftEar, rightEar, size);
    final eyeWidth = _distance(leftEye, rightEye, size);
    final baseFaceWidth =
        earWidth ??
        (eyeWidth == null ? null : eyeWidth * 2.65) ??
        size.width * 0.32;
    final faceWidth = (baseFaceWidth * 1.45)
        .clamp(size.width * 0.24, size.width * 0.68)
        .toDouble();

    return _FaceStickerAnchor(
      eyeCenter: eyeCenter,
      noseCenter: noseCenter,
      faceWidth: faceWidth,
      tracked: tracked,
    );
  }

  static DetectedFace? _bestFace(VisionFrameResult? result) {
    final faces = result?.faces;
    if (faces == null || faces.isEmpty) return null;
    final sorted = [...faces]
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    return sorted.first;
  }

  static Offset? _facePointToOffset(Offset? point, Size size) {
    if (point == null) return null;
    return Offset(point.dx * size.width, point.dy * size.height);
  }

  static Offset? _averageFaceOffset(List<Offset?> points, Size size) {
    final visible = points.whereType<Offset>().toList();
    if (visible.isEmpty) return null;
    final x =
        visible.map((point) => point.dx).reduce((a, b) => a + b) /
        visible.length;
    final y =
        visible.map((point) => point.dy).reduce((a, b) => a + b) /
        visible.length;
    return Offset(x * size.width, y * size.height);
  }

  static double? _faceDistance(Offset? a, Offset? b, Size size) {
    if (a == null || b == null) return null;
    final dx = (a.dx - b.dx) * size.width;
    final dy = (a.dy - b.dy) * size.height;
    return math.sqrt(dx * dx + dy * dy);
  }

  static PoseKeypoint? _visiblePoint(PoseKeypoint? point) {
    if (point == null || point.confidence < 0.18) return null;
    return point;
  }

  static Offset? _pointToOffset(PoseKeypoint? point, Size size) {
    if (point == null) return null;
    return Offset(point.x * size.width, point.y * size.height);
  }

  static Offset? _averageOffset(List<PoseKeypoint?> points, Size size) {
    final visible = points.whereType<PoseKeypoint>().toList();
    if (visible.isEmpty) return null;
    final x =
        visible.map((point) => point.x).reduce((a, b) => a + b) /
        visible.length;
    final y =
        visible.map((point) => point.y).reduce((a, b) => a + b) /
        visible.length;
    return Offset(x * size.width, y * size.height);
  }

  static double? _distance(PoseKeypoint? a, PoseKeypoint? b, Size size) {
    if (a == null || b == null) return null;
    final dx = (a.x - b.x) * size.width;
    final dy = (a.y - b.y) * size.height;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _StickerArt {
  const _StickerArt._();

  static final Paint _white = Paint()..color = Colors.white;
  static final Paint _pink = Paint()..color = const Color(0xffff8fcf);
  static final Paint _dark = Paint()..color = const Color(0xff16161a);
  static final Paint _shine = Paint()
    ..color = Colors.white.withValues(alpha: 0.48);
  static final Paint _outline = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static void drawBunnyEars(Canvas canvas, Offset center, double faceWidth) {
    final earWidth = faceWidth * 0.24;
    final earHeight = faceWidth * 0.78;
    final left = center.translate(-faceWidth * 0.22, 0);
    final right = center.translate(faceWidth * 0.22, 0);
    _drawEar(canvas, left, earWidth, earHeight, -0.18);
    _drawEar(canvas, right, earWidth, earHeight, 0.18);
  }

  static void _drawEar(
    Canvas canvas,
    Offset base,
    double width,
    double height,
    double angle,
  ) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final outer = Rect.fromCenter(
      center: Offset(0, -height * 0.2),
      width: width,
      height: height,
    );
    final inner = Rect.fromCenter(
      center: Offset(0, -height * 0.15),
      width: width * 0.48,
      height: height * 0.58,
    );
    canvas.drawOval(outer, _white);
    canvas.drawOval(outer, _outline);
    canvas.drawOval(inner, _pink);
    canvas.restore();
  }

  static void drawSunglasses(Canvas canvas, Offset center, double faceWidth) {
    final lensWidth = faceWidth * 0.34;
    final lensHeight = faceWidth * 0.20;
    final gap = faceWidth * 0.07;
    final left = Rect.fromCenter(
      center: center.translate(-(lensWidth + gap) / 2, 0),
      width: lensWidth,
      height: lensHeight,
    );
    final right = Rect.fromCenter(
      center: center.translate((lensWidth + gap) / 2, 0),
      width: lensWidth,
      height: lensHeight,
    );
    final radius = Radius.circular(lensHeight * 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(left, radius), _dark);
    canvas.drawRRect(RRect.fromRectAndRadius(right, radius), _dark);
    canvas.drawLine(
      Offset(left.right, center.dy),
      Offset(right.left, center.dy),
      Paint()
        ..color = const Color(0xff16161a)
        ..strokeWidth = faceWidth * 0.035
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: left.center.translate(-lensWidth * 0.16, -lensHeight * 0.16),
        width: lensWidth * 0.22,
        height: lensHeight * 0.20,
      ),
      _shine,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: right.center.translate(-lensWidth * 0.16, -lensHeight * 0.16),
        width: lensWidth * 0.22,
        height: lensHeight * 0.20,
      ),
      _shine,
    );
  }

  static void drawPigNose(Canvas canvas, Offset center, double faceWidth) {
    final width = faceWidth * 0.32;
    final height = faceWidth * 0.21;
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(rect, _pink);
    canvas.drawOval(rect, _outline);
    final nostrilPaint = Paint()..color = const Color(0xff9b3f74);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-width * 0.17, 0),
        width: width * 0.12,
        height: height * 0.32,
      ),
      nostrilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(width * 0.17, 0),
        width: width * 0.12,
        height: height * 0.32,
      ),
      nostrilPaint,
    );
  }

  static void drawNone(Canvas canvas, Offset center, double faceWidth) {
    final radius = faceWidth * 0.30;
    final paint = Paint()
      ..color = const Color(0xff9a9aa4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      center.translate(-radius * 0.7, radius * 0.7),
      center.translate(radius * 0.7, -radius * 0.7),
      paint,
    );
  }
}

class _RasterStickerArt {
  const _RasterStickerArt._();

  static final img.Color _white = img.ColorRgba8(255, 255, 255, 255);
  static final img.Color _pink = img.ColorRgba8(255, 143, 207, 255);
  static final img.Color _dark = img.ColorRgba8(22, 22, 26, 255);
  static final img.Color _shine = img.ColorRgba8(255, 255, 255, 126);
  static final img.Color _outline = img.ColorRgba8(0, 0, 0, 70);
  static final img.Color _nostril = img.ColorRgba8(155, 63, 116, 255);

  static void drawBunnyEars(img.Image image, Offset center, double faceWidth) {
    final earWidth = faceWidth * 0.25;
    final earHeight = faceWidth * 0.78;
    final left = center.translate(-faceWidth * 0.22, 0);
    final right = center.translate(faceWidth * 0.22, 0);
    _fillEllipse(
      image,
      left.translate(0, -earHeight * 0.2),
      earWidth,
      earHeight,
      _white,
    );
    _drawEllipse(
      image,
      left.translate(0, -earHeight * 0.2),
      earWidth,
      earHeight,
      _outline,
      thickness: 5,
    );
    _fillEllipse(
      image,
      left.translate(0, -earHeight * 0.15),
      earWidth * 0.48,
      earHeight * 0.58,
      _pink,
    );
    _fillEllipse(
      image,
      right.translate(0, -earHeight * 0.2),
      earWidth,
      earHeight,
      _white,
    );
    _drawEllipse(
      image,
      right.translate(0, -earHeight * 0.2),
      earWidth,
      earHeight,
      _outline,
      thickness: 5,
    );
    _fillEllipse(
      image,
      right.translate(0, -earHeight * 0.15),
      earWidth * 0.48,
      earHeight * 0.58,
      _pink,
    );
  }

  static void drawSunglasses(img.Image image, Offset center, double faceWidth) {
    final lensWidth = faceWidth * 0.34;
    final lensHeight = faceWidth * 0.20;
    final gap = faceWidth * 0.07;
    final left = center.translate(-(lensWidth + gap) / 2, 0);
    final right = center.translate((lensWidth + gap) / 2, 0);
    _fillEllipse(image, left, lensWidth, lensHeight, _dark);
    _fillEllipse(image, right, lensWidth, lensHeight, _dark);
    img.drawLine(
      image,
      x1: (left.dx + lensWidth / 2).round(),
      y1: center.dy.round(),
      x2: (right.dx - lensWidth / 2).round(),
      y2: center.dy.round(),
      color: _dark,
      thickness: math.max(4, faceWidth * 0.035),
    );
    _fillEllipse(
      image,
      left.translate(-lensWidth * 0.16, -lensHeight * 0.16),
      lensWidth * 0.22,
      lensHeight * 0.20,
      _shine,
    );
    _fillEllipse(
      image,
      right.translate(-lensWidth * 0.16, -lensHeight * 0.16),
      lensWidth * 0.22,
      lensHeight * 0.20,
      _shine,
    );
  }

  static void drawPigNose(img.Image image, Offset center, double faceWidth) {
    final width = faceWidth * 0.32;
    final height = faceWidth * 0.21;
    _fillEllipse(image, center, width, height, _pink);
    _drawEllipse(image, center, width, height, _outline, thickness: 5);
    _fillEllipse(
      image,
      center.translate(-width * 0.17, 0),
      width * 0.12,
      height * 0.32,
      _nostril,
    );
    _fillEllipse(
      image,
      center.translate(width * 0.17, 0),
      width * 0.12,
      height * 0.32,
      _nostril,
    );
  }

  static void _fillEllipse(
    img.Image image,
    Offset center,
    double width,
    double height,
    img.Color color,
  ) {
    final rx = math.max(1, width / 2);
    final ry = math.max(1, height / 2);
    final left = math.max(0, (center.dx - rx).floor());
    final right = math.min(image.width - 1, (center.dx + rx).ceil());
    final top = math.max(0, (center.dy - ry).floor());
    final bottom = math.min(image.height - 1, (center.dy + ry).ceil());
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        final dx = (x - center.dx) / rx;
        final dy = (y - center.dy) / ry;
        if (dx * dx + dy * dy <= 1) {
          image.setPixel(x, y, color);
        }
      }
    }
  }

  static void _drawEllipse(
    img.Image image,
    Offset center,
    double width,
    double height,
    img.Color color, {
    required int thickness,
  }) {
    final rx = math.max(1, width / 2);
    final ry = math.max(1, height / 2);
    final steps = math.max(80, (math.pi * (rx + ry)).round());
    for (var i = 0; i <= steps; i++) {
      final angle = math.pi * 2 * i / steps;
      final x = center.dx + math.cos(angle) * rx;
      final y = center.dy + math.sin(angle) * ry;
      img.fillCircle(
        image,
        x: x.round(),
        y: y.round(),
        radius: thickness,
        color: color,
      );
    }
  }
}

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
