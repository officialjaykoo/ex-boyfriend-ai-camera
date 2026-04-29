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

  void acceptAnalysisResult(VisionFrameResult next) {
    analysisFramesReceived += 1;
    lastAnalysisFrameAt = DateTime.now();
    result = next;
  }

  bool shouldAnalyzeNow() {
    return analysisPipeline.shouldAnalyze(DateTime.now());
  }

  void completeAnalysis() {
    analysisPipeline.complete();
  }

  bool isAnalysisFresh({Duration maxAge = const Duration(seconds: 4)}) {
    final lastFrameAt = lastAnalysisFrameAt;
    return lastFrameAt != null &&
        DateTime.now().difference(lastFrameAt) < maxAge;
  }

  void blockAi(String reason) {
    aiEnabled = false;
    aiBlockedReason = reason;
  }

  void applyBenchmark(_AiBenchmarkResult benchmark) {
    aiBenchmark = benchmark;
    aiEnabled = benchmark.aiEnabled;
    aiBlockedReason = benchmark.aiEnabled ? '' : benchmark.readableSummary;
  }

  Future<_AiBenchmarkResult?> restoreBenchmark({required String prefix}) async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt('${prefix}aiBenchmarkVersion');
    if (version != 1) return null;
    final bestDelegate = prefs.getString('${prefix}aiBestDelegate');
    if (bestDelegate == null || bestDelegate.isEmpty) return null;
    return _AiBenchmarkResult(
      aiEnabled: prefs.getBool('${prefix}aiEnabled') ?? false,
      bestDelegate: bestDelegate,
      averageMs: prefs.getInt('${prefix}aiAverageMs') ?? 0,
      grade: prefs.getString('${prefix}aiGrade') ?? 'unknown',
      blockedReason: prefs.getString('${prefix}aiBlockedReason') ?? '',
      results: const [],
    );
  }

  Future<void> saveBenchmark({
    required String prefix,
    required _AiBenchmarkResult result,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${prefix}aiBenchmarkVersion', 1);
    await prefs.setBool('${prefix}aiEnabled', result.aiEnabled);
    await prefs.setString('${prefix}aiBestDelegate', result.bestDelegate);
    await prefs.setInt('${prefix}aiAverageMs', result.averageMs);
    await prefs.setString('${prefix}aiGrade', result.grade);
    await prefs.setString('${prefix}aiBlockedReason', result.blockedReason);
  }

  void resetPipeline() {
    analysisPipeline.reset();
  }

  void close() {
    engine.close();
  }
}
