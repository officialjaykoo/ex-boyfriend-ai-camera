import '../vision/vision_models.dart';
import 'auto_capture_controller.dart';
import 'composition_session.dart';

class AutoCaptureUseCase {
  const AutoCaptureUseCase({
    this.maxAnalysisAge = const Duration(milliseconds: 800),
  });

  final Duration maxAnalysisAge;

  AutoCaptureDecision evaluate({
    required AutoCaptureController controller,
    required DateTime now,
    required bool enabled,
    required bool aiEnabled,
    required bool canAutoCaptureMode,
    required bool isPhotoMode,
    required bool isBusy,
    required bool isCameraSuspended,
    required CompositionSession composition,
    required VisionFrameResult? visionResult,
    required DateTime? lastAnalysisFrameAt,
    required DateTime? lastShotAt,
  }) {
    return controller.evaluate(
      now: now,
      enabled: enabled,
      aiEnabled: aiEnabled,
      canAutoCaptureMode: canAutoCaptureMode,
      isPhotoMode: isPhotoMode,
      isBusy: isBusy,
      isCameraSuspended: isCameraSuspended,
      hasFreshAnalysis: hasFreshAnalysis(now, lastAnalysisFrameAt),
      hasReliableSubject: composition.hasReliableEstimate,
      compositionReady: composition.ready,
      eyesOpen: eyesOpenForAutoCapture(visionResult),
      subjectX: composition.estimate.bodyCenterX,
      subjectY: composition.estimate.faceCenterY,
      lastShotAt: lastShotAt,
    );
  }

  bool hasFreshAnalysis(DateTime now, DateTime? lastAnalysisFrameAt) {
    if (lastAnalysisFrameAt == null) return false;
    final age = now.difference(lastAnalysisFrameAt);
    return !age.isNegative && age <= maxAnalysisAge;
  }

  bool eyesOpenForAutoCapture(VisionFrameResult? result) {
    final facesWithEyeState = (result?.faces ?? const <DetectedFace>[])
        .where((face) => face.hasEyeOpenProbabilities)
        .toList(growable: false);
    if (facesWithEyeState.isEmpty) return true;
    return facesWithEyeState.every((face) => face.eyesLikelyOpen);
  }
}
