part of 'package:exbf_camera/screens/camera_screen.dart';

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.cue, required this.ready});

  final String cue;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final action = _cueAction(cue, ready);
    return Positioned(
      left: 14,
      top: 14,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: (ready ? const Color(0xff1f9d55) : Colors.black).withValues(
            alpha: 0.60,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CuePictogram(action: action),
            const SizedBox(width: 7),
            Text(
              cue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CueAction _cueAction(String cue, bool ready) {
    if (ready || cue.contains('OK') || cue.contains('촬영')) {
      return _CueAction.capture;
    }
    if (cue.contains('아래')) return _CueAction.down;
    if (cue.contains('위')) return _CueAction.up;
    if (cue.contains('오른쪽')) return _CueAction.right;
    if (cue.contains('왼쪽')) return _CueAction.left;
    if (cue.contains('각도') || cue.contains('수평') || cue.contains('지평선')) {
      return _CueAction.tilt;
    }
    if (cue.contains('뒤로')) return _CueAction.back;
    if (cue.contains('가까이') || cue.contains('채우게')) {
      return _CueAction.forward;
    }
    if (cue.contains('고정') || cue.contains('멈추고')) {
      return _CueAction.capture;
    }
    return _CueAction.adjust;
  }
}

enum _CueAction { up, down, left, right, tilt, back, forward, capture, adjust }

class _CuePictogram extends StatefulWidget {
  const _CuePictogram({required this.action});

  final _CueAction action;

  @override
  State<_CuePictogram> createState() => _CuePictogramState();
}

class _CuePictogramState extends State<_CuePictogram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 28,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CuePictogramPainter(
              widget.action,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _CuePictogramPainter extends CustomPainter {
  const _CuePictogramPainter(this.action, {required this.progress});

  final _CueAction action;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final motion = math.sin(progress * math.pi);
    final phonePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final phoneOffset = _phoneMotion(size, motion);
    final phoneRect = Rect.fromCenter(
      center: Offset(size.width * 0.42, size.height * 0.50) + phoneOffset,
      width: size.width * 0.30,
      height: size.height * 0.70,
    );

    canvas.save();
    if (action == _CueAction.tilt) {
      canvas.translate(phoneRect.center.dx, phoneRect.center.dy);
      canvas.rotate(-0.34 + motion * 0.34);
      canvas.translate(-phoneRect.center.dx, -phoneRect.center.dy);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect, const Radius.circular(4)),
      phonePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect, const Radius.circular(4)),
      stroke,
    );
    canvas.drawCircle(
      Offset(phoneRect.center.dx, phoneRect.bottom - size.height * 0.08),
      1.3,
      fill,
    );
    canvas.restore();

    switch (action) {
      case _CueAction.up:
        _drawArrow(
          canvas,
          stroke,
          Offset(size.width * 0.76, size.height * (0.80 - motion * 0.08)),
          Offset(size.width * 0.76, size.height * (0.24 - motion * 0.08)),
        );
      case _CueAction.down:
        _drawArrow(
          canvas,
          stroke,
          Offset(size.width * 0.76, size.height * (0.20 + motion * 0.08)),
          Offset(size.width * 0.76, size.height * (0.76 + motion * 0.08)),
        );
      case _CueAction.left:
        _drawArrow(
          canvas,
          stroke,
          Offset(size.width * (0.94 - motion * 0.06), size.height * 0.50),
          Offset(size.width * (0.62 - motion * 0.06), size.height * 0.50),
        );
      case _CueAction.right:
        _drawArrow(
          canvas,
          stroke,
          Offset(size.width * (0.56 + motion * 0.06), size.height * 0.50),
          Offset(size.width * (0.88 + motion * 0.06), size.height * 0.50),
        );
      case _CueAction.tilt:
        _drawTiltArrow(canvas, stroke, size);
      case _CueAction.back:
        _drawArrow(
          canvas,
          stroke,
          Offset(size.width * 0.78, size.height * 0.28),
          Offset(size.width * 0.78, size.height * (0.70 + motion * 0.08)),
        );
        canvas.drawLine(
          Offset(size.width * 0.60, size.height * 0.80),
          Offset(size.width * 0.96, size.height * 0.80),
          stroke,
        );
      case _CueAction.forward:
        canvas.drawCircle(
          Offset(size.width * 0.76, size.height * 0.50),
          5 + motion * 4,
          stroke,
        );
        canvas.drawCircle(
          Offset(size.width * 0.76, size.height * 0.50),
          2,
          fill,
        );
      case _CueAction.capture:
        canvas.drawCircle(
          Offset(size.width * 0.78, size.height * 0.50),
          6 + motion * 2,
          stroke,
        );
        canvas.drawCircle(
          Offset(size.width * 0.78, size.height * 0.50),
          3,
          fill,
        );
      case _CueAction.adjust:
        canvas.drawLine(
          Offset(size.width * 0.64, size.height * 0.34),
          Offset(size.width * 0.92, size.height * 0.34),
          stroke,
        );
        canvas.drawLine(
          Offset(size.width * 0.64, size.height * 0.66),
          Offset(size.width * 0.92, size.height * 0.66),
          stroke,
        );
    }
  }

  Offset _phoneMotion(Size size, double motion) {
    final distance = 4.0 * motion;
    return switch (action) {
      _CueAction.up => Offset(0, -distance),
      _CueAction.down => Offset(0, distance),
      _CueAction.left => Offset(-distance, 0),
      _CueAction.right => Offset(distance, 0),
      _CueAction.back => Offset(0, distance * 0.55),
      _CueAction.forward => Offset(0, -distance * 0.45),
      _ => Offset.zero,
    };
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    canvas.drawLine(start, end, paint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const head = 6.0;
    for (final delta in [0.72, -0.72]) {
      final headAngle = angle + math.pi + delta;
      canvas.drawLine(
        end,
        Offset(
          end.dx + math.cos(headAngle) * head,
          end.dy + math.sin(headAngle) * head,
        ),
        paint,
      );
    }
  }

  void _drawTiltArrow(Canvas canvas, Paint paint, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.74, size.height * 0.50),
      radius: size.width * 0.18,
    );
    canvas.drawArc(rect, -1.0, 1.7, false, paint);
    final end = Offset(size.width * 0.87, size.height * 0.38);
    canvas.drawLine(end, end.translate(-5, -1), paint);
    canvas.drawLine(end, end.translate(-2, 5), paint);
  }

  @override
  bool shouldRepaint(covariant _CuePictogramPainter oldDelegate) {
    return oldDelegate.action != action || oldDelegate.progress != progress;
  }
}

