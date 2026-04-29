part of 'package:exbf_camera/screens/camera_screen.dart';

const _showAdvancedSettings = false;

class _CameraSettingsOverlay extends StatelessWidget {
  const _CameraSettingsOverlay({
    required this.showGuides,
    required this.showGrid,
    required this.showScore,
    required this.showVisionDebug,
    required this.captureTimer,
    required this.exposure,
    required this.minExposure,
    required this.maxExposure,
    required this.imageOutputFormat,
    required this.imageQuality,
    required this.videoFps,
    required this.videoBitrate,
    required this.videoAudioEnabled,
    required this.resolutionPreset,
    required this.supportedResolutionPresets,
    required this.manualIso,
    required this.manualShutterNs,
    required this.manualWhiteBalance,
    required this.nativeState,
    required this.deviceCapability,
    required this.aiBenchmark,
    required this.aiEnabled,
    required this.aiBlockedReason,
    required this.analysisFramesReceived,
    required this.lastAnalysisFrameAt,
    required this.nativeSensorCount,
    required this.onToggleGuides,
    required this.onToggleGrid,
    required this.onToggleScore,
    required this.onToggleVisionDebug,
    required this.onTimerTap,
    required this.onExposureChanged,
    required this.onImageFormatSelected,
    required this.onImageQualityTap,
    required this.onVideoFpsTap,
    required this.onVideoBitrateTap,
    required this.onVideoAudioToggle,
    required this.onResolutionSelected,
    required this.onManualIsoSelected,
    required this.onManualShutterSelected,
    required this.onWhiteBalanceSelected,
    required this.onClose,
  });

