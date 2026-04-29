// ignore_for_file: invalid_use_of_protected_member

part of 'package:exbf_camera/screens/camera_screen.dart';

extension _CameraSettingsStore on _CameraScreenState {
  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _aspectLabel =
          prefs.getString('${_CameraScreenState._settingsPrefix}aspectLabel') ??
          _aspectLabel;
      if (!_CameraScreenState._aspectLabels.contains(_aspectLabel)) {
        _aspectLabel = '3:4';
      }
      _shotMode = _enumByName(
        ShotMode.values,
        prefs.getString('${_CameraScreenState._settingsPrefix}shotMode'),
        _shotMode,
      );
      _shotMode = ShotModePolicy.normalizeVisibleMode(_shotMode);
      _flashMode = _enumByName(
        FlashMode.values,
        prefs.getString('${_CameraScreenState._settingsPrefix}flashMode'),
        _flashMode,
      );
      _resolutionPreset = _enumByName(
        ResolutionPreset.values,
        prefs.getString(
          '${_CameraScreenState._settingsPrefix}resolutionPreset',
        ),
        _resolutionPreset,
      );
      _imageOutputFormat = _enumByName(
        ImageOutputFormat.values,
        prefs.getString(
          '${_CameraScreenState._settingsPrefix}imageOutputFormat',
        ),
        _imageOutputFormat,
      );
      _ui.showGrid =
          prefs.getBool('${_CameraScreenState._settingsPrefix}showGrid') ??
          _ui.showGrid;
      _ui.showGuides =
          prefs.getBool('${_CameraScreenState._settingsPrefix}showGuides') ??
          _ui.showGuides;
      _ui.showScore =
          prefs.getBool('${_CameraScreenState._settingsPrefix}showScore') ??
          _ui.showScore;
      _ui.showVisionDebug =
          prefs.getBool(
            '${_CameraScreenState._settingsPrefix}showVisionDebug',
          ) ??
          _ui.showVisionDebug;
      _imageQuality =
          prefs.getInt('${_CameraScreenState._settingsPrefix}imageQuality') ??
          _imageQuality;
      if (![85, 95, 100].contains(_imageQuality)) _imageQuality = 95;
      _videoFps =
          prefs.getInt('${_CameraScreenState._settingsPrefix}videoFps') ??
          _videoFps;
      if (![24, 30, 60].contains(_videoFps)) _videoFps = 30;
      _videoBitrate =
          prefs.getInt('${_CameraScreenState._settingsPrefix}videoBitrate') ??
          _videoBitrate;
      if (![6000000, 10000000, 20000000, 40000000].contains(_videoBitrate)) {
        _videoBitrate = 10000000;
      }
      _videoAudioEnabled =
          prefs.getBool('${_CameraScreenState._settingsPrefix}videoAudio') ??
          _videoAudioEnabled;
      final timerSeconds =
          prefs.getInt('${_CameraScreenState._settingsPrefix}captureTimer') ??
          0;
      _captureTimer = Duration(seconds: timerSeconds);
      if (![0, 3, 5, 10].contains(_captureTimer.inSeconds)) {
        _captureTimer = Duration.zero;
      }
    });
  }

  T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  Future<void> _saveSetting(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '${_CameraScreenState._settingsPrefix}$key';
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
}
