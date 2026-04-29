part of 'package:exbf_camera/screens/camera_screen.dart';

class _UiOverlayController {
  ToolPanel toolPanel = ToolPanel.none;
  StickerEffect stickerEffect = StickerEffect.none;
  StyleEffect styleEffect = StyleEffect.none;
  SetEffect setEffect = SetEffect.none;
  RetouchEffect retouchEffect = RetouchEffect.none;
  MediaMode mediaMode = MediaMode.photo;
  bool showGrid = false;
  bool showGuides = true;
  bool showScore = true;
  bool showVisionDebug = false;
  bool aspectMenuOpen = false;
  bool flashMenuOpen = false;
  bool settingsMenuOpen = false;
  Offset? focusPoint;
  bool showExposureGesture = false;
  String? thumbnailPath;
  bool thumbnailIsVideo = false;

  void toggleTopMenu(String menu) {
    flashMenuOpen = menu == 'flash' ? !flashMenuOpen : false;
    aspectMenuOpen = menu == 'aspect' ? !aspectMenuOpen : false;
    settingsMenuOpen = menu == 'settings' ? !settingsMenuOpen : false;
  }

  void closeMenus() {
    flashMenuOpen = false;
    aspectMenuOpen = false;
    settingsMenuOpen = false;
  }

  void clearTransientOverlays() {
    focusPoint = null;
    showExposureGesture = false;
  }

  void closeToolPanel() {
    toolPanel = ToolPanel.none;
  }

  void toggleToolPanel(ToolPanel panel) {
    toolPanel = toolPanel == panel ? ToolPanel.none : panel;
  }

  void showThumbnail(String path, {required bool isVideo}) {
    thumbnailPath = path;
    thumbnailIsVideo = isVideo;
  }

  void clearThumbnail() {
    thumbnailPath = null;
    thumbnailIsVideo = false;
  }
}
