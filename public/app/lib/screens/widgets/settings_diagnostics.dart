part of 'package:exbf_camera/screens/camera_screen.dart';

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
            Text(deviceCapability.chipset),
            if (sensor != null) ...[
              Text('센서: ${sensor.id} / ${sensor.hardwareLevel}'),
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
              '분석 프레임: Flutter $analysisFramesReceived / Native ${nativeState.analysisFrames}',
            ),
            Text(
              '분석 입력/스킵: ${nativeState.analysisInputFrames} / busy ${nativeState.analysisSkippedBusy} / throttle ${nativeState.analysisSkippedThrottle}',
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
              '센서 수: $nativeSensorCount / 선택 ${nativeState.selectedCameraId ?? nativeState.lensFacing}',
            ),
            Text(
              '바인드: ${nativeState.bindCount}회 / 실패 ${nativeState.bindFailureCount}회',
            ),
            if (nativeState.lastBindError.isNotEmpty)
              Text('바인드 오류: ${nativeState.lastBindError}'),
            if (nativeState.lastCaptureError.isNotEmpty)
              Text('캡처 오류: ${nativeState.lastCaptureError}'),
            if (nativeState.lastVideoError.isNotEmpty)
              Text('영상 오류: ${nativeState.lastVideoError}'),
            Text('영상 이벤트: ${nativeState.lastVideoEvent}'),
            Text(
              '영상 저장: ${nativeState.lastVideoBytes} bytes / ${nativeState.lastVideoDurationMs}ms',
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
