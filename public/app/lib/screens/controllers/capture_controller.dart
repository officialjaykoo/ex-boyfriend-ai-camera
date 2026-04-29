part of 'package:exbf_camera/screens/camera_screen.dart';

class _CaptureController {
  _CaptureController({required String album})
    : pipeline = _CapturePipeline(album: album);

  final _CapturePipeline pipeline;
  final SavedShotHistoryStore historyStore = const SavedShotHistoryStore();
  DateTime? lastShotAt;
  DateTime? recordingStartedAt;
  int? countdownSeconds;

  bool canStartCapture({
    required bool isBusy,
    required bool isCameraSuspended,
    required bool isCameraOperationInFlight,
  }) {
    return !isCameraSuspended && !isBusy && !isCameraOperationInFlight;
  }

  bool canTakePhotoNow({
    required bool isBusy,
    required bool isCameraSuspended,
    required bool nativeCameraReady,
  }) {
    return !isBusy && !isCameraSuspended && nativeCameraReady;
  }

  DateTime markShotStarted() {
    final capturedAt = DateTime.now();
    lastShotAt = capturedAt;
    return capturedAt;
  }

  void markRecordingStarted() {
    recordingStartedAt = DateTime.now();
  }

  void markRecordingStopped() {
    recordingStartedAt = null;
  }

  Future<void> recordSavedShot({
    required String path,
    required ShotMode shotMode,
    required CompositionSession composition,
    required bool autoCaptured,
  }) async {
    final capturedAt = lastShotAt ?? DateTime.now();
    final estimate = composition.estimate;
    await historyStore.add(
      SavedShotRecord(
        id: '${capturedAt.microsecondsSinceEpoch}_${shotMode.name}',
        path: path,
        shotMode: shotMode,
        capturedAt: capturedAt,
        compositionScore: composition.result?.score,
        compositionCue: composition.cue,
        hadReliableEstimate: composition.hasReliableEstimate,
        bodyCenterX: estimate.bodyCenterX,
        faceCenterY: estimate.faceCenterY,
        eyeLineY: estimate.eyeLineY,
        footLineY: estimate.footLineY,
        horizonTiltDeg: estimate.horizonTiltDeg,
        subjectConfidence: estimate.subjectConfidence,
        poseConfidence: estimate.poseConfidence,
        autoCaptured: autoCaptured,
      ),
    );
  }

  void dispose() {
    pipeline.dispose();
  }
}
