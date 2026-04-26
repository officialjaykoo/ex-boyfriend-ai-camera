// ignore_for_file: invalid_use_of_protected_member

part of 'package:exbf_camera/screens/camera_screen.dart';

extension _CaptureActions on _CameraScreenState {
  Future<void> _capturePhoto() async {
    if (_isCameraSuspended || _isBusy || _isCameraOperationInFlight) return;
    if (_captureTimer != Duration.zero && _countdownSeconds == null) {
      for (var seconds = _captureTimer.inSeconds; seconds > 0; seconds--) {
        if (!mounted) return;
        setState(() {
          _countdownSeconds = seconds;
          _status = 'Timer $seconds';
        });
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (mounted) setState(() => _countdownSeconds = null);
    }
    await _capturePhotoNow();
  }

  Future<void> _capturePhotoNow() async {
    if (_isBusy || _isCameraSuspended || !_nativeCameraReady) return;
    await _runCameraOperation(() async {
      if (!mounted || _isCameraSuspended || !_nativeCameraReady) return;
      setState(
        () => _setSession(_CameraSessionPhase.capturing, message: 'Saving'),
      );
      try {
        _lastShotAt = DateTime.now();
        final capturedPath = await _NativeCameraBridge.takePhoto();
        if (capturedPath == null || capturedPath.isEmpty) {
          throw StateError('Capture failed');
        }
        final savedPath = await _composeEditedPhoto(capturedPath);
        final galleryPath = await _capturePipeline.saveImage(savedPath);
        _showTemporaryThumbnail(galleryPath);
        setState(
          () => _setSession(_CameraSessionPhase.photoReady, message: 'Saved'),
        );
      } catch (error) {
        _capturePipeline.fail(error);
        setState(
          () => _setSession(
            _CameraSessionPhase.photoReady,
            message: 'Save error',
          ),
        );
      } finally {
        _capturePipeline.reset();
        if (mounted && !_session.isSuspended) {
          setState(
            () => _setSession(
              _mediaMode == MediaMode.video
                  ? _CameraSessionPhase.videoReady
                  : _CameraSessionPhase.photoReady,
            ),
          );
        }
      }
    });
  }

  Future<void> _toggleVideo() async {
    if (_isBusy || _isCameraSuspended || !_nativeCameraReady) return;
    await _runCameraOperation(() async {
      try {
        final state = await _NativeCameraBridge.toggleVideo();
        if (!mounted) return;
        setState(() {
          if (state == 'recording') {
            _recordingStartedAt = DateTime.now();
            _startRecordingSafetyTimer();
            _setSession(_CameraSessionPhase.recording, message: 'Recording');
          } else {
            _stopRecordingSafetyTimer();
            _recordingStartedAt = null;
            _setSession(
              _CameraSessionPhase.videoReady,
              message: 'Saving video',
            );
          }
        });
        if (state != 'recording') {
          final videoUri = await _waitForVideoFinalize();
          if (!mounted) return;
          if (videoUri != null && videoUri.isNotEmpty) {
            _showTemporaryThumbnail(videoUri, isVideo: true);
            setState(
              () => _setSession(
                _CameraSessionPhase.videoReady,
                message: 'Video saved',
              ),
            );
          } else {
            setState(
              () => _setSession(
                _CameraSessionPhase.videoReady,
                message: 'Video saved',
              ),
            );
          }
        }
      } catch (_) {
        if (!mounted) return;
        _stopRecordingSafetyTimer();
        setState(() {
          _recordingStartedAt = null;
          _setSession(_CameraSessionPhase.videoReady, message: 'Video error');
        });
      }
    });
  }

  void _startRecordingSafetyTimer() {
    _recordingLimitTimer?.cancel();
    _recordingLimitTimer = Timer(_CameraScreenState._maxVideoDuration, () {
      if (!mounted || !_isRecording || _isCameraOperationInFlight) return;
      setState(() => _status = 'Video limit reached');
      unawaited(_toggleVideo());
    });
  }

  void _stopRecordingSafetyTimer() {
    _recordingLimitTimer?.cancel();
    _recordingLimitTimer = null;
  }

  Future<String?> _waitForVideoFinalize() async {
    for (var attempt = 0; attempt < 12; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final state = await _NativeCameraBridge.getState();
      _nativeState = state;
      if (state.lastVideoError.isNotEmpty) return null;
      if (state.lastVideoUri.isNotEmpty && state.lastVideoBytes > 0) {
        return state.lastVideoUri;
      }
    }
    return null;
  }

  Future<void> _openGallery() async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await _CameraScreenState._galleryChannel.invokeMethod<void>(
        'openGallery',
      );
    } catch (_) {
      try {
        await Gal.open();
      } catch (_) {
        setState(() => _status = 'Gallery error');
      }
    }
  }

  void _maybeAutoCapture() {
    if (!_autoCaptureEnabled ||
        !_aiEnabled ||
        _mediaMode != MediaMode.photo ||
        _isBusy ||
        _isCameraSuspended) {
      return;
    }
    final now = DateTime.now();
    final lastAutoCheckAt = _lastAutoCheckAt;
    if (lastAutoCheckAt != null &&
        now.difference(lastAutoCheckAt).inMilliseconds < 1000) {
      return;
    }
    _lastAutoCheckAt = now;
    final rules = _rules[_shotMode]!;
    final estimate =
        _estimateForShotMode(
          transformVisionForViewport(_visionResult, _previewAspectRatio()),
        ) ??
        makePreviewEstimate(_tick);
    if (!_analysisPipeline.isReliable(estimate)) return;
    final result = scoreComposition(estimate, rules);
    if (!result.ready) return;
    final lastShotAt = _lastShotAt;
    if (lastShotAt != null &&
        now.difference(lastShotAt).inMilliseconds < 4500) {
      return;
    }
    _capturePhotoNow();
  }

  void _showTemporaryThumbnail(String path, {bool isVideo = false}) {
    _thumbnailTimer?.cancel();
    setState(() {
      _thumbnailPath = path;
      _thumbnailIsVideo = isVideo;
    });
    _thumbnailTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _thumbnailPath = null;
          _thumbnailIsVideo = false;
        });
      }
    });
  }
}
