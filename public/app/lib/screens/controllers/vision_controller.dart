part of 'package:exbf_camera/screens/camera_screen.dart';

class _VisionController {
  final _AnalysisPipeline analysisPipeline = _AnalysisPipeline(
    minFrameGap: const Duration(milliseconds: 240),
    minSubjectConfidence: 0.25,
    minPoseConfidence: 0.25,
  );
  final VisionEngine engine = VisionEngine();

  VisionFrameResult? result;
  _DeviceCapability deviceCapability = const _DeviceCapability.supported();
  _AiBenchmarkResult aiBenchmark = const _AiBenchmarkResult.enabled();
  bool aiEnabled = true;
  String aiBlockedReason = '';
  int analysisFramesReceived = 0;
  DateTime? lastAnalysisFrameAt;

  void clearResult() {
    result = null;
    lastAnalysisFrameAt = null;
  }

  void resetPipeline() {
    analysisPipeline.reset();
  }

  void close() {
    engine.close();
  }
}
