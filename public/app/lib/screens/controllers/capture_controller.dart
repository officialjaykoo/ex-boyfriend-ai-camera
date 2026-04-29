part of 'package:exbf_camera/screens/camera_screen.dart';

class _CaptureController {
  _CaptureController({required String album})
    : pipeline = _CapturePipeline(album: album);

  final _CapturePipeline pipeline;
  DateTime? lastShotAt;
  DateTime? recordingStartedAt;
  int? countdownSeconds;

  void dispose() {
    pipeline.dispose();
  }
}
