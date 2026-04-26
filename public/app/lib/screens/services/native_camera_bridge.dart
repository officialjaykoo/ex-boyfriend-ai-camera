part of 'package:exbf_camera/screens/camera_screen.dart';

class _NativeCameraBridge {
  const _NativeCameraBridge._();

  static const _channel = MethodChannel('exbf_camera/native_camera');
  static const analysisStream = EventChannel('exbf_camera/native_analysis');

  static Future<List<_NativeCameraSensor>> getSensors() async {
    if (!Platform.isAndroid) return const [];
    final result = await _channel.invokeMethod<List<dynamic>>('getSensors');
    return (result ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(_NativeCameraSensor.fromMap)
        .toList(growable: false);
  }

  static Future<_DeviceCapability> getDeviceCapability() async {
    if (!Platform.isAndroid) return const _DeviceCapability.supported();
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getDeviceCapability',
    );
    return _DeviceCapability.fromMap(result ?? const {});
  }

  static Future<_AiBenchmarkResult> runAiBenchmark() async {
    if (!Platform.isAndroid) return const _AiBenchmarkResult.enabled();
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'runAiBenchmark',
    );
    return _AiBenchmarkResult.fromMap(result ?? const {});
  }

  static Future<void> setAiEnabled({
    required bool enabled,
    String? reason,
    String? delegate,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setAiEnabled', {
      'enabled': enabled,
      'reason': reason,
      'delegate': delegate,
    });
  }

  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('start');
  }

  static Future<_NativeCameraState> getState() async {
    if (!Platform.isAndroid) return const _NativeCameraState();
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getState',
    );
    return _NativeCameraState.fromMap(result ?? const {});
  }

  static Future<void> setCaptureMode(MediaMode mode) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setCaptureMode', {'mode': mode.name});
  }

  static Future<void> setAnalysisMode(String mode) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setAnalysisMode', {'mode': mode});
  }

  static Future<void> setResolution(ResolutionPreset preset) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setResolution', {'preset': preset.name});
  }

  static Future<int?> createPreviewTexture() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<int>('createPreviewTexture');
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('stop');
  }

  static Future<void> switchCamera() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('switchCamera');
  }

  static Future<void> setSensor(String id) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setSensor', {'id': id});
  }

  static Future<void> setZoom(double zoom) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setZoom', {'zoom': zoom});
  }

  static Future<void> setFlash(FlashMode mode) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setFlash', {'mode': mode.name});
  }

  static Future<void> setExposure(double value) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setExposure', {'value': value});
  }

  static Future<void> setManualControls({
    int? iso,
    int? exposureTimeNs,
    String whiteBalance = 'auto',
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setManualControls', {
      'iso': iso,
      'exposureTimeNs': exposureTimeNs,
      'whiteBalance': whiteBalance,
    });
  }

  static Future<void> setVideoOptions({
    required int fps,
    required int bitrate,
    required bool audio,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setVideoOptions', {
      'fps': fps,
      'bitrate': bitrate,
      'audio': audio,
    });
  }

  static Future<_NativeGallerySaveResult> saveImageToGallery({
    required String path,
    required String displayName,
    required String mimeType,
  }) async {
    if (!Platform.isAndroid) return _NativeGallerySaveResult.fallback(path);
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'saveImageToGallery',
      {'path': path, 'displayName': displayName, 'mimeType': mimeType},
    );
    return _NativeGallerySaveResult.fromMap(result ?? const {});
  }

  static Future<void> normalizeJpegExif(String path) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<Map<dynamic, dynamic>>('normalizeJpegExif', {
      'path': path,
    });
  }

  static Future<void> focus(Offset point) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('focus', {'x': point.dx, 'y': point.dy});
  }

  static Future<String?> takePhoto() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<String>('takePhoto');
  }

  static Future<String?> toggleVideo() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<String>('toggleVideo');
  }
}