  final bool showGuides;
  final bool showGrid;
  final bool showScore;
  final bool showVisionDebug;
  final Duration captureTimer;
  final double exposure;
  final double minExposure;
  final double maxExposure;
  final ImageOutputFormat imageOutputFormat;
  final int imageQuality;
  final int videoFps;
  final int videoBitrate;
  final bool videoAudioEnabled;
  final ResolutionPreset resolutionPreset;
  final List<ResolutionPreset> supportedResolutionPresets;
  final int? manualIso;
  final int? manualShutterNs;
  final String manualWhiteBalance;
  final _NativeCameraState nativeState;
  final _DeviceCapability deviceCapability;
  final _AiBenchmarkResult aiBenchmark;
  final bool aiEnabled;
  final String aiBlockedReason;
  final int analysisFramesReceived;
  final DateTime? lastAnalysisFrameAt;
  final int nativeSensorCount;
  final VoidCallback onToggleGuides;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleScore;
  final VoidCallback onToggleVisionDebug;
  final VoidCallback onTimerTap;
  final ValueChanged<double> onExposureChanged;
  final ValueChanged<ImageOutputFormat> onImageFormatSelected;
  final VoidCallback onImageQualityTap;
  final VoidCallback onVideoFpsTap;
  final VoidCallback onVideoBitrateTap;
  final VoidCallback onVideoAudioToggle;
  final ValueChanged<ResolutionPreset> onResolutionSelected;
  final ValueChanged<int?> onManualIsoSelected;
  final ValueChanged<int?> onManualShutterSelected;
  final ValueChanged<String> onWhiteBalanceSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.14),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '설정',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            tooltip: '닫기',
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      _SettingsSection(
                        title: '프리뷰',
                        child: Row(
                          children: [
                            Expanded(
                              child: _SettingsChip(
                                icon: Icons.person_pin_circle_outlined,
                                label: '가이드',
                                selected: showGuides,
                                onTap: onToggleGuides,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _SettingsChip(
                                icon: Icons.grid_3x3_outlined,
                                label: '격자',
                                selected: showGrid,
                                onTap: onToggleGrid,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _SettingsChip(
                                icon: Icons.speed_outlined,
                                label: '점수',
                                selected: showScore,
                                onTap: onToggleScore,
                                compact: true,
                              ),
                            ),
                            if (_showAdvancedSettings) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: _SettingsChip(
                                  icon: Icons.polyline_outlined,
                                  label: 'AI 좌표',
                                  selected: showVisionDebug,
                                  onTap: onToggleVisionDebug,
                                  compact: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: '촬영',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SettingsChip(
                              icon: Icons.timer_outlined,
                              label: captureTimer == Duration.zero
                                  ? '타이머 OFF'
                                  : '타이머 ${captureTimer.inSeconds}s',
                              selected: captureTimer != Duration.zero,
                              onTap: onTimerTap,
                            ),
                            _SettingsChip(
                              icon: Icons.hd_outlined,
                              label: _resolutionLabel,
                              selected:
                                  resolutionPreset != ResolutionPreset.veryHigh,
                              onTap: _cycleResolution,
                            ),
                            _SettingsChip(
                              icon: Icons.high_quality_outlined,
                              label: '품질 $imageQuality',
                              selected: imageQuality != 95,
                              onTap: onImageQualityTap,
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: '노출',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.exposure,
                              color: Color(0xff555555),
                            ),
                            Expanded(
                              child: Slider(
                                value: exposure.clamp(minExposure, maxExposure),
                                min: minExposure,
                                max: maxExposure <= minExposure
                                    ? minExposure + 1
                                    : maxExposure,
                                activeColor: _accentPink,
                                inactiveColor: const Color(0xffe4e4e8),
                                onChanged: maxExposure <= minExposure
                                    ? null
                                    : onExposureChanged,
                              ),
                            ),
                            Text(
                              exposure.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xff555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: '저장',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SettingsChip(
                              icon: Icons.image_outlined,
                              label: 'JPG',
                              selected:
                                  imageOutputFormat == ImageOutputFormat.jpg,
                              onTap: () =>
                                  onImageFormatSelected(ImageOutputFormat.jpg),
                            ),
                            _SettingsChip(
                              icon: Icons.image_outlined,
                              label: 'PNG',
                              selected:
                                  imageOutputFormat != ImageOutputFormat.jpg,
                              onTap: () =>
                                  onImageFormatSelected(ImageOutputFormat.png),
                            ),
                          ],
                        ),
                      ),
                      if (_showAdvancedSettings)
                        _SettingsSection(
                          title: '진단',
                          child: _DiagnosticsPanel(
                            nativeState: nativeState,
                            deviceCapability: deviceCapability,
                            aiBenchmark: aiBenchmark,
                            aiEnabled: aiEnabled,
                            aiBlockedReason: aiBlockedReason,
                            analysisFramesReceived: analysisFramesReceived,
                            lastAnalysisFrameAt: lastAnalysisFrameAt,
                            nativeSensorCount: nativeSensorCount,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _resolutionLabel {
    return switch (resolutionPreset) {
      ResolutionPreset.high => 'HD',
      ResolutionPreset.veryHigh => 'FHD',
      ResolutionPreset.ultraHigh => 'UHD',
    };
  }

  void _cycleResolution() {
    final next = switch (resolutionPreset) {
      ResolutionPreset.high => ResolutionPreset.veryHigh,
      ResolutionPreset.veryHigh => ResolutionPreset.ultraHigh,
      ResolutionPreset.ultraHigh => ResolutionPreset.high,
    };
    if (supportedResolutionPresets.contains(next)) {
      onResolutionSelected(next);
      return;
    }
    final currentIndex = supportedResolutionPresets.indexOf(resolutionPreset);
    final safeIndex = currentIndex < 0 ? 0 : currentIndex + 1;
    onResolutionSelected(
      supportedResolutionPresets[safeIndex % supportedResolutionPresets.length],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff777777),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _SettingsChip extends StatelessWidget {
  const _SettingsChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12),
        decoration: BoxDecoration(
          color: selected ? _accentPink.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _accentPink : const Color(0xffdedee4),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? _accentPink : const Color(0xff555555),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? _accentPink : const Color(0xff555555),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
