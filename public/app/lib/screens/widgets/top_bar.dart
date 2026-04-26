part of 'package:exbf_camera/screens/camera_screen.dart';

class _LoadingPreview extends StatelessWidget {
  const _LoadingPreview({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TopToolbar extends StatelessWidget {
  const _TopToolbar({
    required this.aspectLabel,
    required this.flashMode,
    required this.autoCaptureEnabled,
    required this.onAutoCaptureToggle,
    required this.onFlashTap,
    required this.onAspectTap,
    required this.onSettingsTap,
    required this.showGuides,
    required this.showGrid,
    required this.showScore,
    required this.onSwitchCamera,
  });

  final String aspectLabel;
  final FlashMode flashMode;
  final bool autoCaptureEnabled;
  final VoidCallback onAutoCaptureToggle;
  final VoidCallback onFlashTap;
  final VoidCallback onAspectTap;
  final VoidCallback onSettingsTap;
  final bool showGuides;
  final bool showGrid;
  final bool showScore;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: onAutoCaptureToggle,
              style: TextButton.styleFrom(
                foregroundColor: autoCaptureEnabled
                    ? _accentPink
                    : const Color(0xff4d4d4d),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                autoCaptureEnabled ? 'AUTO ON' : 'AUTO OFF',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Flash',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: Icon(
                    _flashIcon,
                    size: 21,
                    color: const Color(0xff4d4d4d),
                  ),
                  onPressed: onFlashTap,
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAspectTap,
                  child: Container(
                    width: 32,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff5a5a5a),
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      aspectLabel,
                      style: const TextStyle(
                        color: Color(0xff4d4d4d),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                IconButton(
                  tooltip: 'Settings',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 21,
                    color: showGuides || showGrid || showScore
                        ? _accentPink
                        : const Color(0xff4d4d4d),
                  ),
                  onPressed: onSettingsTap,
                ),
                IconButton(
                  tooltip: 'Switch camera',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: const Icon(
                    Icons.cameraswitch_outlined,
                    size: 22,
                    color: Color(0xff4d4d4d),
                  ),
                  onPressed: onSwitchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _flashIcon {
    return switch (flashMode) {
      FlashMode.auto => Icons.flash_auto,
      FlashMode.always => Icons.flash_on,
      FlashMode.torch => Icons.highlight,
      FlashMode.off => Icons.flash_off,
    };
  }
}

class _TopFloatingMenus extends StatelessWidget {
  const _TopFloatingMenus({
    required this.flashMenuOpen,
    required this.aspectMenuOpen,
    required this.settingsMenuOpen,
    required this.aspectLabels,
    required this.aspectLabel,
    required this.flashMode,
    required this.showGuides,
    required this.showGrid,
    required this.showScore,
    required this.onFlashSelected,
    required this.onAspectSelected,
    required this.onToggleGuides,
    required this.onToggleGrid,
    required this.onToggleScore,
  });

  final bool flashMenuOpen;
  final bool aspectMenuOpen;
  final bool settingsMenuOpen;
  final List<String> aspectLabels;
  final String aspectLabel;
  final FlashMode flashMode;
  final bool showGuides;
  final bool showGrid;
  final bool showScore;
  final ValueChanged<FlashMode> onFlashSelected;
  final ValueChanged<String> onAspectSelected;
  final VoidCallback onToggleGuides;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleScore;

  @override
  Widget build(BuildContext context) {
    final Widget? content;
    if (aspectMenuOpen) {
      content = _TopMenuRail(
        children: aspectLabels.map((label) {
          return _FloatingChoice(
            label: label,
            selected: label == aspectLabel,
            onTap: () => onAspectSelected(label),
          );
        }).toList(),
      );
    } else if (flashMenuOpen) {
      content = _TopMenuRail(
        children: [
          _FloatingChoice(
            label: 'Off',
            selected: flashMode == FlashMode.off,
            onTap: () => onFlashSelected(FlashMode.off),
          ),
          _FloatingChoice(
            label: 'Auto',
            selected: flashMode == FlashMode.auto,
            onTap: () => onFlashSelected(FlashMode.auto),
          ),
          _FloatingChoice(
            label: 'On',
            selected: flashMode == FlashMode.always,
            onTap: () => onFlashSelected(FlashMode.always),
          ),
          _FloatingChoice(
            label: 'Torch',
            selected: flashMode == FlashMode.torch,
            onTap: () => onFlashSelected(FlashMode.torch),
          ),
        ],
      );
    } else if (settingsMenuOpen) {
      content = _TopMenuRail(
        children: [
          _FloatingIconChoice(
            icon: Icons.person_pin_circle_outlined,
            selected: showGuides,
            onTap: onToggleGuides,
          ),
          _FloatingIconChoice(
            icon: Icons.grid_3x3_outlined,
            selected: showGrid,
            onTap: onToggleGrid,
          ),
          _FloatingIconChoice(
            icon: Icons.speed_outlined,
            selected: showScore,
            onTap: onToggleScore,
          ),
        ],
      );
    } else {
      content = null;
    }

    if (content == null) return const SizedBox.shrink();

    return Positioned(top: 42, left: 0, right: 0, child: content);
  }
}

class _TopMenuRail extends StatelessWidget {
  const _TopMenuRail({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      elevation: 2,
      child: SizedBox(
        height: 44,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingChoice extends StatelessWidget {
  const _FloatingChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 38),
        height: 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? _accentPink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xff555555),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FloatingIconChoice extends StatelessWidget {
  const _FloatingIconChoice({
    required this.icon,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? _accentPink : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          size: 19,
          color: selected ? Colors.white : const Color(0xff555555),
        ),
      ),
    );
  }
}

class _CameraViewport extends StatelessWidget {
  const _CameraViewport({required this.aspectRatio, required this.child});

  final double? aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (aspectRatio == null) return SizedBox.expand(child: child);
    return AspectRatio(
      aspectRatio: aspectRatio!,
      child: ClipRect(child: child),
    );
  }
}

class _NativeCameraPreviewSurface extends StatelessWidget {
  const _NativeCameraPreviewSurface({required this.textureId});

  final int textureId;

  @override
  Widget build(BuildContext context) {
    return Texture(textureId: textureId);
  }
}