class _NativeGallerySaveResult {
  const _NativeGallerySaveResult({
    required this.ok,
    required this.path,
    required this.uri,
    required this.bytes,
    required this.error,
  });

  factory _NativeGallerySaveResult.fallback(String path) {
    return _NativeGallerySaveResult(
      ok: true,
      path: path,
      uri: '',
      bytes: 0,
      error: '',
    );
  }

  final bool ok;
  final String path;
  final String uri;
  final int bytes;
  final String error;

  factory _NativeGallerySaveResult.fromMap(Map<dynamic, dynamic> map) {
    return _NativeGallerySaveResult(
      ok: map['ok'] == true,
      path: '${map['path'] ?? ''}',
      uri: '${map['uri'] ?? ''}',
      bytes: (map['bytes'] as num?)?.toInt() ?? 0,
      error: '${map['error'] ?? ''}',
    );
  }
}

extension _AiBenchmarkReadable on _AiBenchmarkResult {
  String get readableSummary {
    if (!aiEnabled) return blockedReason.isEmpty ? 'AI 비활성화' : blockedReason;
    final quality = grade == 'high' ? '고품질' : '표준';
    return 'AI $quality · $bestDelegate · ${averageMs}ms';
  }
}

extension _DeviceCapabilityReadable on _DeviceCapability {
  String get readableSummary {
    if (supported) {
      return '기기 검사 통과 · RAM ${totalRamGb.toStringAsFixed(1)}GB · Camera2 $camera2Level';
    }
    return failedReasons.join('\n');
  }
}

class _AiBenchmarkResult {
  const _AiBenchmarkResult({
    required this.aiEnabled,
    required this.bestDelegate,
    required this.averageMs,
    required this.grade,
    required this.blockedReason,
    required this.results,
  });

  const _AiBenchmarkResult.enabled()
    : aiEnabled = true,
      bestDelegate = 'CPU',
      averageMs = 0,
      grade = 'unknown',
      blockedReason = '',
      results = const [];

  final bool aiEnabled;
  final String bestDelegate;
  final int averageMs;
  final String grade;
  final String blockedReason;
  final List<_AiBenchmarkDelegateResult> results;

  String get summary {
    if (!aiEnabled) return blockedReason.isEmpty ? 'AI 비활성화' : blockedReason;
    final quality = grade == 'high' ? '고품질' : '표준';
    return 'AI $quality · $bestDelegate · ${averageMs}ms';
  }

  factory _AiBenchmarkResult.fromMap(Map<dynamic, dynamic> map) {
    return _AiBenchmarkResult(
      aiEnabled: map['aiEnabled'] == true,
      bestDelegate: '${map['bestDelegate'] ?? 'NONE'}',
      averageMs: (map['averageMs'] as num?)?.toInt() ?? 0,
      grade: '${map['grade'] ?? 'unknown'}',
      blockedReason: '${map['blockedReason'] ?? ''}',
      results: (map['results'] as List<dynamic>? ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(_AiBenchmarkDelegateResult.fromMap)
          .toList(growable: false),
    );
  }
}

class _AiBenchmarkDelegateResult {
  const _AiBenchmarkDelegateResult({
    required this.delegate,
    required this.ok,
    required this.averageMs,
    required this.error,
  });

  final String delegate;
  final bool ok;
  final int averageMs;
  final String error;

  factory _AiBenchmarkDelegateResult.fromMap(Map<dynamic, dynamic> map) {
    return _AiBenchmarkDelegateResult(
      delegate: '${map['delegate'] ?? 'unknown'}',
      ok: map['ok'] == true,
      averageMs: (map['averageMs'] as num?)?.toInt() ?? 0,
      error: '${map['error'] ?? ''}',
    );
  }
}

class _DeviceCapability {
  const _DeviceCapability({
    required this.supported,
    required this.failedReasons,
    required this.sdk,
    required this.minSdk,
    required this.totalRamBytes,
    required this.minRamBytes,
    required this.camera2Level,
    required this.chipset,
    required this.chipsetSupported,
    required this.chipsetKnownFast,
    required this.abi64,
    required this.nnapiAvailable,
    required this.gpuDelegateCandidate,
  });

