import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/composition_engine.dart';
import '../engine/vision_composition_adapter.dart';
import '../models/camera_modes.dart';
import '../rules/composition_rules.dart';
import '../vision/vision_engine.dart';
import '../vision/vision_models.dart';

part 'widgets/bottom_controls.dart';
part 'widgets/camera_overlays.dart';
part 'widgets/composition_guides.dart';
part 'widgets/settings_overlay.dart';
part 'widgets/sticker_effects.dart';
part 'widgets/tool_selection_overlay.dart';
part 'widgets/top_bar.dart';
part 'services/camera_controls.dart';
part 'services/camera_lifecycle.dart';
part 'services/native_camera_bridge.dart';
part 'services/camera_runtime.dart';
part 'services/camera_settings_store.dart';
part 'services/capture_actions.dart';
part 'services/photo_composer.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static const _aspectLabels = ['FULL', '9:16', '3:4', '1:1', '4:3', '16:9'];
  static const _galleryChannel = MethodChannel('exbf_camera/gallery');
  static const _volumeChannel = EventChannel('exbf_camera/volume_keydown');
  static const _settingsPrefix = 'exbf.camera.';
  static const _albumName = 'Ex-Boyfriend Camera';
  static const _maxVideoDuration = Duration(minutes: 10);
  static const _toolOptions = {
    ToolPanel.sticker: ['Smile', 'Heart', 'Date'],
    ToolPanel.style: ['Vivid', 'Warm', 'Cool', 'Film', 'Mono'],
    ToolPanel.set: ['Solo', 'Cafe', 'Travel', 'Food', 'Night'],
    ToolPanel.retouch: ['Skin', 'Bright', 'Jaw', 'Eyes', 'Nose'],
  };

  String _status = 'Camera ready';
  String _aspectLabel = '3:4';
  ShotMode _shotMode = ShotMode.portrait;
  ToolPanel _toolPanel = ToolPanel.none;
  StickerEffect _stickerEffect = StickerEffect.none;
  StyleEffect _styleEffect = StyleEffect.none;
  SetEffect _setEffect = SetEffect.none;
  RetouchEffect _retouchEffect = RetouchEffect.none;
  ImageOutputFormat _imageOutputFormat = ImageOutputFormat.jpg;
  MediaMode _mediaMode = MediaMode.photo;
  Map<ShotMode, CompositionRuleSet> _rules = compositionRules;
  FlashMode _flashMode = FlashMode.off;
  bool _autoCaptureEnabled = false;
  bool _showGrid = false;
  bool _showGuides = true;
  bool _showScore = true;
  bool _showVisionDebug = false;
  bool _aspectMenuOpen = false;
  bool _flashMenuOpen = false;
  bool _settingsMenuOpen = false;
  ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;
  bool _isRecording = false;
  bool _isBusy = false;
  bool _isCameraSuspended = false;
  bool _isCameraOperationInFlight = false;
  _CameraSessionState _session = const _CameraSessionState(
    _CameraSessionPhase.preparing,
    message: 'Camera ready',
  );
  int _imageQuality = 95;
  int _videoFps = 30;
  int _videoBitrate = 10000000;
  bool _videoAudioEnabled = true;
  Duration _captureTimer = Duration.zero;
  int? _countdownSeconds;
  Offset? _focusPoint;
  bool _showExposureGesture = false;
  double _zoom = 1;
  double _zoomAtScaleStart = 1;
  _ZoomModel _zoomModel = const _ZoomModel(min: 1, max: 10, current: 1);
  final double _minExposure = -3;
  final double _maxExposure = 3;
  double _exposure = 0;
  int? _manualIso;
  int? _manualShutterNs;
  String _manualWhiteBalance = 'auto';
  int _tick = 0;
  DateTime? _lastShotAt;
  DateTime? _lastAutoCheckAt;
  DateTime? _recordingStartedAt;
  String? _thumbnailPath;
  bool _thumbnailIsVideo = false;
  Timer? _tickTimer;
  Timer? _thumbnailTimer;
  Timer? _focusTimer;
  Timer? _exposureGestureTimer;
  Timer? _recordingLimitTimer;
  StreamSubscription<dynamic>? _volumeSubscription;
  StreamSubscription<dynamic>? _analysisSubscription;
  late final _CapturePipeline _capturePipeline;
  final _AnalysisPipeline _analysisPipeline = _AnalysisPipeline(
    minFrameGap: const Duration(milliseconds: 240),
    minSubjectConfidence: 0.25,
    minPoseConfidence: 0.25,
  );
  final VisionEngine _visionEngine = VisionEngine();
  VisionFrameResult? _visionResult;
  _DeviceCapability _deviceCapability = const _DeviceCapability.supported();
  _AiBenchmarkResult _aiBenchmark = const _AiBenchmarkResult.enabled();
  bool _aiEnabled = true;
  String _aiBlockedReason = '';
  List<_NativeCameraSensor> _nativeSensors = [];
  _NativeCameraState _nativeState = const _NativeCameraState();
  bool _nativeCameraReady = false;
  int? _nativeTextureId;
  String? _nativeStandardSensorId;
  String? _nativeWideSensorId;
  String? _nativeSelectedSensorId;
  int _analysisFramesReceived = 0;
  DateTime? _lastAnalysisFrameAt;
  DateTime? _lastNativeStatePollAt;

  @override
  void initState() {
    super.initState();
    _capturePipeline = _CapturePipeline(album: _albumName);
    WidgetsBinding.instance.addObserver(this);
    _restoreSettings().whenComplete(_initialize);
    _loadRules();
    _subscribeVolumeButtons();
    final started = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      if (_visionResult == null) {
        setState(
          () => _tick = DateTime.now().difference(started).inMilliseconds,
        );
      } else if (_isRecording) {
        setState(
          () => _tick = DateTime.now().difference(started).inMilliseconds,
        );
      }
      final now = DateTime.now();
      final lastPoll = _lastNativeStatePollAt;
      if (lastPoll == null || now.difference(lastPoll).inSeconds >= 2) {
        _lastNativeStatePollAt = now;
        unawaited(_refreshNativeState());
      }
      _maybeAutoCapture();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _thumbnailTimer?.cancel();
    _focusTimer?.cancel();
    _exposureGestureTimer?.cancel();
    _recordingLimitTimer?.cancel();
    _volumeSubscription?.cancel();
    _analysisSubscription?.cancel();
    _capturePipeline.dispose();
    unawaited(_NativeCameraBridge.stop());
    _visionEngine.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _suspendCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  void _setSession(_CameraSessionPhase phase, {String? message}) {
    _session = _session.copyWith(phase: phase, message: message);
    _isBusy = _session.isBusy;
    _isRecording = _session.isRecording;
    _isCameraSuspended = _session.isSuspended;
    if (message != null) {
      _status = message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules[_shotMode]!;
    final viewportVisionResult = transformVisionForViewport(
      _visionResult,
      _previewAspectRatio(),
    );
    final estimate =
        _estimateForShotMode(viewportVisionResult) ??
        makePreviewEstimate(_tick);
    final result = scoreComposition(estimate, rules);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopToolbar(
                  aspectLabel: _aspectLabel,
                  flashMode: _flashMode,
                  autoCaptureEnabled: _autoCaptureEnabled,
                  onAutoCaptureToggle: _toggleAutoCapture,
                  onFlashTap: () => _toggleTopMenu('flash'),
                  onAspectTap: () => _toggleTopMenu('aspect'),
                  onSettingsTap: () => _toggleTopMenu('settings'),
                  showGuides: _showGuides,
                  showGrid: _showGrid,
                  showScore: _showScore,
                  onSwitchCamera: _switchCamera,
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: _CameraViewport(
                        aspectRatio: _previewAspectRatio(),
                        child: !_nativeCameraReady
                            ? _LoadingPreview(status: _status)
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) =>
                                    _focusAt(details, context),
                                onScaleStart: (_) {
                                  _zoomAtScaleStart = _zoom;
                                },
                                onScaleUpdate: (details) {
                                  if (details.pointerCount >= 2) {
                                    if ((details.scale - 1).abs() < 0.02) {
                                      return;
                                    }
                                    _setZoom(_zoomAtScaleStart * details.scale);
                                    return;
                                  }
                                  if (details.pointerCount == 1 &&
                                      details.focalPointDelta.dy.abs() >
                                          details.focalPointDelta.dx.abs()) {
                                    _adjustExposureByDrag(
                                      details.focalPointDelta.dy,
                                    );
                                  }
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_nativeTextureId != null)
                                      _FilteredCameraPreview(
                                        textureId: _nativeTextureId!,
                                        style: _styleEffect,
                                        set: _setEffect,
                                        retouch: _retouchEffect,
                                      ),
                                    _EffectPreviewOverlay(
                                      style: _styleEffect,
                                      set: _setEffect,
                                      retouch: _retouchEffect,
                                    ),
                                    if (_stickerEffect != StickerEffect.none)
                                      _StickerOverlay(
                                        sticker: _stickerEffect,
                                        visionResult: viewportVisionResult,
                                        estimate: estimate,
                                      ),
                                    if (_showGrid) const _RuleGrid(),
                                    if (_aiEnabled && _showGuides)
                                      _CompositionGuideOverlay(
                                        mode: _shotMode,
                                        rules: rules,
                                        estimate: estimate,
                                        visionResult: viewportVisionResult,
                                        ready: result.ready,
                                      ),
                                    if (_aiEnabled && _showScore)
                                      _ScoreBadge(
                                        cue: result.cue,
                                        ready: result.ready,
                                      ),
                                    if (_aiEnabled && _showVisionDebug)
                                      _VisionDebugOverlay(
                                        result: viewportVisionResult,
                                      ),
                                    if (_countdownSeconds != null)
                                      _CountdownBadge(
                                        seconds: _countdownSeconds!,
                                      ),
                                    if (_isRecording &&
                                        _recordingStartedAt != null)
                                      _RecordingTimerBadge(
                                        startedAt: _recordingStartedAt!,
                                      ),
                                    if (_focusPoint != null)
                                      _FocusReticle(point: _focusPoint!),
                                    if (_showExposureGesture)
                                      _ExposureGestureBadge(
                                        exposure: _exposure,
                                      ),
                                    if (_shotMode == ShotMode.lowLight)
                                      const Positioned(
                                        left: 14,
                                        top: 62,
                                        child: _NightFloatIcon(),
                                      ),
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: _ZoomBadge(
                                        zoom: _zoom,
                                        onTap: _cycleZoom,
                                      ),
                                    ),
                                    if (_thumbnailPath != null)
                                      Positioned(
                                        left: 18,
                                        bottom: 18,
                                        child: _ShotThumbnail(
                                          path: _thumbnailPath!,
                                          onTap: () async {
                                            _thumbnailTimer?.cancel();
                                            setState(() {
                                              _thumbnailPath = null;
                                              _thumbnailIsVideo = false;
                                            });
                                            await _openGallery();
                                          },
                                          isVideo: _thumbnailIsVideo,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                _BottomControls(
                  shotMode: _shotMode,
                  mediaMode: _mediaMode,
                  toolPanel: _toolPanel,
                  isRecording: _isRecording,
                  isBusy: _isBusy,
                  onShotModeChanged: (mode) {
                    setState(() {
                      _shotMode = mode;
                      if (mode == ShotMode.selfie) {
                        _autoCaptureEnabled = false;
                        _status = 'Selfie face mode';
                      }
                    });
                    unawaited(_applyAnalysisModeForShotMode(mode));
                    unawaited(_saveSetting('shotMode', mode.name));
                  },
                  onMediaModeChanged: _setMediaMode,
                  onToolSelected: _toggleToolPanel,
                  onGalleryTap: _openGallery,
                  onShutterTap: _mediaMode == MediaMode.video
                      ? _toggleVideo
                      : _capturePhoto,
                ),
              ],
            ),
            _TopFloatingMenus(
              flashMenuOpen: _flashMenuOpen,
              aspectMenuOpen: _aspectMenuOpen,
              settingsMenuOpen: false,
              aspectLabels: _aspectLabels,
              aspectLabel: _aspectLabel,
              flashMode: _flashMode,
              showGuides: _showGuides,
              showGrid: _showGrid,
              showScore: _showScore,
              onFlashSelected: _setFlash,
              onAspectSelected: (label) => setState(() {
                _aspectLabel = label;
                _aspectMenuOpen = false;
                unawaited(_saveSetting('aspectLabel', label));
              }),
              onToggleGuides: _toggleGuides,
              onToggleGrid: _toggleGrid,
              onToggleScore: _toggleScore,
            ),
            if (_settingsMenuOpen)
              _CameraSettingsOverlay(
                showGuides: _showGuides,
                showGrid: _showGrid,
                showScore: _showScore,
                showVisionDebug: _showVisionDebug,
                captureTimer: _captureTimer,
                exposure: _exposure,
                minExposure: _minExposure,
                maxExposure: _maxExposure,
                imageOutputFormat: _imageOutputFormat,
                imageQuality: _imageQuality,
                videoFps: _videoFps,
                videoBitrate: _videoBitrate,
                videoAudioEnabled: _videoAudioEnabled,
                resolutionPreset: _resolutionPreset,
                supportedResolutionPresets: _supportedResolutionPresets,
                manualIso: _manualIso,
                manualShutterNs: _manualShutterNs,
                manualWhiteBalance: _manualWhiteBalance,
                nativeState: _nativeState,
                deviceCapability: _deviceCapability,
                aiBenchmark: _aiBenchmark,
                aiEnabled: _aiEnabled,
                aiBlockedReason: _aiBlockedReason,
                analysisFramesReceived: _analysisFramesReceived,
                lastAnalysisFrameAt: _lastAnalysisFrameAt,
                nativeSensorCount: _nativeSensors.length,
                onToggleGuides: _toggleGuides,
                onToggleGrid: _toggleGrid,
                onToggleScore: _toggleScore,
                onToggleVisionDebug: _toggleVisionDebug,
                onTimerTap: _cycleCaptureTimer,
                onExposureChanged: _setExposure,
                onImageFormatSelected: _setImageOutputFormat,
                onImageQualityTap: _cycleImageQuality,
                onVideoFpsTap: _cycleVideoFps,
                onVideoBitrateTap: _cycleVideoBitrate,
                onVideoAudioToggle: _toggleVideoAudio,
                onResolutionSelected: _setResolution,
                onManualIsoSelected: _setManualIso,
                onManualShutterSelected: _setManualShutter,
                onWhiteBalanceSelected: _setWhiteBalance,
                onClose: () => setState(() => _settingsMenuOpen = false),
              ),
            if (_toolPanel != ToolPanel.none)
              _ToolSelectionOverlay(
                panel: _toolPanel,
                options: _toolOptions[_toolPanel]!,
                selectedSticker: _stickerEffect,
                selectedStyle: _styleEffect,
                selectedSet: _setEffect,
                selectedRetouch: _retouchEffect,
                onStickerSelected: (sticker) =>
                    setState(() => _stickerEffect = sticker),
                onStyleSelected: (style) =>
                    setState(() => _styleEffect = style),
                onSetSelected: (set) => setState(() => _setEffect = set),
                onRetouchSelected: (retouch) =>
                    setState(() => _retouchEffect = retouch),
                onClose: () => setState(() => _toolPanel = ToolPanel.none),
              ),
          ],
        ),
      ),
    );
  }
}
