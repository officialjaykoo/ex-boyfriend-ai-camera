part of 'package:exbf_camera/screens/camera_screen.dart';

enum _CameraSessionPhase {
  preparing,
  photoReady,
  videoReady,
  recording,
  capturing,
  suspended,
  error,
}

class _CameraSessionState {
  const _CameraSessionState(this.phase, {this.message});

  final _CameraSessionPhase phase;
  final String? message;

  bool get isBusy =>
      phase == _CameraSessionPhase.preparing ||
      phase == _CameraSessionPhase.capturing;

  bool get isRecording => phase == _CameraSessionPhase.recording;

  bool get isSuspended => phase == _CameraSessionPhase.suspended;

  bool get isReady =>
      phase == _CameraSessionPhase.photoReady ||
      phase == _CameraSessionPhase.videoReady;

  _CameraSessionState copyWith({_CameraSessionPhase? phase, String? message}) {
    return _CameraSessionState(
      phase ?? this.phase,
      message: message ?? this.message,
    );
  }
}

enum _CapturePipelineStatus { idle, saving, success, failure }

class _CapturePipelineEvent {
  const _CapturePipelineEvent({required this.status, this.path, this.error});

  final _CapturePipelineStatus status;
  final String? path;
  final Object? error;
}

class _CapturePipeline {
  _CapturePipeline({required this.album});

  final String album;
  final ValueNotifier<_CapturePipelineEvent> events = ValueNotifier(
    const _CapturePipelineEvent(status: _CapturePipelineStatus.idle),
  );

  Future<String> saveImage(String path) async {
    events.value = _CapturePipelineEvent(
      status: _CapturePipelineStatus.saving,
      path: path,
    );
    final file = File(path);
    if (!await file.exists() || await file.length() <= 0) {
      throw StateError('Image file is empty');
    }
    if (Platform.isAndroid) {
      if (path.toLowerCase().endsWith('.jpg') ||
          path.toLowerCase().endsWith('.jpeg')) {
        await _NativeCameraBridge.normalizeJpegExif(path);
      }
      final result = await _NativeCameraBridge.saveImageToGallery(
        path: path,
        displayName: _displayName(path),
        mimeType: _mimeType(path),
      );
      if (result.ok) {
        events.value = _CapturePipelineEvent(
          status: _CapturePipelineStatus.success,
          path: result.uri.isNotEmpty ? result.uri : path,
        );
        return path;
      }
      throw StateError(
        result.error.isEmpty ? 'Gallery save failed' : result.error,
      );
    }
    if (!await Gal.hasAccess(toAlbum: true)) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) throw StateError('Gallery access denied');
    }
    try {
      await Gal.putImage(path, album: album);
    } catch (_) {
      await Gal.putImage(path);
    }
    events.value = _CapturePipelineEvent(
      status: _CapturePipelineStatus.success,
      path: path,
    );
    return path;
  }

  String _displayName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    if (name.isNotEmpty) return name;
    final extension = path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    return 'EXBF_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  String _mimeType(String path) {
    return path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  }

  Future<String> saveVideo(String path) async {
    events.value = _CapturePipelineEvent(
      status: _CapturePipelineStatus.saving,
      path: path,
    );
    final file = File(path);
    if (!await file.exists() || await file.length() <= 0) {
      throw StateError('Video file is empty');
    }
    if (!await Gal.hasAccess(toAlbum: true)) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) throw StateError('Gallery access denied');
    }
    try {
      await Gal.putVideo(path, album: album);
    } catch (_) {
      await Gal.putVideo(path);
    }
    events.value = _CapturePipelineEvent(
      status: _CapturePipelineStatus.success,
      path: path,
    );
    return path;
  }

  void fail(Object error) {
    events.value = _CapturePipelineEvent(
      status: _CapturePipelineStatus.failure,
      error: error,
    );
  }

  void reset() {
    events.value = const _CapturePipelineEvent(
      status: _CapturePipelineStatus.idle,
    );
  }

  void dispose() => events.dispose();
}

extension _CameraOperationGate on _CameraScreenState {
  Future<T?> _runCameraOperation<T>(Future<T> Function() action) async {
    if (_isCameraOperationInFlight) return null;
    _isCameraOperationInFlight = true;
    try {
      return await action();
    } finally {
      _isCameraOperationInFlight = false;
    }
  }
}

enum FlashMode { off, auto, always, torch }

enum ResolutionPreset { high, veryHigh, ultraHigh }

class _AnalysisPipeline {
  _AnalysisPipeline({
    required this.minFrameGap,
    required this.minSubjectConfidence,
    required this.minPoseConfidence,
  });

  final Duration minFrameGap;
  final double minSubjectConfidence;
  final double minPoseConfidence;
  bool _isAnalyzing = false;
  DateTime? _lastFrameAt;

  bool shouldAnalyze(DateTime now) {
    final last = _lastFrameAt;
    if (_isAnalyzing) return false;
    if (last != null && now.difference(last) < minFrameGap) return false;
    _isAnalyzing = true;
    _lastFrameAt = now;
    return true;
  }

  void complete() {
    _isAnalyzing = false;
  }

  void reset() {
    _isAnalyzing = false;
    _lastFrameAt = null;
  }

  bool isReliable(SubjectEstimate? estimate) {
    if (estimate == null) return false;
    return estimate.subjectConfidence >= minSubjectConfidence ||
        estimate.poseConfidence >= minPoseConfidence;
  }
}

class _ZoomModel {
  const _ZoomModel({
    required this.min,
    required this.max,
    required this.current,
  });

  final double min;
  final double max;
  final double current;

  _ZoomModel copyWith({double? min, double? max, double? current}) {
    return _ZoomModel(
      min: min ?? this.min,
      max: max ?? this.max,
      current: current ?? this.current,
    );
  }

  double clamp(double value) => value.clamp(min, max).toDouble();

  double get oneX => clamp(1);

  double nextPreset({required bool hasWideLens}) {
    final candidates = [1.0, 2.0, 3.0, 0.5]
        .where((value) => hasWideLens || value != 0.5)
        .toSet()
        .toList(growable: false);
    final currentIndex = candidates.indexWhere(
      (value) => (current - value).abs() < 0.15,
    );
    return candidates[(currentIndex + 1) % candidates.length];
  }
}
