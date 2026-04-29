// ignore_for_file: invalid_use_of_protected_member

part of 'package:exbf_camera/screens/camera_screen.dart';

extension _CameraControls on _CameraScreenState {
  Future<void> _switchCamera() async {
    if (_isBusy || _isCameraSuspended || _isCameraOperationInFlight) return;
    await _runCameraOperation(() async {
      setState(() => _status = 'Camera switching');
      await _NativeCameraBridge.switchCamera();
      await _refreshNativeState();
      if (!mounted) return;
      setState(() {
        _nativeSelectedSensorId = null;
        _zoom = 1;
        _zoomModel = _zoomModel.copyWith(current: 1);
        _visionResult = null;
        _lastAnalysisFrameAt = null;
        _status = 'Camera switched';
      });
    });
  }

  void _setShotMode(ShotMode mode) {
    final nextMode = ShotModePolicy.normalizeVisibleMode(mode);
    if (_shotMode == nextMode) {
      unawaited(_applyShotModeCameraPolicy(nextMode));
      return;
    }
    setState(() {
      _shotMode = nextMode;
      _autoCapture.reset();
      _vision.clearResult();
      if (!ShotModePolicy.canAutoCapture(nextMode)) {
        _autoCaptureEnabled = false;
      }
      _status = nextMode == ShotMode.selfie
          ? 'Selfie front camera'
          : 'Rear camera guide';
    });
    unawaited(_applyShotModeCameraPolicy(nextMode));
    unawaited(_saveSetting('shotMode', nextMode.name));
  }

  Future<void> _applyShotModeCameraPolicy(ShotMode mode) async {
    await _applyAnalysisModeForShotMode(mode);
    await _syncCameraFacingForShotMode(mode);
  }

  Future<void> _syncCameraFacingForShotMode(ShotMode mode) async {
    if (_isCameraSuspended ||
        !_nativeCameraReady ||
        _isCameraOperationInFlight) {
      return;
    }
    final wantsFrontCamera = mode == ShotMode.selfie;
    if (wantsFrontCamera == _isFrontCamera) return;
    await _switchCamera();
  }

  Future<void> _setFlash(FlashMode mode) async {
    _flashMode = mode;
    unawaited(_saveSetting('flashMode', mode.name));
    await _NativeCameraBridge.setFlash(mode);
    if (mounted) setState(() => _ui.flashMenuOpen = false);
  }

  Future<void> _setResolution(ResolutionPreset preset) async {
    if (_isCameraSuspended || _isCameraOperationInFlight) return;
    if (_resolutionPreset == preset) {
      setState(() => _ui.settingsMenuOpen = false);
      return;
    }
    setState(() {
      _resolutionPreset = preset;
      _ui.settingsMenuOpen = false;
      _status = 'Camera loading';
    });
    unawaited(_saveSetting('resolutionPreset', preset.name));
    await _runCameraOperation(() async {
      await _NativeCameraBridge.setResolution(preset);
      await _NativeCameraBridge.start();
      await _refreshNativeState();
      if (mounted) {
        setState(
          () => _setSession(
            _ui.mediaMode == MediaMode.video
                ? _CameraSessionPhase.videoReady
                : _CameraSessionPhase.photoReady,
            message: 'CameraX ready',
          ),
        );
      }
    });
  }

