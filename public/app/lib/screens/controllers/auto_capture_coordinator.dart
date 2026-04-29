part of 'package:exbf_camera/screens/camera_screen.dart';

class _AutoCaptureCoordinator {
  final AutoCaptureController controller = AutoCaptureController();
  final AutoCaptureUseCase useCase = const AutoCaptureUseCase();

  void reset() {
    controller.reset();
  }

  AutoCaptureDecision tick({
    required DateTime now,
    required bool enabled,
    required bool aiEnabled,
    required ShotMode shotMode,
    required MediaMode mediaMode,
    required bool isBusy,
    required bool isCameraSuspended,
    required CompositionSession composition,
    required VisionFrameResult? viewportVisionResult,
    required DateTime? lastAnalysisFrameAt,
    required DateTime? lastShotAt,
  }) {
    return useCase.evaluate(
      controller: controller,
      now: now,
      enabled: enabled,
      aiEnabled: aiEnabled,
      canAutoCaptureMode: ShotModePolicy.canAutoCapture(shotMode),
      isPhotoMode: mediaMode == MediaMode.photo,
      isBusy: isBusy,
      isCameraSuspended: isCameraSuspended,
      composition: composition,
      visionResult: viewportVisionResult,
      lastAnalysisFrameAt: lastAnalysisFrameAt,
      lastShotAt: lastShotAt,
    );
  }
}
