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
import '../product/auto_capture_controller.dart';
import '../product/composition_session.dart';
import '../product/saved_shot_history.dart';
import '../product/shot_mode_policy.dart';
import '../rules/composition_rules.dart';
import '../vision/vision_engine.dart';
import '../vision/vision_models.dart';

part 'widgets/bottom_controls.dart';
part 'widgets/camera_overlays.dart';
part 'widgets/composition_guides.dart';
part 'widgets/guide_debug_overlays.dart';
part 'widgets/settings_overlay.dart';
part 'widgets/settings_diagnostics.dart';
part 'widgets/sticker_effects.dart';
part 'widgets/photo_effect_processor.dart';
part 'widgets/tool_selection_overlay.dart';
part 'widgets/top_bar.dart';
part 'controllers/ui_overlay_controller.dart';
part 'controllers/settings_controller.dart';
part 'controllers/vision_controller.dart';
part 'controllers/camera_session_controller.dart';
part 'controllers/capture_controller.dart';
part 'controllers/composition_controller.dart';
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
  ShotMode _shotMode = ShotMode.portrait;
  ToolPanel _toolPanel = ToolPanel.none;
  StickerEffect _stickerEffect = StickerEffect.none;
  StyleEffect _styleEffect = StyleEffect.none;
  SetEffect _setEffect = SetEffect.none;
  RetouchEffect _retouchEffect = RetouchEffect.none;
  MediaMode _mediaMode = MediaMode.photo;
  final _CompositionController _composition = _CompositionController();
  FlashMode _flashMode = FlashMode.off;
  bool _autoCaptureEnabled = false;
  final _UiOverlayController _ui = _UiOverlayController();
  final _CameraSessionController _cameraSession = _CameraSessionController();
  bool get _isRecording => _cameraSession.isRecording;
  bool get _isBusy => _cameraSession.isBusy;
  bool get _isCameraSuspended => _cameraSession.isSuspended;
  bool get _isCameraOperationInFlight => _cameraSession.cameraOperationInFlight;
  set _isCameraOperationInFlight(bool value) =>
      _cameraSession.cameraOperationInFlight = value;
  _CameraSessionState get _session => _cameraSession.state;
  final _SettingsController _settings = _SettingsController();
  String get _aspectLabel => _settings.aspectLabel;
  set _aspectLabel(String value) => _settings.aspectLabel = value;
  ImageOutputFormat get _imageOutputFormat => _settings.imageOutputFormat;
  set _imageOutputFormat(ImageOutputFormat value) =>
      _settings.imageOutputFormat = value;
  ResolutionPreset get _resolutionPreset => _settings.resolutionPreset;
  set _resolutionPreset(ResolutionPreset value) =>
      _settings.resolutionPreset = value;
  int get _imageQuality => _settings.imageQuality;
  set _imageQuality(int value) => _settings.imageQuality = value;
  int get _videoFps => _settings.videoFps;
  set _videoFps(int value) => _settings.videoFps = value;
  int get _videoBitrate => _settings.videoBitrate;
  set _videoBitrate(int value) => _settings.videoBitrate = value;
  bool get _videoAudioEnabled => _settings.videoAudioEnabled;
  set _videoAudioEnabled(bool value) => _settings.videoAudioEnabled = value;
  Duration get _captureTimer => _settings.captureTimer;
  set _captureTimer(Duration value) => _settings.captureTimer = value;
  late final _CaptureController _capture;
  _CapturePipeline get _capturePipeline => _capture.pipeline;
  int? get _countdownSeconds => _capture.countdownSeconds;
  set _countdownSeconds(int? value) => _capture.countdownSeconds = value;
  double _zoom = 1;
  double _zoomAtScaleStart = 1;
  _ZoomModel _zoomModel = const _ZoomModel(min: 1, max: 10, current: 1);
  double get _minExposure => _SettingsController.minExposure;
  double get _maxExposure => _SettingsController.maxExposure;
  double get _exposure => _settings.exposure;
  set _exposure(double value) => _settings.exposure = value;
  int? get _manualIso => _settings.manualIso;
  set _manualIso(int? value) => _settings.manualIso = value;
  int? get _manualShutterNs => _settings.manualShutterNs;
  set _manualShutterNs(int? value) => _settings.manualShutterNs = value;
  String get _manualWhiteBalance => _settings.manualWhiteBalance;
  set _manualWhiteBalance(String value) => _settings.manualWhiteBalance = value;
  DateTime? get _lastShotAt => _capture.lastShotAt;
  set _lastShotAt(DateTime? value) => _capture.lastShotAt = value;
  DateTime? get _recordingStartedAt => _capture.recordingStartedAt;
  set _recordingStartedAt(DateTime? value) =>
      _capture.recordingStartedAt = value;
  Timer? _tickTimer;
  Timer? _thumbnailTimer;
  Timer? _focusTimer;
  Timer? _exposureGestureTimer;
  Timer? _recordingLimitTimer;
  StreamSubscription<dynamic>? _volumeSubscription;
  StreamSubscription<dynamic>? _analysisSubscription;
  final _VisionController _vision = _VisionController();
  _AnalysisPipeline get _analysisPipeline => _vision.analysisPipeline;
  VisionEngine get _visionEngine => _vision.engine;
  final AutoCaptureController _autoCaptureController = AutoCaptureController();
  final SavedShotHistoryStore _shotHistoryStore = const SavedShotHistoryStore();
  VisionFrameResult? get _visionResult => _vision.result;
  set _visionResult(VisionFrameResult? value) => _vision.result = value;
  _DeviceCapability get _deviceCapability => _vision.deviceCapability;
  set _deviceCapability(_DeviceCapability value) =>
      _vision.deviceCapability = value;
  _AiBenchmarkResult get _aiBenchmark => _vision.aiBenchmark;
  set _aiBenchmark(_AiBenchmarkResult value) => _vision.aiBenchmark = value;
  bool get _aiEnabled => _vision.aiEnabled;
  set _aiEnabled(bool value) => _vision.aiEnabled = value;
  String get _aiBlockedReason => _vision.aiBlockedReason;
  set _aiBlockedReason(String value) => _vision.aiBlockedReason = value;
  List<_NativeCameraSensor> get _nativeSensors => _cameraSession.nativeSensors;
  set _nativeSensors(List<_NativeCameraSensor> value) =>
      _cameraSession.nativeSensors = value;
  _NativeCameraState get _nativeState => _cameraSession.nativeState;
  set _nativeState(_NativeCameraState value) =>
      _cameraSession.nativeState = value;
  bool get _nativeCameraReady => _cameraSession.nativeCameraReady;
  set _nativeCameraReady(bool value) =>
      _cameraSession.nativeCameraReady = value;
  int? get _nativeTextureId => _cameraSession.nativeTextureId;
  set _nativeTextureId(int? value) => _cameraSession.nativeTextureId = value;
  String? get _nativeStandardSensorId => _cameraSession.nativeStandardSensorId;
  set _nativeStandardSensorId(String? value) =>
      _cameraSession.nativeStandardSensorId = value;
  String? get _nativeWideSensorId => _cameraSession.nativeWideSensorId;
  set _nativeWideSensorId(String? value) =>
      _cameraSession.nativeWideSensorId = value;
  String? get _nativeSelectedSensorId => _cameraSession.nativeSelectedSensorId;
  set _nativeSelectedSensorId(String? value) =>
      _cameraSession.nativeSelectedSensorId = value;
  int get _analysisFramesReceived => _vision.analysisFramesReceived;
  set _analysisFramesReceived(int value) =>
      _vision.analysisFramesReceived = value;
  DateTime? get _lastAnalysisFrameAt => _vision.lastAnalysisFrameAt;
  set _lastAnalysisFrameAt(DateTime? value) =>
      _vision.lastAnalysisFrameAt = value;
  DateTime? get _lastNativeStatePollAt => _cameraSession.lastNativeStatePollAt;
  set _lastNativeStatePollAt(DateTime? value) =>
      _cameraSession.lastNativeStatePollAt = value;

  @override
  void initState() {
    super.initState();
    _capture = _CaptureController(album: _albumName);
    WidgetsBinding.instance.addObserver(this);
    _restoreSettings().whenComplete(_initialize);
    _loadRules();
    _subscribeVolumeButtons();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      if (_visionResult == null || _isRecording) {
        setState(() {});
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
    _capture.dispose();
    unawaited(_NativeCameraBridge.stop());
    _vision.close();
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
    _cameraSession.setPhase(phase, message: message);
    if (message != null) {
      _status = message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = _composition.rulesFor(_shotMode);
    final viewportVisionResult = transformVisionForViewport(
      _visionResult,
      _previewAspectRatio(),
    );
    final liveEstimate = _estimateForShotMode(viewportVisionResult);
    final composition = _composition.evaluate(
      mode: _shotMode,
      liveEstimate: liveEstimate,
      hasReliableEstimate: _analysisPipeline.isReliable(liveEstimate),
    );

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
                  showGuides: _ui.showGuides,
                  showGrid: _ui.showGrid,
                  showScore: _ui.showScore,
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
                                        mode: _shotMode,
                                        visionResult: viewportVisionResult,
                                        estimate: composition.estimate,
                                      ),
                                    if (_ui.showGrid) const _RuleGrid(),
                                    if (_aiEnabled && _ui.showGuides)
                                      _CompositionGuideOverlay(
                                        mode: _shotMode,
                                        rules: rules,
                                        estimate: composition.estimate,
                                        visionResult: viewportVisionResult,
                                        ready: composition.ready,
                                      ),
                                    if (_aiEnabled && _ui.showScore)
                                      _ScoreBadge(
                                        cue: composition.cue,
                                        ready: composition.ready,
                                      ),
                                    if (_aiEnabled && _ui.showVisionDebug)
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
                                    if (_ui.focusPoint != null)
                                      _FocusReticle(point: _ui.focusPoint!),
                                    if (_ui.showExposureGesture)
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
                                    if (_ui.thumbnailPath != null)
                                      Positioned(
                                        left: 18,
                                        bottom: 18,
                                        child: _ShotThumbnail(
                                          path: _ui.thumbnailPath!,
                                          onTap: () async {
                                            _thumbnailTimer?.cancel();
                                            setState(_ui.clearThumbnail);
                                            await _openGallery();
                                          },
                                          isVideo: _ui.thumbnailIsVideo,
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
                    final nextMode = ShotModePolicy.normalizeVisibleMode(mode);
                    setState(() {
                      _shotMode = nextMode;
                      _autoCaptureController.reset();
                      if (!ShotModePolicy.canAutoCapture(nextMode)) {
                        _autoCaptureEnabled = false;
                        _status = 'Selfie face mode';
                      }
                    });
                    unawaited(_applyAnalysisModeForShotMode(nextMode));
                    unawaited(_saveSetting('shotMode', nextMode.name));
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
              flashMenuOpen: _ui.flashMenuOpen,
              aspectMenuOpen: _ui.aspectMenuOpen,
              settingsMenuOpen: false,
              aspectLabels: _aspectLabels,
              aspectLabel: _aspectLabel,
              flashMode: _flashMode,
              showGuides: _ui.showGuides,
              showGrid: _ui.showGrid,
              showScore: _ui.showScore,
              onFlashSelected: _setFlash,
              onAspectSelected: (label) => setState(() {
                _aspectLabel = label;
                _ui.aspectMenuOpen = false;
                unawaited(_saveSetting('aspectLabel', label));
              }),
              onToggleGuides: _toggleGuides,
              onToggleGrid: _toggleGrid,
              onToggleScore: _toggleScore,
            ),
            if (_ui.settingsMenuOpen)
              _CameraSettingsOverlay(
                showGuides: _ui.showGuides,
                showGrid: _ui.showGrid,
                showScore: _ui.showScore,
                showVisionDebug: _ui.showVisionDebug,
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
                onClose: () => setState(() => _ui.settingsMenuOpen = false),
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
