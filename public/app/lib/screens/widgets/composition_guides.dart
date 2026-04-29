part of 'package:exbf_camera/screens/camera_screen.dart';

class _CompositionGuideOverlay extends StatelessWidget {
  const _CompositionGuideOverlay({
    required this.mode,
    required this.rules,
    required this.estimate,
    required this.visionResult,
    required this.ready,
  });

  final ShotMode mode;
  final CompositionRuleSet rules;
  final SubjectEstimate estimate;
  final VisionFrameResult? visionResult;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CompositionGuidePainter(
        mode: mode,
        rules: rules,
        estimate: estimate,
        visionResult: visionResult,
        ready: ready,
      ),
    );
  }
}

class _CompositionGuidePainter extends CustomPainter {
  const _CompositionGuidePainter({
    required this.mode,
    required this.rules,
    required this.estimate,
    required this.visionResult,
    required this.ready,
  });

  final ShotMode mode;
  final CompositionRuleSet rules;
  final SubjectEstimate estimate;
  final VisionFrameResult? visionResult;
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case ShotMode.portrait:
        _drawGuideFromRule(canvas, size, fullBody: estimate.footLineY > 0.86);
      case ShotMode.selfie:
        _drawSelfieGuide(canvas, size);
      case ShotMode.group:
        _drawGuideFromRule(canvas, size, fullBody: true);
      case ShotMode.landscape:
        _drawGuideFromRule(canvas, size, fullBody: false);
      case ShotMode.stillLife:
        _drawStillLifeGuide(canvas, size);
      case ShotMode.object:
        _drawObjectGuide(canvas, size);
      case ShotMode.candid:
        _drawGuideFromRule(canvas, size, fullBody: false);
      case ShotMode.lowLight:
        _drawGuideFromRule(canvas, size, fullBody: false);
    }
  }

  void _drawGuideFromRule(Canvas canvas, Size size, {required bool fullBody}) {
    switch (rules.guideType) {
      case 'people_eye_thirds':
        _drawPeopleEyeThirdsGuide(canvas, size, fullBody);
      case 'group_people':
        _drawGroupPeopleGuide(canvas, size);
      case 'horizon_thirds':
        _drawHorizonThirdsGuide(canvas, size);
      case 'subject_thirds':
        _drawSubjectThirdsGuide(canvas, size);
      case 'subject_viewpoint':
        _drawSubjectViewpointGuide(canvas, size);
      case 'candid_people':
        _drawCandidPeopleGuide(canvas, size);
      case 'stable_level':
        _drawStableLevelGuide(canvas, size);
      default:
        _drawSubjectThirdsGuide(canvas, size);
    }
  }

  Paint _linePaint({double alpha = 0.78, double width = 3}) {
    return Paint()
      ..color = (ready ? const Color(0xff19c37d) : Colors.white).withValues(
        alpha: alpha,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Paint _fillPaint({double alpha = 0.10}) {
    return Paint()
      ..color = (ready ? const Color(0xff19c37d) : Colors.white).withValues(
        alpha: alpha,
      )
      ..style = PaintingStyle.fill;
  }

  void _drawTargetReticle(
    Canvas canvas,
    Offset center,
    double radius, {
    double alpha = 0.78,
  }) {
    final paint = _linePaint(alpha: alpha, width: 3);
    final soft = _linePaint(alpha: 0.16, width: 12);
    canvas.drawCircle(center, radius, soft);
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      center.translate(-radius * 1.35, 0),
      center.translate(-radius * 0.66, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(radius * 0.66, 0),
      center.translate(radius * 1.35, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius * 1.35),
      center.translate(0, -radius * 0.66),
      paint,
    );
    canvas.drawLine(
      center.translate(0, radius * 0.66),
      center.translate(0, radius * 1.35),
      paint,
    );
  }

  void _drawAnchorDot(Canvas canvas, Offset center, {double radius = 5}) {
    canvas.drawCircle(center, radius + 5, _fillPaint(alpha: 0.18));
    canvas.drawCircle(center, radius, _fillPaint(alpha: 0.74));
  }

  void _drawPeopleEyeThirdsGuide(Canvas canvas, Size size, bool fullBody) {
    final centerX = size.width * rules.bodyCenterX;
    final faceCenter = Offset(centerX, size.height * rules.faceCenterY);
    final eyeY = size.height * rules.eyeLineY;
    final footY = size.height * rules.footLineY;
    final guidePaint = _linePaint(alpha: 0.54, width: 2.2);
    final faceRadius = size.width * (fullBody ? 0.080 : 0.105);

    _drawTargetReticle(canvas, faceCenter, faceRadius);
    canvas.drawLine(
      Offset(size.width * 0.10, eyeY),
      Offset(size.width * 0.90, eyeY),
      guidePaint,
    );
    _drawAnchorDot(canvas, Offset(centerX, eyeY), radius: 4.5);
    canvas.drawLine(
      Offset(centerX, faceCenter.dy + size.height * 0.08),
      Offset(centerX, fullBody ? footY : size.height * 0.72),
      _linePaint(alpha: 0.42, width: 2.4),
    );

    if (fullBody) {
      _drawFullBodyHumanGuide(canvas, size, centerX, faceCenter, footY);
      canvas.drawLine(
        Offset(size.width * 0.18, footY),
        Offset(size.width * 0.82, footY),
        guidePaint,
      );
      _drawAnchorDot(canvas, Offset(centerX, footY), radius: 4.5);
    } else {
      _drawHalfBodyHumanGuide(canvas, size, centerX, faceCenter);
    }
  }

  void _drawFullBodyHumanGuide(
    Canvas canvas,
    Size size,
    double centerX,
    Offset faceCenter,
    double footY,
  ) {
    final outline = _linePaint(alpha: 0.40, width: 2.5);
    final soft = _linePaint(alpha: 0.12, width: 11);
    final headWidth = size.width * 0.18;
    final headHeight = headWidth * 1.24;
    final neckY = faceCenter.dy + headHeight * 0.56;
    final shoulderY = neckY + size.height * 0.055;
    final hipY = footY - size.height * 0.25;
    final shoulderHalf = size.width * 0.145;
    final waistHalf = size.width * 0.088;
    final hipHalf = size.width * 0.125;
    final handY = size.height * 0.66;
    final kneeY = footY - size.height * 0.13;

    final headRect = Rect.fromCenter(
      center: faceCenter,
      width: headWidth,
      height: headHeight,
    );
    canvas.drawOval(headRect.inflate(size.width * 0.012), soft);
    canvas.drawOval(headRect, outline);

    final shoulders = Path()
      ..moveTo(centerX - shoulderHalf, shoulderY)
      ..cubicTo(
        centerX - shoulderHalf * 0.68,
        shoulderY - size.height * 0.035,
        centerX - shoulderHalf * 0.22,
        neckY,
        centerX,
        neckY,
      )
      ..cubicTo(
        centerX + shoulderHalf * 0.22,
        neckY,
        centerX + shoulderHalf * 0.68,
        shoulderY - size.height * 0.035,
        centerX + shoulderHalf,
        shoulderY,
      );
    canvas.drawPath(shoulders, outline);

    final body = Path()
      ..moveTo(centerX - shoulderHalf * 0.74, shoulderY + size.height * 0.025)
      ..cubicTo(
        centerX - waistHalf * 1.18,
        size.height * 0.50,
        centerX - hipHalf * 0.96,
        hipY - size.height * 0.045,
        centerX - hipHalf * 0.92,
        hipY,
      )
      ..lineTo(centerX + hipHalf * 0.92, hipY)
      ..cubicTo(
        centerX + hipHalf * 0.96,
        hipY - size.height * 0.045,
        centerX + waistHalf * 1.18,
        size.height * 0.50,
        centerX + shoulderHalf * 0.74,
        shoulderY + size.height * 0.025,
      );
    canvas.drawPath(body, outline);

    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(centerX + side * shoulderHalf, shoulderY);
      final elbow = Offset(
        centerX + side * size.width * 0.17,
        size.height * 0.52,
      );
      final hand = Offset(centerX + side * size.width * 0.135, handY);
      final arm = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy);
      canvas.drawPath(arm, outline);
      canvas.drawCircle(hand, size.width * 0.014, _fillPaint(alpha: 0.28));

      final hip = Offset(centerX + side * hipHalf * 0.48, hipY);
      final knee = Offset(centerX + side * size.width * 0.058, kneeY);
      final foot = Offset(centerX + side * size.width * 0.088, footY);
      final leg = Path()
        ..moveTo(hip.dx, hip.dy)
        ..quadraticBezierTo(knee.dx, knee.dy, foot.dx, foot.dy);
      canvas.drawPath(leg, outline);
      canvas.drawLine(
        foot.translate(-side * size.width * 0.040, 0),
        foot.translate(side * size.width * 0.055, 0),
        outline,
      );
    }
  }

  void _drawHalfBodyHumanGuide(
    Canvas canvas,
    Size size,
    double centerX,
    Offset faceCenter,
  ) {
    final outline = _linePaint(alpha: 0.38, width: 2.5);
    final soft = _linePaint(alpha: 0.12, width: 11);
    final headWidth = size.width * 0.23;
    final headHeight = headWidth * 1.22;
    final neckY = faceCenter.dy + headHeight * 0.56;
    final shoulderY = neckY + size.height * 0.060;
    final torsoBottomY = size.height * 0.73;
    final shoulderHalf = size.width * 0.225;
    final waistHalf = size.width * 0.135;

    final headRect = Rect.fromCenter(
      center: faceCenter,
      width: headWidth,
      height: headHeight,
    );
    canvas.drawOval(headRect.inflate(size.width * 0.012), soft);
    canvas.drawOval(headRect, outline);

    final upperBody = Path()
      ..moveTo(centerX - shoulderHalf, shoulderY)
      ..cubicTo(
        centerX - shoulderHalf * 0.62,
        shoulderY - size.height * 0.045,
        centerX - size.width * 0.050,
        neckY,
        centerX,
        neckY,
      )
      ..cubicTo(
        centerX + size.width * 0.050,
        neckY,
        centerX + shoulderHalf * 0.62,
        shoulderY - size.height * 0.045,
        centerX + shoulderHalf,
        shoulderY,
      )
      ..cubicTo(
        centerX + waistHalf * 1.05,
        size.height * 0.56,
        centerX + waistHalf * 0.92,
        torsoBottomY,
        centerX + waistHalf * 0.66,
        torsoBottomY,
      )
      ..moveTo(centerX - shoulderHalf, shoulderY)
      ..cubicTo(
        centerX - waistHalf * 1.05,
        size.height * 0.56,
        centerX - waistHalf * 0.92,
        torsoBottomY,
        centerX - waistHalf * 0.66,
        torsoBottomY,
      );
    canvas.drawPath(upperBody, outline);

    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(centerX + side * shoulderHalf, shoulderY);
      final elbow = Offset(
        centerX + side * size.width * 0.245,
        size.height * 0.57,
      );
      final hand = Offset(
        centerX + side * size.width * 0.170,
        size.height * 0.71,
      );
      final arm = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy);
      canvas.drawPath(arm, outline);
      canvas.drawCircle(hand, size.width * 0.015, _fillPaint(alpha: 0.28));
    }
  }

  void _drawSelfieGuide(Canvas canvas, Size size) {
    final centerX = size.width * rules.bodyCenterX;
    final faceCenter = Offset(centerX, size.height * rules.faceCenterY);
    final eyeY = size.height * rules.eyeLineY;
    final facePaint = _linePaint(alpha: 0.88, width: 3.4);
    final softPaint = _linePaint(alpha: 0.14, width: 16);
    final guidePaint = _linePaint(alpha: 0.50, width: 2.0);
    final detectedFace = _bestFace();

    final faceRect = Rect.fromCenter(
      center: faceCenter,
      width: size.width * 0.40,
      height: size.width * 0.52,
    );
    canvas.drawOval(faceRect, softPaint);
    canvas.drawOval(faceRect, facePaint);
    _drawSelfieHighAngleCue(canvas, size, faceRect);
    final headroomY = faceRect.top - size.height * 0.035;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(faceCenter.dx, headroomY),
        width: faceRect.width * 0.72,
        height: size.height * 0.08,
      ),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      _linePaint(alpha: 0.44, width: 2.1),
    );
    canvas.drawLine(
      Offset(size.width * 0.20, eyeY),
      Offset(size.width * 0.80, eyeY),
      guidePaint,
    );
    _drawAnchorDot(canvas, Offset(centerX, eyeY), radius: 4.5);
    _drawSelfieEyeSlots(canvas, Offset(centerX, eyeY), size);
    _drawSelfieNoseMouthGuide(canvas, faceCenter, faceRect, size);
    canvas.drawArc(
      Rect.fromCenter(
        center: faceCenter.translate(
          -faceRect.width * 0.42,
          faceRect.height * 0.06,
        ),
        width: faceRect.width * 0.38,
        height: faceRect.height * 0.40,
      ),
      -math.pi * 0.44,
      math.pi * 0.46,
      false,
      _linePaint(alpha: 0.32, width: 2),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: faceCenter.translate(
          faceRect.width * 0.42,
          faceRect.height * 0.06,
        ),
        width: faceRect.width * 0.38,
        height: faceRect.height * 0.40,
      ),
      math.pi * 0.98,
      math.pi * 0.46,
      false,
      _linePaint(alpha: 0.32, width: 2),
    );
    _drawAnchorDot(canvas, faceCenter, radius: 4.8);

    if (detectedFace != null) {
      final rect = Rect.fromLTWH(
        detectedFace.x * size.width,
        detectedFace.y * size.height,
        detectedFace.width * size.width,
        detectedFace.height * size.height,
      );
      canvas.drawOval(
        rect.inflate(size.width * 0.012),
        _linePaint(alpha: 0.24, width: 2),
      );
    }
  }

  void _drawSelfieHighAngleCue(Canvas canvas, Size size, Rect faceRect) {
    final paint = _linePaint(alpha: 0.46, width: 2.1);
    final fill = _fillPaint(alpha: 0.14);
    final phoneCenter = Offset(
      faceRect.right + size.width * 0.12,
      faceRect.top + size.height * 0.055,
    );
    final phoneRect = Rect.fromCenter(
      center: phoneCenter,
      width: size.width * 0.070,
      height: size.height * 0.105,
    );

    canvas.save();
    canvas.translate(phoneCenter.dx, phoneCenter.dy);
    canvas.rotate(math.pi * 0.16);
    canvas.translate(-phoneCenter.dx, -phoneCenter.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect, const Radius.circular(5)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect, const Radius.circular(5)),
      paint,
    );
    canvas.drawCircle(
      Offset(phoneCenter.dx, phoneRect.bottom - size.height * 0.012),
      1.8,
      paint,
    );
    canvas.restore();

    final arrowStart = Offset(
      phoneCenter.dx - size.width * 0.020,
      phoneCenter.dy,
    );
    final arrowEnd = Offset(
      faceRect.center.dx + faceRect.width * 0.16,
      faceRect.top,
    );
    canvas.drawLine(arrowStart, arrowEnd, paint);
    canvas.drawLine(
      arrowEnd,
      arrowEnd.translate(size.width * 0.035, -size.height * 0.004),
      paint,
    );
    canvas.drawLine(
      arrowEnd,
      arrowEnd.translate(size.width * 0.006, -size.height * 0.030),
      paint,
    );
  }

  void _drawSelfieNoseMouthGuide(
    Canvas canvas,
    Offset faceCenter,
    Rect faceRect,
    Size size,
  ) {
    final featurePaint = _linePaint(alpha: 0.58, width: 2.1);
    final softPaint = _linePaint(alpha: 0.12, width: 8);
    final noseTop = Offset(
      faceCenter.dx,
      faceCenter.dy - faceRect.height * 0.03,
    );
    final noseTip = Offset(
      faceCenter.dx,
      faceCenter.dy + faceRect.height * 0.14,
    );
    final noseLeft = noseTip.translate(-faceRect.width * 0.055, 0);
    final noseRight = noseTip.translate(faceRect.width * 0.055, 0);
    final mouthCenter = Offset(
      faceCenter.dx,
      faceCenter.dy + faceRect.height * 0.30,
    );
    final mouthRect = Rect.fromCenter(
      center: mouthCenter,
      width: faceRect.width * 0.34,
      height: size.height * 0.035,
    );

    canvas.drawLine(noseTop, noseTip, softPaint);
    canvas.drawLine(noseTop, noseTip, featurePaint);
    canvas.drawLine(noseLeft, noseRight, featurePaint);
    canvas.drawArc(mouthRect, math.pi * 0.10, math.pi * 0.80, false, softPaint);
    canvas.drawArc(
      mouthRect,
      math.pi * 0.10,
      math.pi * 0.80,
      false,
      featurePaint,
    );
    _drawAnchorDot(canvas, noseTip, radius: 3.2);
    _drawAnchorDot(canvas, mouthCenter, radius: 3.2);
  }

  void _drawSelfieEyeSlots(Canvas canvas, Offset center, Size size) {
    final slotPaint = _linePaint(alpha: 0.46, width: 2.1);
    final slotWidth = size.width * 0.115;
    final slotHeight = size.height * 0.030;
    for (final dx in [-size.width * 0.095, size.width * 0.095]) {
      final rect = Rect.fromCenter(
        center: center.translate(dx, 0),
        width: slotWidth,
        height: slotHeight,
      );
      canvas.drawArc(rect, math.pi * 0.05, math.pi * 0.90, false, slotPaint);
    }
  }

  void _drawGroupPeopleGuide(Canvas canvas, Size size) {
    final y = size.height * rules.faceCenterY;
    final left = Offset(size.width * 0.38, y);
    final right = Offset(size.width * 0.62, y);
    final footY = size.height * rules.footLineY;

    _drawPairedHumanGuide(canvas, size, left, footY, lean: -1);
    _drawPairedHumanGuide(canvas, size, right, footY, lean: 1);
    for (final center in [left, right]) {
      _drawAnchorDot(canvas, center, radius: 4.5);
    }
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * rules.eyeLineY),
      Offset(size.width * 0.86, size.height * rules.eyeLineY),
      _linePaint(alpha: 0.52, width: 2.2),
    );
    canvas.drawLine(
      Offset(size.width * 0.22, footY),
      Offset(size.width * 0.78, footY),
      _linePaint(alpha: 0.36, width: 2.0),
    );
  }

  void _drawPairedHumanGuide(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    double footY, {
    required double lean,
  }) {
    final outline = _linePaint(alpha: 0.40, width: 2.3);
    final soft = _linePaint(alpha: 0.12, width: 10);
    final headWidth = size.width * 0.145;
    final headHeight = headWidth * 1.24;
    final neckY = faceCenter.dy + headHeight * 0.56;
    final shoulderY = neckY + size.height * 0.050;
    final hipY = footY - size.height * 0.22;
    final shoulderHalf = size.width * 0.118;
    final waistHalf = size.width * 0.070;
    final hipHalf = size.width * 0.095;
    final centerX = faceCenter.dx + lean * size.width * 0.012;

    final headRect = Rect.fromCenter(
      center: faceCenter,
      width: headWidth,
      height: headHeight,
    );
    canvas.drawOval(headRect.inflate(size.width * 0.010), soft);
    canvas.drawOval(headRect, outline);

    final body = Path()
      ..moveTo(centerX - shoulderHalf, shoulderY)
      ..cubicTo(
        centerX - shoulderHalf * 0.60,
        shoulderY - size.height * 0.030,
        faceCenter.dx - size.width * 0.030,
        neckY,
        faceCenter.dx,
        neckY,
      )
      ..cubicTo(
        faceCenter.dx + size.width * 0.030,
        neckY,
        centerX + shoulderHalf * 0.60,
        shoulderY - size.height * 0.030,
        centerX + shoulderHalf,
        shoulderY,
      )
      ..cubicTo(
        centerX + waistHalf * 1.10,
        size.height * 0.55,
        centerX + hipHalf * 0.92,
        hipY,
        centerX + hipHalf * 0.88,
        hipY,
      )
      ..lineTo(centerX - hipHalf * 0.88, hipY)
      ..cubicTo(
        centerX - hipHalf * 0.92,
        hipY,
        centerX - waistHalf * 1.10,
        size.height * 0.55,
        centerX - shoulderHalf,
        shoulderY,
      );
    canvas.drawPath(body, outline);

    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(centerX + side * shoulderHalf, shoulderY);
      final hand = Offset(
        centerX + side * size.width * 0.125 + lean * size.width * 0.012,
        size.height * 0.64,
      );
      final elbow = Offset(
        centerX + side * size.width * 0.132,
        size.height * 0.51,
      );
      final arm = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy);
      canvas.drawPath(arm, outline);
      canvas.drawCircle(hand, size.width * 0.012, _fillPaint(alpha: 0.28));
    }

    for (final side in [-1.0, 1.0]) {
      final hip = Offset(centerX + side * hipHalf * 0.42, hipY);
      final foot = Offset(centerX + side * size.width * 0.064, footY);
      canvas.drawLine(hip, foot, outline);
    }
  }

  void _drawHorizonThirdsGuide(Canvas canvas, Size size) {
    final guide = _linePaint(alpha: 0.74, width: 3);
    final thin = _linePaint(alpha: 0.36, width: 1.5);
    final horizonY = size.height * rules.horizonY;
    canvas.save();
    canvas.translate(size.width / 2, horizonY);
    canvas.rotate(estimate.horizonTiltDeg * math.pi / 180);
    canvas.drawLine(
      Offset(-size.width * 0.58, 0),
      Offset(size.width * 0.58, 0),
      guide,
    );
    canvas.restore();
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      thin,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      thin,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.92),
      Offset(size.width * 0.45, horizonY),
      thin,
    );
    canvas.drawLine(
      Offset(size.width * 0.88, size.height * 0.92),
      Offset(size.width * 0.55, horizonY),
      thin,
    );
  }

  void _drawSubjectThirdsGuide(Canvas canvas, Size size) {
    final center = Offset(
      size.width * rules.bodyCenterX,
      size.height * rules.faceCenterY,
    );
    final thin = _linePaint(alpha: 0.30, width: 1.5);
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      thin,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      thin,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      thin,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      thin,
    );
    _drawTargetReticle(canvas, center, size.width * 0.115);
    final triangle = Path()
      ..moveTo(center.dx, center.dy - size.width * 0.18)
      ..lineTo(center.dx - size.width * 0.18, center.dy + size.width * 0.14)
      ..lineTo(center.dx + size.width * 0.18, center.dy + size.width * 0.14)
      ..close();
    canvas.drawPath(triangle, _linePaint(alpha: 0.28, width: 2));
    _drawAnchorDot(canvas, center, radius: 5);
  }

  void _drawSubjectViewpointGuide(Canvas canvas, Size size) {
    _drawSubjectThirdsGuide(canvas, size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            size.width * rules.bodyCenterX,
            size.height * rules.faceCenterY,
          ),
          width: size.width * 0.48,
          height: size.height * 0.34,
        ),
        const Radius.circular(18),
      ),
      _linePaint(alpha: 0.34, width: 2),
    );
  }

  void _drawStillLifeGuide(Canvas canvas, Size size) {
    _drawSubjectThirdsGuide(canvas, size);
    final objects = _nonPersonObjects();
    final paint = _linePaint(alpha: 0.54, width: 2.4);
    if (objects.isEmpty) {
      return;
    }
    final topObjects = objects.take(3).toList(growable: false);
    final centers = topObjects
        .map((object) {
          return Offset(
            (object.x + object.width / 2) * size.width,
            (object.y + object.height / 2) * size.height,
          );
        })
        .toList(growable: false);
    for (final object in topObjects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            object.x * size.width,
            object.y * size.height,
            object.width * size.width,
            object.height * size.height,
          ),
          const Radius.circular(12),
        ),
        _linePaint(alpha: 0.30, width: 2),
      );
    }
    if (centers.length >= 3) {
      final triangle = Path()
        ..moveTo(centers[0].dx, centers[0].dy)
        ..lineTo(centers[1].dx, centers[1].dy)
        ..lineTo(centers[2].dx, centers[2].dy)
        ..close();
      canvas.drawPath(triangle, paint);
    } else {
      for (final center in centers) {
        _drawTargetReticle(canvas, center, size.width * 0.07, alpha: 0.55);
      }
    }
  }

  void _drawObjectGuide(Canvas canvas, Size size) {
    final objects = _nonPersonObjects();
    final object = objects.isEmpty ? null : objects.first;
    if (object == null) {
      _drawSubjectViewpointGuide(canvas, size);
      return;
    }
    final rect = Rect.fromLTWH(
      object.x * size.width,
      object.y * size.height,
      object.width * size.width,
      object.height * size.height,
    ).inflate(size.width * 0.025);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      _linePaint(alpha: 0.72, width: 3),
    );
    _drawTargetReticle(
      canvas,
      rect.center,
      math.min(rect.width, rect.height) * 0.22,
    );
    final negativeSpacePaint = _linePaint(alpha: 0.22, width: 1.5);
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      negativeSpacePaint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      negativeSpacePaint,
    );
  }

  List<DetectedObject> _nonPersonObjects() {
    final objects = visionResult?.objects ?? const <DetectedObject>[];
    return objects.where((object) => object.label != 'person').toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  DetectedFace? _bestFace() {
    final faces = visionResult?.faces ?? const <DetectedFace>[];
    if (faces.isEmpty) return null;
    final sorted = [...faces]
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    return sorted.first;
  }

  void _drawCandidPeopleGuide(Canvas canvas, Size size) {
    _drawPeopleEyeThirdsGuide(canvas, size, false);
    _drawCandidMotionSpace(canvas, size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.18,
          size.width * 0.72,
          size.height * 0.62,
        ),
        const Radius.circular(24),
      ),
      _linePaint(alpha: 0.26, width: 2),
    );
  }

  void _drawCandidMotionSpace(Canvas canvas, Size size) {
    final centerX = size.width * rules.bodyCenterX;
    final y = size.height * 0.48;
    final direction = centerX < size.width * 0.50 ? 1.0 : -1.0;
    final paint = _linePaint(alpha: 0.34, width: 2.2);
    final hand = Offset(centerX + direction * size.width * 0.20, y);
    final elbow = Offset(
      centerX + direction * size.width * 0.11,
      y + size.height * 0.06,
    );
    final shoulder = Offset(
      centerX + direction * size.width * 0.07,
      y - size.height * 0.02,
    );
    final arm = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy);
    canvas.drawPath(arm, paint);
    canvas.drawCircle(hand, size.width * 0.014, _fillPaint(alpha: 0.24));

    final arrowStart = Offset(
      centerX + direction * size.width * 0.18,
      size.height * 0.35,
    );
    final arrowEnd = Offset(
      centerX + direction * size.width * 0.34,
      size.height * 0.35,
    );
    canvas.drawLine(arrowStart, arrowEnd, paint);
    canvas.drawLine(
      arrowEnd,
      arrowEnd.translate(-direction * size.width * 0.035, -size.height * 0.020),
      paint,
    );
    canvas.drawLine(
      arrowEnd,
      arrowEnd.translate(-direction * size.width * 0.035, size.height * 0.020),
      paint,
    );
  }

  void _drawStableLevelGuide(Canvas canvas, Size size) {
    final center = Offset(
      size.width * rules.bodyCenterX,
      size.height * rules.faceCenterY,
    );
    canvas.drawCircle(
      center,
      size.width * 0.18,
      _linePaint(alpha: 0.28, width: 12),
    );
    canvas.drawCircle(
      center,
      size.width * 0.18,
      _linePaint(alpha: 0.70, width: 2.5),
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height * rules.horizonY);
    canvas.rotate(estimate.horizonTiltDeg * math.pi / 180);
    canvas.drawLine(
      Offset(-size.width * 0.58, 0),
      Offset(size.width * 0.58, 0),
      _linePaint(alpha: 0.62, width: 3),
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.20,
          size.width * 0.64,
          size.height * 0.62,
        ),
        const Radius.circular(24),
      ),
      _linePaint(alpha: 0.32, width: 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompositionGuidePainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.rules != rules ||
        oldDelegate.estimate != estimate ||
        oldDelegate.visionResult != visionResult ||
        oldDelegate.ready != ready;
  }
}
