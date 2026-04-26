part of 'package:exbf_camera/screens/camera_screen.dart';

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.cue, required this.ready});

  final String cue;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      top: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (ready ? const Color(0xff1f9d55) : Colors.black).withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          cue,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
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
