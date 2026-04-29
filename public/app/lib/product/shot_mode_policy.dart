import '../models/camera_modes.dart';

enum VisionAnalysisMode { full, faceOnly, objectOnly }

class ShotModePolicy {
  const ShotModePolicy._();

  static const visibleModes = [
    ShotMode.portrait,
    ShotMode.group,
    ShotMode.selfie,
  ];

  static ShotMode normalizeVisibleMode(ShotMode mode) {
    return visibleModes.contains(mode) ? mode : ShotMode.portrait;
  }

  static bool canAutoCapture(ShotMode mode) {
    return mode != ShotMode.selfie;
  }

  static VisionAnalysisMode analysisModeFor(ShotMode mode) {
    return switch (mode) {
      ShotMode.selfie => VisionAnalysisMode.faceOnly,
      ShotMode.stillLife || ShotMode.object => VisionAnalysisMode.objectOnly,
      _ => VisionAnalysisMode.full,
    };
  }

  static String nativeAnalysisModeFor(ShotMode mode) {
    return switch (analysisModeFor(mode)) {
      VisionAnalysisMode.faceOnly => 'face_only',
      VisionAnalysisMode.objectOnly => 'object_only',
      VisionAnalysisMode.full => 'full',
    };
  }
}