  const _DeviceCapability.supported()
    : supported = true,
      failedReasons = const [],
      sdk = 0,
      minSdk = 0,
      totalRamBytes = 0,
      minRamBytes = 0,
      camera2Level = 'unknown',
      chipset = 'unknown',
      chipsetSupported = true,
      chipsetKnownFast = false,
      abi64 = 'unknown',
      nnapiAvailable = true,
      gpuDelegateCandidate = true;

  final bool supported;
  final List<String> failedReasons;
  final int sdk;
  final int minSdk;
  final int totalRamBytes;
  final int minRamBytes;
  final String camera2Level;
  final String chipset;
  final bool chipsetSupported;
  final bool chipsetKnownFast;
  final String abi64;
  final bool nnapiAvailable;
  final bool gpuDelegateCandidate;

  double get totalRamGb => totalRamBytes / 1000000000;

  String get summary {
    if (supported) {
      return '기기 검사 통과 · RAM ${totalRamGb.toStringAsFixed(1)}GB · Camera2 $camera2Level';
    }
    return failedReasons.join('\n');
  }

  factory _DeviceCapability.fromMap(Map<dynamic, dynamic> map) {
    return _DeviceCapability(
      supported: map['supported'] == true,
      failedReasons: (map['failedReasons'] as List<dynamic>? ?? const [])
          .map((reason) => reason.toString())
          .toList(growable: false),
      sdk: (map['sdk'] as num?)?.toInt() ?? 0,
      minSdk: (map['minSdk'] as num?)?.toInt() ?? 33,
      totalRamBytes: (map['totalRamBytes'] as num?)?.toInt() ?? 0,
      minRamBytes: (map['minRamBytes'] as num?)?.toInt() ?? 0,
      camera2Level: '${map['camera2Level'] ?? 'UNKNOWN'}',
      chipset: '${map['chipset'] ?? 'unknown'}',
      chipsetSupported: map['chipsetSupported'] == true,
      chipsetKnownFast: map['chipsetKnownFast'] == true,
      abi64: '${map['abi64'] ?? 'unknown'}',
      nnapiAvailable: map['nnapiAvailable'] == true,
      gpuDelegateCandidate: map['gpuDelegateCandidate'] == true,
    );
  }
}

class _NativeCameraState {
  const _NativeCameraState({
    this.ready = false,
    this.textureAttached = false,
    this.previewViewAttached = false,
    this.captureMode = 'photo',
    this.resolutionPreset = 'veryHigh',
    this.selectedCameraId,
    this.lensFacing = 'back',
    this.zoomRatio = 1,
    this.recording = false,
    this.imageCaptureReady = false,
    this.videoCaptureReady = false,
    this.analysisFrames = 0,
    this.analysisInputFrames = 0,
    this.analysisSkippedBusy = 0,
    this.analysisSkippedThrottle = 0,
    this.analysisFps = 0,
    this.analysisEnabled = false,
    this.analysisPolicy = 'unknown',
    this.analysisMode = 'full',
    this.aiEnabled = true,
    this.aiBlockedReason = '',
    this.lastAnalysisAt = 0,
    this.lastProcessingMs = 0,
    this.lastRotationDegrees = 0,
    this.nativeVisionReady = false,
    this.nativeVisionDelegate = 'unknown',
    this.uptimeMs = 0,
    this.bindCount = 0,
    this.bindFailureCount = 0,
    this.lastBindError = '',
    this.lastPhotoPath = '',
    this.lastPhotoBytes = 0,
    this.lastCaptureError = '',
    this.lastVideoUri = '',
    this.lastVideoError = '',
    this.lastVideoEvent = 'idle',
    this.lastVideoFinalizeAt = 0,
    this.lastVideoBytes = 0,
    this.lastVideoStatusBytes = 0,
    this.lastVideoStatusDurationMs = 0,
    this.videoRecordCount = 0,
    this.videoFinalizeCount = 0,
    this.lastVideoDurationMs = 0,
    this.usedMemoryMb = 0,
    this.maxMemoryMb = 0,
    this.thermalStatus = -1,
    this.manualIso,
    this.manualExposureTimeNs,
    this.manualWhiteBalance = 'auto',
    this.selectedSensor,
    this.targetFps = 30,
    this.targetVideoBitrate = 10000000,
    this.audioEnabled = true,
    this.lastFocusX = 0.5,
    this.lastFocusY = 0.5,
    this.lastFocusAt = 0,
    this.lastFocusResult = '',
    this.lastGalleryUri = '',
    this.lastGalleryError = '',
    this.lastCameraState = 'idle',
    this.lastCameraStateError = '',
  });

