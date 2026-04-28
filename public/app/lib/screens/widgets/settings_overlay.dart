part of 'package:exbf_camera/screens/camera_screen.dart';

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
                        title: '프리뷰 표시',
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
                              label: '사진 품질 $imageQuality',
                              selected: imageQuality != 95,
                              onTap: onImageQualityTap,
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: '영상',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SettingsChip(
                              icon: Icons.speed_outlined,
                              label: '${videoFps}fps',
                              selected: videoFps != 30,
                              onTap: onVideoFpsTap,
                            ),
                            _SettingsChip(
                              icon: Icons.memory_outlined,
                              label: '${(videoBitrate / 1000000).round()}Mbps',
                              selected: videoBitrate != 10000000,
                              onTap: onVideoBitrateTap,
                            ),
                            _SettingsChip(
                              icon: videoAudioEnabled
                                  ? Icons.mic_outlined
                                  : Icons.mic_off_outlined,
                              label: videoAudioEnabled ? '오디오 ON' : '오디오 OFF',
                              selected: !videoAudioEnabled,
                              onTap: onVideoAudioToggle,
                            ),
                          ],
                        ),
                      ),
                      _SettingsSection(
                        title: '노출 보정',
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
                        title: '수동 Camera2 제어',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsChipRow(
                              label: 'ISO',
                              children: [
                                _SettingsChip(
                                  icon: Icons.auto_mode,
                                  label: 'Auto',
                                  selected: manualIso == null,
                                  onTap: () => onManualIsoSelected(null),
                                ),
                                for (final iso in const [100, 400, 800, 1600])
                                  _SettingsChip(
                                    icon: Icons.iso_outlined,
                                    label: '$iso',
                                    selected: manualIso == iso,
                                    onTap: () => onManualIsoSelected(iso),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _SettingsChipRow(
                              label: '셔터',
                              children: [
                                _SettingsChip(
                                  icon: Icons.auto_mode,
                                  label: 'Auto',
                                  selected: manualShutterNs == null,
                                  onTap: () => onManualShutterSelected(null),
                                ),
                                for (final shutter in const [
                                  _ShutterOption('1/30', 33333333),
                                  _ShutterOption('1/60', 16666667),
                                  _ShutterOption('1/120', 8333333),
                                ])
                                  _SettingsChip(
                                    icon: Icons.shutter_speed_outlined,
                                    label: shutter.label,
                                    selected: manualShutterNs == shutter.ns,
                                    onTap: () =>
                                        onManualShutterSelected(shutter.ns),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _SettingsChipRow(
                              label: '화이트밸런스',
                              children: [
                                for (final wb in const [
                                  _WhiteBalanceOption('auto', 'Auto'),
                                  _WhiteBalanceOption('daylight', 'Day'),
                                  _WhiteBalanceOption('cloudy', 'Cloud'),
                                  _WhiteBalanceOption('fluorescent', 'Fluo'),
                                ])
                                  _SettingsChip(
                                    icon: Icons.thermostat_outlined,
                                    label: wb.label,
                                    selected: manualWhiteBalance == wb.value,
                                    onTap: () =>
                                        onWhiteBalanceSelected(wb.value),
                                  ),
                              ],
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

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({
    required this.nativeState,
    required this.deviceCapability,
    required this.aiBenchmark,
    required this.aiEnabled,
    required this.aiBlockedReason,
    required this.analysisFramesReceived,
    required this.lastAnalysisFrameAt,
    required this.nativeSensorCount,
  });

  final _NativeCameraState nativeState;
  final _DeviceCapability deviceCapability;
  final _AiBenchmarkResult aiBenchmark;
  final bool aiEnabled;
  final String aiBlockedReason;
  final int analysisFramesReceived;
  final DateTime? lastAnalysisFrameAt;
  final int nativeSensorCount;

  @override
  Widget build(BuildContext context) {
    final lastFrame = lastAnalysisFrameAt;
    final lastFrameLabel = lastFrame == null
        ? '없음'
        : '${DateTime.now().difference(lastFrame).inSeconds}s 전';
    final sensor = nativeState.selectedSensor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff7f7fa),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe4e4e8)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xff555555),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CameraX: ${nativeState.ready ? "정상" : "대기"}'),
            Text(
              '모드: ${nativeState.captureMode} / 줌 ${nativeState.zoomRatio.toStringAsFixed(1)}x',
            ),
            Text(
              '기기: ${deviceCapability.supported ? "지원" : "미지원"} / Android ${deviceCapability.sdk}',
            ),
            Text(
              'RAM: ${deviceCapability.totalRamGb.toStringAsFixed(1)}GB / Camera2 ${deviceCapability.camera2Level}',
            ),
            Text(
              '칩셋: ${deviceCapability.chipsetKnownFast ? "고성능 목록" : "벤치마크 기준"}',
            ),
            Text(deviceCapability.chipset),
            if (sensor != null) ...[
              Text('선택 렌즈: ${sensor.id} / ${sensor.hardwareLevel}'),
              Text('ISO: ${sensor.minIso ?? "-"}-${sensor.maxIso ?? "-"}'),
              Text(
                '셔터: ${_nsLabel(sensor.minExposureTimeNs)}-${_nsLabel(sensor.maxExposureTimeNs)}',
              ),
              Text(
                '줌: ${sensor.minZoomRatio?.toStringAsFixed(1) ?? "-"}-${sensor.maxZoomRatio?.toStringAsFixed(1) ?? sensor.maxDigitalZoom.toStringAsFixed(1)}x',
              ),
            ],
            Text(
              'Native AI: ${nativeState.nativeVisionReady ? "ON" : "OFF"} / ${nativeState.nativeVisionDelegate}',
            ),
            Text('AI 사용: ${aiEnabled ? "ON" : "카메라 전용"}'),
            if (!aiEnabled && aiBlockedReason.isNotEmpty)
              Text('AI 차단: $aiBlockedReason'),
            Text('벤치마크: ${aiBenchmark.readableSummary}'),
            for (final result in aiBenchmark.results)
              Text(
                '${result.delegate}: ${result.ok ? "${result.averageMs}ms" : "실패 ${result.error}"}',
              ),
            Text('분석 정책: ${nativeState.analysisPolicy}'),
            Text('분석 모드: ${nativeState.analysisMode}'),
            Text(
              '분석: Flutter $analysisFramesReceived / Native ${nativeState.analysisFrames} 프레임',
            ),
            Text(
              '분석 입력/스킵: ${nativeState.analysisInputFrames} / 바쁨 ${nativeState.analysisSkippedBusy} / 간격 ${nativeState.analysisSkippedThrottle}',
            ),
            Text('분석 FPS: ${nativeState.analysisFps.toStringAsFixed(1)}'),
            Text(
              'AI 처리: ${nativeState.lastProcessingMs}ms / 회전 ${nativeState.lastRotationDegrees}도',
            ),
            Text('마지막 AI: $lastFrameLabel'),
            Text(
              '캡처: 사진 ${nativeState.imageCaptureReady ? "ON" : "OFF"} / 영상 ${nativeState.videoCaptureReady ? "ON" : "OFF"}',
            ),
            Text(
              '렌즈 수: $nativeSensorCount / 선택 ${nativeState.selectedCameraId ?? nativeState.lensFacing}',
            ),
            Text(
              '바인딩: ${nativeState.bindCount}회 / 실패 ${nativeState.bindFailureCount}회',
            ),
            if (nativeState.lastBindError.isNotEmpty)
              Text('바인딩 오류: ${nativeState.lastBindError}'),
            if (nativeState.lastCaptureError.isNotEmpty)
              Text('캡처 오류: ${nativeState.lastCaptureError}'),
            if (nativeState.lastVideoError.isNotEmpty)
              Text('영상 오류: ${nativeState.lastVideoError}'),
            Text('영상 이벤트: ${nativeState.lastVideoEvent}'),
            Text(
              '영상 저장: ${nativeState.lastVideoBytes} bytes / ${nativeState.lastVideoDurationMs}ms',
            ),
            Text(
              '영상 진행: ${nativeState.lastVideoStatusBytes} bytes / ${nativeState.lastVideoStatusDurationMs}ms',
            ),
            Text(
              '녹화 횟수: 시작 ${nativeState.videoRecordCount} / 완료 ${nativeState.videoFinalizeCount}',
            ),
            if (nativeState.lastGalleryError.isNotEmpty)
              Text('갤러리 오류: ${nativeState.lastGalleryError}'),
            Text('카메라 상태: ${nativeState.lastCameraState}'),
            if (nativeState.lastCameraStateError.isNotEmpty)
              Text('카메라 상태 오류: ${nativeState.lastCameraStateError}'),
            Text('최근 사진: ${nativeState.lastPhotoBytes} bytes'),
            Text(
              '최근 저장: ${nativeState.lastGalleryUri.isEmpty ? "-" : nativeState.lastGalleryUri}',
            ),
            Text('최근 포커스: ${nativeState.lastFocusResult}'),
            Text(
              '영상 설정: ${nativeState.targetFps}fps / ${(nativeState.targetVideoBitrate / 1000000).round()}Mbps / 오디오 ${nativeState.audioEnabled ? "ON" : "OFF"}',
            ),
            Text(
              '메모리: ${nativeState.usedMemoryMb}/${nativeState.maxMemoryMb} MB',
            ),
            Text('발열 상태: ${_thermalLabel(nativeState.thermalStatus)}'),
            Text(
              '수동값: ISO ${nativeState.manualIso ?? "Auto"} / 셔터 ${_nsLabel(nativeState.manualExposureTimeNs)} / WB ${nativeState.manualWhiteBalance}',
            ),
            Text(
              '가동 시간: ${(nativeState.uptimeMs / 60000).toStringAsFixed(1)}분',
            ),
          ],
        ),
      ),
    );
  }

  String _nsLabel(int? value) {
    if (value == null || value <= 0) return 'Auto';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}ms';
    return '${(value / 1000).toStringAsFixed(0)}us';
  }

  String _thermalLabel(int value) {
    return switch (value) {
      0 => '정상',
      1 => '가벼움',
      2 => '보통',
      3 => '심함',
      4 => '위험',
      5 => '긴급',
      6 => '종료 임박',
      _ => '알 수 없음',
    };
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

class _SettingsChipRow extends StatelessWidget {
  const _SettingsChipRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff777777),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
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

class _ShutterOption {
  const _ShutterOption(this.label, this.ns);
  final String label;
  final int ns;
}

class _WhiteBalanceOption {
  const _WhiteBalanceOption(this.value, this.label);
  final String value;
  final String label;
}
