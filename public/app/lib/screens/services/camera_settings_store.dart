// ignore_for_file: invalid_use_of_protected_member

part of 'package:exbf_camera/screens/camera_screen.dart';

extension _CameraSettingsStore on _CameraScreenState {
  Future<void> _restoreSettings() async {
    final shotMode = await _settings.restore(
      prefix: _CameraScreenState._settingsPrefix,
      aspectLabels: _CameraScreenState._aspectLabels,
      currentShotMode: _shotMode,
      currentFlashMode: _flashMode,
      setFlashMode: (value) => _flashMode = value,
      setShowGrid: (value) => _ui.showGrid = value,
      setShowGuides: (value) => _ui.showGuides = value,
      setShowScore: (value) => _ui.showScore = value,
      setShowVisionDebug: (value) => _ui.showVisionDebug = value,
    );
    if (!mounted) return;
    setState(() => _shotMode = shotMode);
  }

  Future<void> _saveSetting(String key, Object value) {
    return _settings.save(
      prefix: _CameraScreenState._settingsPrefix,
      key: key,
      value: value,
    );
  }
}