  final bool ready;
  final bool textureAttached;
  final bool previewViewAttached;
  final String captureMode;
  final String resolutionPreset;
  final String? selectedCameraId;
  final String lensFacing;
  final double zoomRatio;
  final bool recording;
  final bool imageCaptureReady;
  final bool videoCaptureReady;
  final int analysisFrames;
  final int analysisInputFrames;
  final int analysisSkippedBusy;
  final int analysisSkippedThrottle;
  final double analysisFps;
  final bool analysisEnabled;
  final String analysisPolicy;
  final String analysisMode;
  final bool aiEnabled;
  final String aiBlockedReason;
  final int lastAnalysisAt;
  final int lastProcessingMs;
  final int lastRotationDegrees;
  final bool nativeVisionReady;
  final String nativeVisionDelegate;
  final int uptimeMs;
  final int bindCount;
  final int bindFailureCount;
  final String lastBindError;
  final String lastPhotoPath;
  final int lastPhotoBytes;
  final String lastCaptureError;
  final String lastVideoUri;
  final String lastVideoError;
  final String lastVideoEvent;
  final int lastVideoFinalizeAt;
  final int lastVideoBytes;
  final int lastVideoStatusBytes;
  final int lastVideoStatusDurationMs;
  final int videoRecordCount;
  final int videoFinalizeCount;
  final int lastVideoDurationMs;
  final int usedMemoryMb;
  final int maxMemoryMb;
  final int thermalStatus;
  final int? manualIso;
  final int? manualExposureTimeNs;
  final String manualWhiteBalance;
  final _NativeSensorCapability? selectedSensor;
  final int targetFps;
  final int targetVideoBitrate;
  final bool audioEnabled;
  final double lastFocusX;
  final double lastFocusY;
  final int lastFocusAt;
  final String lastFocusResult;
  final String lastGalleryUri;
  final String lastGalleryError;
  final String lastCameraState;
  final String lastCameraStateError;

  bool get hasAnalysis => analysisFrames > 0;

