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
}
