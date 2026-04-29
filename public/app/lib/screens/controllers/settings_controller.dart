part of 'package:exbf_camera/screens/camera_screen.dart';

class _SettingsController {
  String aspectLabel = '3:4';
  ImageOutputFormat imageOutputFormat = ImageOutputFormat.jpg;
  ResolutionPreset resolutionPreset = ResolutionPreset.veryHigh;
  int imageQuality = 95;
  int videoFps = 30;
  int videoBitrate = 10000000;
  bool videoAudioEnabled = true;
  Duration captureTimer = Duration.zero;
  double exposure = 0;
  int? manualIso;
  int? manualShutterNs;
  String manualWhiteBalance = 'auto';

  static const double minExposure = -3;
  static const double maxExposure = 3;

  Future<ShotMode> restore({
    required String prefix,
    required List<String> aspectLabels,
    required ShotMode currentShotMode,
    required FlashMode currentFlashMode,
    required void Function(FlashMode flashMode) setFlashMode,
    required void Function(bool showGrid) setShowGrid,
    required void Function(bool showGuides) setShowGuides,
    required void Function(bool showScore) setShowScore,
    required void Function(bool showVisionDebug) setShowVisionDebug,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    aspectLabel = prefs.getString('${prefix}aspectLabel') ?? aspectLabel;
    if (!aspectLabels.contains(aspectLabel)) aspectLabel = '3:4';

    final restoredShotMode = ShotModePolicy.normalizeVisibleMode(
      _enumByName(
        ShotMode.values,
        prefs.getString('${prefix}shotMode'),
        currentShotMode,
      ),
    );
    setFlashMode(
      _enumByName(
        FlashMode.values,
        prefs.getString('${prefix}flashMode'),
        currentFlashMode,
      ),
    );

    resolutionPreset = _enumByName(
      ResolutionPreset.values,
      prefs.getString('${prefix}resolutionPreset'),
      resolutionPreset,
    );
    imageOutputFormat = _enumByName(
      ImageOutputFormat.values,
      prefs.getString('${prefix}imageOutputFormat'),
      imageOutputFormat,
    );
    setShowGrid(prefs.getBool('${prefix}showGrid') ?? false);
    setShowGuides(prefs.getBool('${prefix}showGuides') ?? true);
    setShowScore(prefs.getBool('${prefix}showScore') ?? true);
    setShowVisionDebug(prefs.getBool('${prefix}showVisionDebug') ?? false);

    imageQuality = prefs.getInt('${prefix}imageQuality') ?? imageQuality;
    if (![85, 95, 100].contains(imageQuality)) imageQuality = 95;
    videoFps = prefs.getInt('${prefix}videoFps') ?? videoFps;
    if (![24, 30, 60].contains(videoFps)) videoFps = 30;
    videoBitrate = prefs.getInt('${prefix}videoBitrate') ?? videoBitrate;
    if (![6000000, 10000000, 20000000, 40000000].contains(videoBitrate)) {
      videoBitrate = 10000000;
    }
    videoAudioEnabled =
        prefs.getBool('${prefix}videoAudio') ?? videoAudioEnabled;
    final timerSeconds = prefs.getInt('${prefix}captureTimer') ?? 0;
    captureTimer = Duration(seconds: timerSeconds);
    if (![0, 3, 5, 10].contains(captureTimer.inSeconds)) {
      captureTimer = Duration.zero;
    }
    return restoredShotMode;
  }

  Future<void> save({
    required String prefix,
    required String key,
    required Object value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '$prefix$key';
    switch (value) {
      case bool boolValue:
        await prefs.setBool(fullKey, boolValue);
      case int intValue:
        await prefs.setInt(fullKey, intValue);
      case double doubleValue:
        await prefs.setDouble(fullKey, doubleValue);
      case String stringValue:
        await prefs.setString(fullKey, stringValue);
    }
  }

  T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