  factory _NativeCameraState.fromMap(Map<dynamic, dynamic> map) {
    return _NativeCameraState(
      ready: map['ready'] == true,
      textureAttached: map['textureAttached'] == true,
      previewViewAttached: map['previewViewAttached'] == true,
      captureMode: '${map['captureMode'] ?? 'photo'}',
      resolutionPreset: '${map['resolutionPreset'] ?? 'veryHigh'}',
      selectedCameraId: map['selectedCameraId']?.toString(),
      lensFacing: '${map['lensFacing'] ?? 'back'}',
      zoomRatio: (map['zoomRatio'] as num?)?.toDouble() ?? 1,
      recording: map['recording'] == true,
      imageCaptureReady: map['imageCaptureReady'] == true,
      videoCaptureReady: map['videoCaptureReady'] == true,
      analysisFrames: (map['analysisFrames'] as num?)?.toInt() ?? 0,
      analysisInputFrames: (map['analysisInputFrames'] as num?)?.toInt() ?? 0,
      analysisSkippedBusy: (map['analysisSkippedBusy'] as num?)?.toInt() ?? 0,
      analysisSkippedThrottle:
          (map['analysisSkippedThrottle'] as num?)?.toInt() ?? 0,
      analysisFps: (map['analysisFps'] as num?)?.toDouble() ?? 0,
      analysisEnabled: map['analysisEnabled'] == true,
      analysisPolicy: '${map['analysisPolicy'] ?? 'unknown'}',
      analysisMode: '${map['analysisMode'] ?? 'full'}',
      aiEnabled: map['aiEnabled'] != false,
      aiBlockedReason: '${map['aiBlockedReason'] ?? ''}',
      lastAnalysisAt: (map['lastAnalysisAt'] as num?)?.toInt() ?? 0,
      lastProcessingMs: (map['lastProcessingMs'] as num?)?.toInt() ?? 0,
      lastRotationDegrees: (map['lastRotationDegrees'] as num?)?.toInt() ?? 0,
      nativeVisionReady: map['nativeVisionReady'] == true,
      nativeVisionDelegate: '${map['nativeVisionDelegate'] ?? 'unknown'}',
      uptimeMs: (map['uptimeMs'] as num?)?.toInt() ?? 0,
      bindCount: (map['bindCount'] as num?)?.toInt() ?? 0,
      bindFailureCount: (map['bindFailureCount'] as num?)?.toInt() ?? 0,
      lastBindError: '${map['lastBindError'] ?? ''}',
      lastPhotoPath: '${map['lastPhotoPath'] ?? ''}',
      lastPhotoBytes: (map['lastPhotoBytes'] as num?)?.toInt() ?? 0,
      lastCaptureError: '${map['lastCaptureError'] ?? ''}',
      lastVideoUri: '${map['lastVideoUri'] ?? ''}',
      lastVideoError: '${map['lastVideoError'] ?? ''}',
      lastVideoEvent: '${map['lastVideoEvent'] ?? 'idle'}',
      lastVideoFinalizeAt: (map['lastVideoFinalizeAt'] as num?)?.toInt() ?? 0,
      lastVideoBytes: (map['lastVideoBytes'] as num?)?.toInt() ?? 0,
      lastVideoStatusBytes: (map['lastVideoStatusBytes'] as num?)?.toInt() ?? 0,
      lastVideoStatusDurationMs:
          (map['lastVideoStatusDurationMs'] as num?)?.toInt() ?? 0,
      videoRecordCount: (map['videoRecordCount'] as num?)?.toInt() ?? 0,
      videoFinalizeCount: (map['videoFinalizeCount'] as num?)?.toInt() ?? 0,
      lastVideoDurationMs: (map['lastVideoDurationMs'] as num?)?.toInt() ?? 0,
      usedMemoryMb: (map['usedMemoryMb'] as num?)?.toInt() ?? 0,
      maxMemoryMb: (map['maxMemoryMb'] as num?)?.toInt() ?? 0,
      thermalStatus: (map['thermalStatus'] as num?)?.toInt() ?? -1,
      manualIso: (map['manualIso'] as num?)?.toInt(),
      manualExposureTimeNs: (map['manualExposureTimeNs'] as num?)?.toInt(),
      manualWhiteBalance: '${map['manualWhiteBalance'] ?? 'auto'}',
      selectedSensor: map['selectedSensor'] is Map<dynamic, dynamic>
          ? _NativeSensorCapability.fromMap(
              map['selectedSensor'] as Map<dynamic, dynamic>,
            )
          : null,
      targetFps: (map['targetFps'] as num?)?.toInt() ?? 30,
      targetVideoBitrate:
          (map['targetVideoBitrate'] as num?)?.toInt() ?? 10000000,
      audioEnabled: map['audioEnabled'] != false,
      lastFocusX: (map['lastFocusX'] as num?)?.toDouble() ?? 0.5,
      lastFocusY: (map['lastFocusY'] as num?)?.toDouble() ?? 0.5,
      lastFocusAt: (map['lastFocusAt'] as num?)?.toInt() ?? 0,
      lastFocusResult: '${map['lastFocusResult'] ?? ''}',
      lastGalleryUri: '${map['lastGalleryUri'] ?? ''}',
      lastGalleryError: '${map['lastGalleryError'] ?? ''}',
      lastCameraState: '${map['lastCameraState'] ?? 'idle'}',
      lastCameraStateError: '${map['lastCameraStateError'] ?? ''}',
    );
  }
}

class _NativeCameraSensor {
  const _NativeCameraSensor({
    required this.id,
    required this.position,
    required this.type,
    required this.flashAvailable,
    required this.isLogical,
    this.focalLength,
    this.equivalent35mm,
    this.hardwareLevel = 'UNKNOWN',
    this.manualSensor = false,
    this.manualPostProcessing = false,
    this.raw = false,
    this.minIso,
    this.maxIso,
    this.minExposureTimeNs,
    this.maxExposureTimeNs,
    this.minExposureCompensation,
    this.maxExposureCompensation,
    this.exposureCompensationStep,
    this.minZoomRatio,
    this.maxZoomRatio,
    this.maxDigitalZoom = 1,
    this.supportedFps = const [30],
    this.supportedResolutionPresets = const [
      ResolutionPreset.high,
      ResolutionPreset.veryHigh,
    ],
    this.maxJpegWidth,
    this.maxJpegHeight,
  });

