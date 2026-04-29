class AutoCaptureController {
  AutoCaptureController({
    this.checkInterval = const Duration(seconds: 1),
    this.stableDuration = const Duration(seconds: 1),
    this.shotCooldown = const Duration(milliseconds: 4500),
    this.maxFrameDrift = 0.045,
  });

  final Duration checkInterval;
  final Duration stableDuration;
  final Duration shotCooldown;
  final double maxFrameDrift;

  DateTime? _lastCheckAt;
  DateTime? _readySince;
  double? _lastSubjectX;
  double? _lastSubjectY;

  void reset() {
    _lastCheckAt = null;
    _resetReadyWindow();
  }

  AutoCaptureDecision evaluate({
    required DateTime now,
    required bool enabled,
    required bool aiEnabled,
    required bool canAutoCaptureMode,
    required bool isPhotoMode,
    required bool isBusy,
    required bool isCameraSuspended,
    required bool hasFreshAnalysis,
    required bool hasReliableSubject,
    required bool compositionReady,
    required bool eyesOpen,
    required double? subjectX,
    required double? subjectY,
    required DateTime? lastShotAt,
  }) {
    if (!enabled ||
        !aiEnabled ||
        !canAutoCaptureMode ||
        !isPhotoMode ||
        isBusy ||
        isCameraSuspended ||
        !hasFreshAnalysis) {
      reset();
      return AutoCaptureDecision.wait;
    }

    final lastCheckAt = _lastCheckAt;
    if (lastCheckAt != null && now.difference(lastCheckAt) < checkInterval) {
      return AutoCaptureDecision.wait;
    }
    _lastCheckAt = now;

    if (!hasReliableSubject || !compositionReady || !eyesOpen) {
      _resetReadyWindow();
      return AutoCaptureDecision.wait;
    }

    if (_hasUnstableFrame(subjectX, subjectY)) {
      _readySince = now;
      _lastSubjectX = subjectX;
      _lastSubjectY = subjectY;
      return AutoCaptureDecision.wait;
    }
    _lastSubjectX = subjectX;
    _lastSubjectY = subjectY;

    final readySince = _readySince;
    if (readySince == null) {
      _readySince = now;
      return AutoCaptureDecision.wait;
    }
    if (now.difference(readySince) < stableDuration) {
      return AutoCaptureDecision.wait;
    }

    if (lastShotAt != null && now.difference(lastShotAt) < shotCooldown) {
      return AutoCaptureDecision.wait;
    }

    _resetReadyWindow();
    return AutoCaptureDecision.capture;
  }

  bool _hasUnstableFrame(double? subjectX, double? subjectY) {
    final lastX = _lastSubjectX;
    final lastY = _lastSubjectY;
    if (subjectX == null ||
        subjectY == null ||
        lastX == null ||
        lastY == null) {
      return false;
    }
    final dx = subjectX - lastX;
    final dy = subjectY - lastY;
    return dx * dx + dy * dy > maxFrameDrift * maxFrameDrift;
  }

  void _resetReadyWindow() {
    _readySince = null;
    _lastSubjectX = null;
    _lastSubjectY = null;
  }
}

enum AutoCaptureDecision { wait, capture }