  Future<void> _setZoom(double value) async {
    if (_isCameraSuspended || _isCameraOperationInFlight) return;
    final keepCurrentLens = _isFrontCamera || _shotMode == ShotMode.selfie;
    final next = keepCurrentLens
        ? value.clamp(1, 10).toDouble()
        : value <= 0.55
        ? 0.5
        : value.clamp(1, 10).toDouble();
    if (!keepCurrentLens &&
        next == 0.5 &&
        _nativeWideSensorId != null &&
        _nativeSelectedSensorId != _nativeWideSensorId) {
      _nativeSelectedSensorId = _nativeWideSensorId;
      await _NativeCameraBridge.setSensor(_nativeWideSensorId!);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    } else if (!keepCurrentLens &&
        next >= 0.95 &&
        _nativeStandardSensorId != null &&
        _nativeSelectedSensorId == _nativeWideSensorId) {
      _nativeSelectedSensorId = _nativeStandardSensorId;
      await _NativeCameraBridge.setSensor(_nativeStandardSensorId!);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    await _NativeCameraBridge.setZoom(next == 0.5 ? 1 : next);
    if (mounted) {
      setState(() {
        _zoom = next;
        _zoomModel = _zoomModel.copyWith(current: next);
      });
    }
  }

  Future<void> _setExposure(double value) async {
    final next = value.clamp(_minExposure, _maxExposure).toDouble();
    _exposure = next;
    await _NativeCameraBridge.setExposure(next);
    if (mounted) setState(() {});
  }

  void _adjustExposureByDrag(double deltaY) {
    if (_isCameraSuspended || _isCameraOperationInFlight) return;
    final next = (_exposure - deltaY / 140).clamp(_minExposure, _maxExposure);
    _exposureGestureTimer?.cancel();
    setState(() {
      _exposure = next.toDouble();
      _ui.showExposureGesture = true;
      _status = _exposure >= 0
          ? 'Exposure +${_exposure.toStringAsFixed(1)}'
          : 'Exposure ${_exposure.toStringAsFixed(1)}';
    });
    unawaited(_NativeCameraBridge.setExposure(_exposure));
    _exposureGestureTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) setState(() => _ui.showExposureGesture = false);
    });
  }

  Future<void> _applyManualControls() async {
    await _NativeCameraBridge.setManualControls(
      iso: _manualIso,
      exposureTimeNs: _manualShutterNs,
      whiteBalance: _manualWhiteBalance,
    );
    await _refreshNativeState();
  }

  Future<void> _setManualIso(int? iso) async {
    setState(() => _manualIso = iso);
    await _applyManualControls();
  }

  Future<void> _setManualShutter(int? shutterNs) async {
    setState(() => _manualShutterNs = shutterNs);
    await _applyManualControls();
  }

  Future<void> _setWhiteBalance(String whiteBalance) async {
    setState(() => _manualWhiteBalance = whiteBalance);
    await _applyManualControls();
  }

  Future<void> _cycleZoom() async {
    await _setZoom(
      _zoomModel.nextPreset(hasWideLens: _hasWideBackCamera && !_isFrontCamera),
    );
  }

  bool get _hasWideBackCamera => _nativeWideSensorId != null;

  bool get _isFrontCamera => _nativeState.lensFacing == 'front';

  _NativeCameraSensor? get _activeNativeSensor {
    for (final sensor in _nativeSensors) {
      if (sensor.id == _nativeSelectedSensorId) return sensor;
    }
    for (final sensor in _nativeSensors) {
      if (sensor.id == _nativeStandardSensorId) return sensor;
    }
    for (final sensor in _nativeSensors) {
      if (sensor.isBack) return sensor;
    }
    return _nativeSensors.isEmpty ? null : _nativeSensors.first;
  }

  List<int> get _supportedVideoFps {
    final values = _activeNativeSensor?.supportedFps ?? const [30];
    return values.isEmpty ? const [30] : values;
  }

  List<ResolutionPreset> get _supportedResolutionPresets {
    final values =
        _activeNativeSensor?.supportedResolutionPresets ??
        const [ResolutionPreset.high, ResolutionPreset.veryHigh];
    return values.isEmpty
        ? const [ResolutionPreset.high, ResolutionPreset.veryHigh]
        : values;
  }

  void _toggleAutoCapture() {
    if (!ShotModePolicy.canAutoCapture(_shotMode)) {
      setState(() {
        _autoCapture.reset();
        _autoCaptureEnabled = false;
        _status = 'Selfie uses face guide';
      });
      return;
    }
    setState(() {
      _autoCapture.reset();
      _autoCaptureEnabled = !_autoCaptureEnabled;
      _status = _autoCaptureEnabled ? 'AUTO ON' : 'AUTO OFF';
    });
  }

  Future<void> _setMediaMode(MediaMode mode) async {
    if (_ui.mediaMode == mode ||
        _isBusy ||
        _isCameraSuspended ||
        _isCameraOperationInFlight) {
      return;
    }
    setState(() {
      _ui.mediaMode = mode;
      _status = 'Camera loading';
      if (mode == MediaMode.video) {
        _visionResult = null;
        _lastAnalysisFrameAt = null;
      }
      if (!_session.isRecording && !_session.isSuspended) {
        _setSession(
          mode == MediaMode.video
              ? _CameraSessionPhase.videoReady
              : _CameraSessionPhase.photoReady,
        );
      }
    });
    await _runCameraOperation(() async {
      await _NativeCameraBridge.setCaptureMode(mode);
      await _refreshNativeState();
      if (!mounted) return;
      setState(() {
        _setSession(
          mode == MediaMode.video
              ? _CameraSessionPhase.videoReady
              : _CameraSessionPhase.photoReady,
          message: mode == MediaMode.video ? 'Video ready' : 'Photo ready',
        );
      });
    });
  }

  Future<void> _applyAnalysisModeForShotMode(ShotMode mode) async {
    await _NativeCameraBridge.setAnalysisMode(
      ShotModePolicy.nativeAnalysisModeFor(mode),
    );
  }

  void _toggleGuides() {
    setState(() => _ui.showGuides = !_ui.showGuides);
    unawaited(_saveSetting('showGuides', _ui.showGuides));
  }

  void _toggleGrid() {
    setState(() => _ui.showGrid = !_ui.showGrid);
    unawaited(_saveSetting('showGrid', _ui.showGrid));
  }

  void _toggleScore() {
    setState(() => _ui.showScore = !_ui.showScore);
    unawaited(_saveSetting('showScore', _ui.showScore));
  }

  void _toggleVisionDebug() {
    setState(() => _ui.showVisionDebug = !_ui.showVisionDebug);
    unawaited(_saveSetting('showVisionDebug', _ui.showVisionDebug));
  }

  Future<void> _focusAt(TapDownDetails details, Size previewSize) async {
    if (_isZoomBadgeTap(details.localPosition, previewSize)) {
      return;
    }
    final point = Offset(
      (details.localPosition.dx / previewSize.width).clamp(0, 1).toDouble(),
      (details.localPosition.dy / previewSize.height).clamp(0, 1).toDouble(),
    );
    await _NativeCameraBridge.focus(point);
    _focusTimer?.cancel();
    setState(() {
      _ui.focusPoint = details.localPosition;
      _status = 'Focus set';
    });
    _focusTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _ui.focusPoint = null);
    });
  }

  bool _isZoomBadgeTap(Offset point, Size previewSize) {
    const badgeSize = 58.0;
    const margin = 16.0;
    const touchPadding = 20.0;
    final left = previewSize.width - margin - badgeSize - touchPadding;
    final top = previewSize.height - margin - badgeSize - touchPadding;
    return point.dx >= left && point.dy >= top;
  }

  void _cycleCaptureTimer() {
    const timers = [
      Duration.zero,
      Duration(seconds: 3),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ];
    final index = timers.indexOf(_captureTimer);
    setState(() {
      _captureTimer = timers[(index + 1) % timers.length];
      _status = _captureTimer == Duration.zero
          ? 'Timer OFF'
          : 'Timer ${_captureTimer.inSeconds}s';
    });
    unawaited(_saveSetting('captureTimer', _captureTimer.inSeconds));
  }

  void _cycleImageQuality() {
    const values = [85, 95, 100];
    final index = values.indexOf(_imageQuality);
    setState(() {
      _imageQuality = values[(index + 1) % values.length];
      _status = 'Quality $_imageQuality';
    });
    unawaited(_saveSetting('imageQuality', _imageQuality));
  }

  Future<void> _applyVideoOptions() async {
    await _NativeCameraBridge.setVideoOptions(
      fps: _videoFps,
      bitrate: _videoBitrate,
      audio: _videoAudioEnabled,
    );
    await _refreshNativeState();
  }

  Future<void> _cycleVideoFps() async {
    final values = _supportedVideoFps;
    final index = values.indexOf(_videoFps);
    setState(() {
      _videoFps = values[(index + 1) % values.length];
      _status = 'Video $_videoFps fps';
    });
    unawaited(_saveSetting('videoFps', _videoFps));
    await _applyVideoOptions();
  }

  Future<void> _cycleVideoBitrate() async {
    const values = [6000000, 10000000, 20000000, 40000000];
    final index = values.indexOf(_videoBitrate);
    setState(() {
      _videoBitrate = values[(index + 1) % values.length];
      _status = 'Video ${(_videoBitrate / 1000000).round()}Mbps';
    });
    unawaited(_saveSetting('videoBitrate', _videoBitrate));
    await _applyVideoOptions();
  }

  Future<void> _toggleVideoAudio() async {
    setState(() {
      _videoAudioEnabled = !_videoAudioEnabled;
      _status = _videoAudioEnabled ? 'Audio ON' : 'Audio OFF';
    });
    unawaited(_saveSetting('videoAudio', _videoAudioEnabled));
    await _applyVideoOptions();
  }

  void _setImageOutputFormat(ImageOutputFormat format) {
    setState(() {
      _imageOutputFormat = format;
      _status = format == ImageOutputFormat.jpg ? 'JPG' : 'PNG';
    });
    unawaited(_saveSetting('imageOutputFormat', format.name));
  }

  void _toggleTopMenu(String menu) {
    setState(() {
      _ui.closeToolPanel();
      _ui.toggleTopMenu(menu);
    });
  }

  void _toggleToolPanel(ToolPanel panel) {
    setState(() {
      _ui.closeMenus();
      _ui.toggleToolPanel(panel);
    });
  }

  double? _previewAspectRatio() {
    return switch (_aspectLabel) {
      '9:16' => 9 / 16,
      '3:4' => 3 / 4,
      '1:1' => 1,
      '4:3' => 4 / 3,
      '16:9' => 16 / 9,
      _ => null,
    };
  }
}