  final String id;
  final String position;
  final String type;
  final bool flashAvailable;
  final bool isLogical;
  final double? focalLength;
  final double? equivalent35mm;
  final String hardwareLevel;
  final bool manualSensor;
  final bool manualPostProcessing;
  final bool raw;
  final int? minIso;
  final int? maxIso;
  final int? minExposureTimeNs;
  final int? maxExposureTimeNs;
  final int? minExposureCompensation;
  final int? maxExposureCompensation;
  final double? exposureCompensationStep;
  final double? minZoomRatio;
  final double? maxZoomRatio;
  final double maxDigitalZoom;
  final List<int> supportedFps;
  final List<ResolutionPreset> supportedResolutionPresets;
  final int? maxJpegWidth;
  final int? maxJpegHeight;

  bool get isBack => position == 'back';
  bool get isUltraWide => type == 'ultraWide';
  bool get isWide => type == 'wide' || type == 'logical';
  bool get isTelephoto => type == 'telephoto';

  factory _NativeCameraSensor.fromMap(Map<dynamic, dynamic> map) {
    return _NativeCameraSensor(
      id: '${map['id']}',
      position: '${map['position']}',
      type: '${map['type']}',
      flashAvailable: map['flashAvailable'] == true,
      isLogical: map['isLogical'] == true,
      focalLength: (map['focalLength'] as num?)?.toDouble(),
      equivalent35mm: (map['equivalent35mm'] as num?)?.toDouble(),
      hardwareLevel: '${map['hardwareLevel'] ?? 'UNKNOWN'}',
      manualSensor: map['manualSensor'] == true,
      manualPostProcessing: map['manualPostProcessing'] == true,
      raw: map['raw'] == true,
      minIso: (map['minIso'] as num?)?.toInt(),
      maxIso: (map['maxIso'] as num?)?.toInt(),
      minExposureTimeNs: (map['minExposureTimeNs'] as num?)?.toInt(),
      maxExposureTimeNs: (map['maxExposureTimeNs'] as num?)?.toInt(),
      minExposureCompensation: (map['minExposureCompensation'] as num?)
          ?.toInt(),
      maxExposureCompensation: (map['maxExposureCompensation'] as num?)
          ?.toInt(),
      exposureCompensationStep: (map['exposureCompensationStep'] as num?)
          ?.toDouble(),
      minZoomRatio: (map['minZoomRatio'] as num?)?.toDouble(),
      maxZoomRatio: (map['maxZoomRatio'] as num?)?.toDouble(),
      maxDigitalZoom: (map['maxDigitalZoom'] as num?)?.toDouble() ?? 1,
      supportedFps: _parseSupportedFps(map['supportedFps']),
      supportedResolutionPresets: _parseResolutionPresets(
        map['supportedResolutionPresets'],
      ),
      maxJpegWidth: (map['maxJpegWidth'] as num?)?.toInt(),
      maxJpegHeight: (map['maxJpegHeight'] as num?)?.toInt(),
    );
  }
}

class _NativeSensorCapability {
  const _NativeSensorCapability({
    required this.id,
    required this.hardwareLevel,
    this.minIso,
    this.maxIso,
    this.minExposureTimeNs,
    this.maxExposureTimeNs,
    this.minExposureCompensation,
    this.maxExposureCompensation,
    this.minZoomRatio,
    this.maxZoomRatio,
    this.maxDigitalZoom = 1,
    this.supportedFps = const [30],
    this.supportedResolutionPresets = const [
      ResolutionPreset.high,
      ResolutionPreset.veryHigh,
    ],
    this.maxJpegWidth,
    this.maxJpegHeight,
  });

