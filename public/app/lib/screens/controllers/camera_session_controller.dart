part of 'package:exbf_camera/screens/camera_screen.dart';

class _CameraSessionController {
  _CameraSessionState state = const _CameraSessionState(
    _CameraSessionPhase.preparing,
    message: 'Camera ready',
  );
  bool cameraOperationInFlight = false;
  List<_NativeCameraSensor> nativeSensors = [];
  _NativeCameraState nativeState = const _NativeCameraState();
  bool nativeCameraReady = false;
  int? nativeTextureId;
  String? nativeStandardSensorId;
  String? nativeWideSensorId;
  String? nativeSelectedSensorId;
  DateTime? lastNativeStatePollAt;

  bool get isBusy => state.isBusy;
  bool get isRecording => state.isRecording;
  bool get isSuspended => state.isSuspended;

  void setPhase(_CameraSessionPhase phase, {String? message}) {
    state = state.copyWith(phase: phase, message: message);
  }
}