class _ZoomBadge extends StatelessWidget {
  const _ZoomBadge({required this.zoom, required this.onTap});

  final double zoom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.42),
        ),
        child: Text(
          '${zoom.toStringAsFixed(zoom >= 10 ? 0 : 1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NightFloatIcon extends StatelessWidget {
  const _NightFloatIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.nightlight_round, color: Colors.white, size: 17),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.46),
          shape: BoxShape.circle,
          border: Border.all(color: _accentPink, width: 4),
        ),
        child: Text(
          '$seconds',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RecordingTimerBadge extends StatelessWidget {
  const _RecordingTimerBadge({required this.startedAt});

  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Positioned(
      top: 14,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xffff3b30),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'REC $minutes:$seconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusReticle extends StatelessWidget {
  const _FocusReticle({required this.point});

  final Offset point;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: point.dx - 32,
      top: point.dy - 32,
      child: IgnorePointer(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: _accentPink, width: 2.4),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _accentPink,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExposureGestureBadge extends StatelessWidget {
  const _ExposureGestureBadge({required this.exposure});

  final double exposure;

  @override
  Widget build(BuildContext context) {
    final normalized = ((exposure + 3) / 6).clamp(0.0, 1.0);
    return Positioned(
      right: 18,
      top: 92,
      child: IgnorePointer(
        child: Container(
          width: 42,
          height: 164,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      heightFactor: normalized,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: _accentPink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exposure >= 0
                    ? '+${exposure.toStringAsFixed(1)}'
                    : exposure.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotThumbnail extends StatelessWidget {
  const _ShotThumbnail({
    required this.path,
    required this.onTap,
    this.isVideo = false,
  });

  final String path;
  final VoidCallback onTap;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: isVideo
              ? ColoredBox(
                  color: Colors.black.withValues(alpha: 0.72),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                )
              : Image.file(File(path), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
