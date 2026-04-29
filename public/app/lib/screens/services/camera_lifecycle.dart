// ignore_for_file: invalid_use_of_protected_member

part of 'package:exbf_camera/screens/camera_screen.dart';

extension _CameraLifecycle on _CameraScreenState {
  void _subscribeVolumeButtons() {
    _volumeSubscription = _CameraScreenState._volumeChannel
        .receiveBroadcastStream()
        .listen((_) {
          if (_isBusy) return;
          if (_ui.mediaMode == MediaMode.video) {
            _toggleVideo();
          } else {
            _capturePhoto();
          }
        }, onError: (_) {});
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(
        () => _setSession(
          _CameraSessionPhase.preparing,
          message: 'Camera loading',
        ),
      );
    }
    final cameraStatus = await Permission.camera.request();
    await Permission.microphone.request();
    if (!cameraStatus.isGranted) {
      if (mounted) {
        setState(
          () => _setSession(
            _CameraSessionPhase.error,
            message: 'Camera permission needed',
          ),
        );
      }
      return;
    }

    try {
      _deviceCapability = await _NativeCameraBridge.getDeviceCapability();
      if (!_deviceCapability.supported) {
        _vision.blockAi(_deviceCapability.readableSummary);
        await _NativeCameraBridge.setAiEnabled(
          enabled: false,
          reason: _aiBlockedReason,
        );
      } else {
        await _NativeCameraBridge.setAiEnabled(
          enabled: false,
          reason: 'Camera first start',
        );
      }
      _nativeSensors = await _NativeCameraBridge.getSensors();
      _configureNativeSensors();
      _nativeTextureId = await _NativeCameraBridge.createPreviewTexture();
      await _NativeCameraBridge.setResolution(_resolutionPreset);
      await _NativeCameraBridge.setCaptureMode(_ui.mediaMode);
      await _applyAnalysisModeForShotMode(_shotMode);
      await _NativeCameraBridge.setVideoOptions(
        fps: _videoFps,
        bitrate: _videoBitrate,
        audio: _videoAudioEnabled,
      );
      await _NativeCameraBridge.start();
      _nativeState = await _NativeCameraBridge.getState();
      if (!mounted) return;
      setState(() {
        _nativeCameraReady = true;
        _setSession(
          _ui.mediaMode == MediaMode.video
              ? _CameraSessionPhase.videoReady
              : _CameraSessionPhase.photoReady,
          message: 'CameraX ready',
        );
      });
      await _syncCameraFacingForShotMode(_shotMode);
      if (!mounted) return;
      if (_deviceCapability.supported) {
        unawaited(_prepareAiAfterCameraStart());
      } else {
        _analysisSubscription?.cancel();
        _vision.clearResult();
        if (mounted) setState(() => _status = 'Camera only');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _setSession(_CameraSessionPhase.error, message: 'Camera error'),
        );
      }
    }
  }

  Future<void> _prepareAiAfterCameraStart() async {
    try {
      final cachedBenchmark = await _restoreAiBenchmark();
      if (cachedBenchmark != null) {
        _vision.applyBenchmark(cachedBenchmark);
      } else {
        if (mounted) setState(() => _status = 'AI benchmark');
        _vision.applyBenchmark(await _NativeCameraBridge.runAiBenchmark());
        unawaited(_saveAiBenchmark(_aiBenchmark));
      }
      await _NativeCameraBridge.setAiEnabled(
        enabled: _aiBenchmark.aiEnabled,
        reason: _aiBenchmark.blockedReason,
        delegate: _aiBenchmark.bestDelegate,
      );
      await _applyAnalysisModeForShotMode(_shotMode);
      if (_aiEnabled) {
        await _loadVisionEngine();
        _startNativeAnalysis();
        if (mounted) setState(() => _status = 'AI connected');
      } else {
        _analysisSubscription?.cancel();
        _vision.clearResult();
        if (mounted) setState(() => _status = 'Camera only');
      }
      await _refreshNativeState();
    } catch (_) {
      _vision.blockAi('AI start failed');
      await _NativeCameraBridge.setAiEnabled(
        enabled: false,
        reason: _aiBlockedReason,
      );
      if (mounted) setState(() => _status = 'Camera only');
    }
  }

  Future<_AiBenchmarkResult?> _restoreAiBenchmark() async {
    return _vision.restoreBenchmark(prefix: _CameraScreenState._settingsPrefix);
  }

  Future<void> _saveAiBenchmark(_AiBenchmarkResult result) async {
    await _vision.saveBenchmark(
      prefix: _CameraScreenState._settingsPrefix,
      result: result,
    );
  }

  void _startNativeAnalysis() {
    _analysisSubscription?.cancel();
    _analysisSubscription = _NativeCameraBridge.analysisStream
        .receiveBroadcastStream()
        .listen((event) async {
          if (!mounted || _isCameraSuspended || _isBusy) return;
          if (!_vision.shouldAnalyzeNow()) return;
          try {
            final VisionFrameResult result;
            if (event is Map<dynamic, dynamic>) {
              result = VisionFrameResult.fromNativeMap(event);
            } else {
              final bytes = event is Uint8List
                  ? event
                  : Uint8List.fromList((event as List<dynamic>).cast<int>());
              final frame = img.decodeImage(bytes);
              if (frame == null) return;
              result = await _visionEngine.analyzeImage(frame);
            }
            if (!mounted || _isCameraSuspended) return;
            setState(() {
              _vision.acceptAnalysisResult(result);
              if (_status == 'CameraX ready' || _status == 'AI ready') {
                _status = 'AI connected';
              }
            });
          } catch (_) {
            if (mounted) setState(() => _status = 'AI analyze error');
          } finally {
            _vision.completeAnalysis();
          }
        });
  }

  Future<void> _loadRules() async {
    try {
      final document = await loadCompositionRuleDocumentFromAsset();
      if (!mounted) return;
      setState(
        () => _composition.rules = {...compositionRules, ...document.modes},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Rules error');
    }
  }

  Future<void> _loadVisionEngine() async {
    if (Platform.isAndroid) {
      setState(() => _status = 'Native AI ready');
      return;
    }
    try {
      setState(() => _status = 'AI loading');
      await _visionEngine.load();
      if (!mounted) return;
      setState(() {
        _status = 'AI ready';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'AI load error';
      });
    }
  }

  Future<void> _suspendCamera() async {
    if (_isCameraSuspended) return;
    _thumbnailTimer?.cancel();
    _focusTimer?.cancel();
    _exposureGestureTimer?.cancel();
    _recordingLimitTimer?.cancel();
    _setSession(_CameraSessionPhase.suspended, message: 'Camera paused');
    _recordingStartedAt = null;
    _ui.clearTransientOverlays();
    _vision.resetPipeline();
    _analysisSubscription?.pause();
    await _NativeCameraBridge.stop();
    _nativeCameraReady = false;
    if (mounted) setState(() {});
  }

  Future<void> _resumeCamera() async {
    if (!_isCameraSuspended) return;
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      if (mounted) {
        setState(
          () => _setSession(
            _CameraSessionPhase.error,
            message: 'Camera permission needed',
          ),
        );
      }
      return;
    }
    if (mounted) {
      setState(
        () => _setSession(
          _CameraSessionPhase.preparing,
          message: 'Camera loading',
        ),
      );
    }
    _analysisSubscription?.resume();
    await _NativeCameraBridge.setResolution(_resolutionPreset);
    await _NativeCameraBridge.setCaptureMode(_ui.mediaMode);
    await _applyAnalysisModeForShotMode(_shotMode);
    await _NativeCameraBridge.setVideoOptions(
      fps: _videoFps,
      bitrate: _videoBitrate,
      audio: _videoAudioEnabled,
    );
    await _NativeCameraBridge.start();
    await _refreshNativeState();
    if (!mounted) return;
    setState(() {
      _nativeCameraReady = true;
      _setSession(
        _ui.mediaMode == MediaMode.video
            ? _CameraSessionPhase.videoReady
            : _CameraSessionPhase.photoReady,
        message: 'CameraX ready',
      );
    });
  }

  void _configureNativeSensors() {
    final backSensors = _nativeSensors.where((sensor) => sensor.isBack);
    _NativeCameraSensor? firstWhereOrNull(
      Iterable<_NativeCameraSensor> sensors,
      bool Function(_NativeCameraSensor sensor) test,
    ) {
      for (final sensor in sensors) {
        if (test(sensor)) return sensor;
      }
      return null;
    }

    final standard = firstWhereOrNull(backSensors, (sensor) => sensor.isWide);
    final ultraWide = firstWhereOrNull(
      backSensors,
      (sensor) => sensor.isUltraWide,
    );
    _nativeStandardSensorId = standard?.id;
    _nativeWideSensorId = ultraWide?.id;
    _nativeSelectedSensorId = _nativeStandardSensorId ?? _nativeWideSensorId;
    final maxZoom = standard?.maxZoomRatio ?? standard?.maxDigitalZoom ?? 10;
    _zoomModel = _zoomModel.copyWith(max: math.max(3, maxZoom), current: _zoom);
    if (!_supportedResolutionPresets.contains(_resolutionPreset)) {
      _resolutionPreset =
          _supportedResolutionPresets.contains(ResolutionPreset.veryHigh)
          ? ResolutionPreset.veryHigh
          : _supportedResolutionPresets.first;
    }
    if (!_supportedVideoFps.contains(_videoFps)) {
      _videoFps = _supportedVideoFps.contains(30)
          ? 30
          : _supportedVideoFps.first;
    }
    if (_nativeSelectedSensorId != null) {
      unawaited(_NativeCameraBridge.setSensor(_nativeSelectedSensorId!));
    }
  }

  Future<void> _refreshNativeState() async {
    if (!mounted || !Platform.isAndroid) return;
    try {
      final state = await _NativeCameraBridge.getState();
      if (!mounted) return;
      setState(() => _nativeState = state);
    } catch (_) {
      // Diagnostics must never interrupt the camera.
    }
  }
}