  final String id;
  final String hardwareLevel;
  final int? minIso;
  final int? maxIso;
  final int? minExposureTimeNs;
  final int? maxExposureTimeNs;
  final int? minExposureCompensation;
  final int? maxExposureCompensation;
  final double? minZoomRatio;
  final double? maxZoomRatio;
  final double maxDigitalZoom;
  final List<int> supportedFps;
  final List<ResolutionPreset> supportedResolutionPresets;
  final int? maxJpegWidth;
  final int? maxJpegHeight;

  factory _NativeSensorCapability.fromMap(Map<dynamic, dynamic> map) {
    return _NativeSensorCapability(
      id: '${map['id'] ?? ''}',
      hardwareLevel: '${map['hardwareLevel'] ?? 'UNKNOWN'}',
      minIso: (map['minIso'] as num?)?.toInt(),
      maxIso: (map['maxIso'] as num?)?.toInt(),
      minExposureTimeNs: (map['minExposureTimeNs'] as num?)?.toInt(),
      maxExposureTimeNs: (map['maxExposureTimeNs'] as num?)?.toInt(),
      minExposureCompensation: (map['minExposureCompensation'] as num?)
          ?.toInt(),
      maxExposureCompensation: (map['maxExposureCompensation'] as num?)
          ?.toInt(),
      minZoomRatio: (map['minZoomRatio'] as num?)?.toDouble(),
      maxZoomRatio: (map['maxZoomRatio'] as num?)?.toDouble(),
      maxDigitalZoom: (map['maxDigitalZoom'] as num?)?.toDouble() ?? 1,
      supportedFps: _parseSupportedFps(map['supportedFps']),
      supportedResolutionPresets: _parseResolutionPresets(
        map['supportedResolutionPresets'],
      ),
      maxJpegWidth: (map['maxJpegWidth'] as num?)?.toInt(),
      maxJpegHeight: (map['maxJpegHeight'] as num?)?.toInt(),
    );
  }
}

List<int> _parseSupportedFps(Object? value) {
  final parsed =
      (value as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((fps) => fps.toInt())
          .where((fps) => fps == 24 || fps == 30 || fps == 60)
          .toSet()
          .toList()
        ..sort();
  return parsed.isEmpty ? const [30] : parsed;
}

List<ResolutionPreset> _parseResolutionPresets(Object? value) {
  final parsed = (value as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .map((name) => _resolutionPresetByName(name))
      .whereType<ResolutionPreset>()
      .toSet()
      .toList();
  return parsed.isEmpty
      ? const [ResolutionPreset.high, ResolutionPreset.veryHigh]
      : parsed;
}

ResolutionPreset? _resolutionPresetByName(String name) {
  for (final preset in ResolutionPreset.values) {
    if (preset.name == name) return preset;
  }
  return null;
}
