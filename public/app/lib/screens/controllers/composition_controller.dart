part of 'package:exbf_camera/screens/camera_screen.dart';

class _CompositionController {
  Map<ShotMode, CompositionRuleSet> rules = compositionRules;

  CompositionRuleSet rulesFor(ShotMode mode) {
    return rules[mode] ?? compositionRules[ShotMode.portrait]!;
  }

  CompositionSession evaluate({
    required ShotMode mode,
    required SubjectEstimate? liveEstimate,
    required bool hasReliableEstimate,
  }) {
    return CompositionSession.evaluate(
      rules: rulesFor(mode),
      liveEstimate: liveEstimate,
      hasReliableEstimate: hasReliableEstimate,
    );
  }

  VisionFrameResult? viewportVisionResult({
    required VisionFrameResult? result,
    required double? previewAspectRatio,
  }) {
    return transformVisionForViewport(result, previewAspectRatio);
  }

  SubjectEstimate? estimateForMode({
    required ShotMode mode,
    required VisionFrameResult? viewportVisionResult,
  }) {
    if (mode == ShotMode.selfie) {
      return estimateSelfieFaceFromVision(viewportVisionResult);
    }
    if (mode == ShotMode.stillLife || mode == ShotMode.object) {
      return estimateObjectFromVision(viewportVisionResult);
    }
    return estimateSubjectFromVision(viewportVisionResult);
  }

  CompositionSession currentSession({
    required ShotMode mode,
    required VisionFrameResult? visionResult,
    required double? previewAspectRatio,
    required _AnalysisPipeline analysisPipeline,
  }) {
    final viewportResult = viewportVisionResult(
      result: visionResult,
      previewAspectRatio: previewAspectRatio,
    );
    final estimate = estimateForMode(
      mode: mode,
      viewportVisionResult: viewportResult,
    );
    return evaluate(
      mode: mode,
      liveEstimate: estimate,
      hasReliableEstimate: analysisPipeline.isReliable(estimate),
    );
  }
}
