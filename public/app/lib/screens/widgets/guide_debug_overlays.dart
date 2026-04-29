part of 'package:exbf_camera/screens/camera_screen.dart';

class _RuleGrid extends StatelessWidget {
  const _RuleGrid();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _RuleGridPainter());
}

class _RuleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VisionDebugOverlay extends StatelessWidget {
  const _VisionDebugOverlay({required this.result});

  final VisionFrameResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    if (result == null) return const SizedBox.shrink();
    return CustomPaint(painter: _VisionDebugPainter(result));
  }
}

class _VisionDebugPainter extends CustomPainter {
  const _VisionDebugPainter(this.result);

  final VisionFrameResult result;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = _accentPink.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final labelPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.54)
      ..style = PaintingStyle.fill;
    final posePaint = Paint()
      ..color = const Color(0xff19c37d).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final facePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    final objectsToDraw = [
      ...result.objects.where((object) => object.label == 'person'),
      ...result.objects.where((object) => object.label != 'person'),
    ].take(6);

    for (final object in objectsToDraw) {
      final rect = Rect.fromLTWH(
        object.x * size.width,
        object.y * size.height,
        object.width * size.width,
        object.height * size.height,
      );
      canvas.drawRect(rect, boxPaint);
      final label = '${object.label} ${(object.confidence * 100).round()}%';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      final labelRect = Rect.fromLTWH(
        rect.left,
        (rect.top - 20).clamp(0, size.height - 18).toDouble(),
        textPainter.width + 8,
        18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
        labelPaint,
      );
      textPainter.paint(canvas, labelRect.topLeft + const Offset(4, 2));
    }

    for (final face in result.faces.take(4)) {
      final rect = Rect.fromLTWH(
        face.x * size.width,
        face.y * size.height,
        face.width * size.width,
        face.height * size.height,
      );
      canvas.drawOval(rect, facePaint);
      for (final point in [
        face.leftEye,
        face.rightEye,
        face.nose,
      ].whereType<Offset>()) {
        canvas.drawCircle(
          Offset(point.dx * size.width, point.dy * size.height),
          3.6,
          Paint()..color = _accentPink,
        );
      }
    }

    for (final point in result.pose.where((point) => point.confidence > 0.18)) {
      final center = Offset(point.x * size.width, point.y * size.height);
      canvas.drawCircle(center, 5.5, Paint()..color = Colors.black45);
      canvas.drawCircle(center, 3.4, posePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisionDebugPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
