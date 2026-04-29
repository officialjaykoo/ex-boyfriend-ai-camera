import 'package:exbf_camera/models/camera_modes.dart';
import 'package:exbf_camera/product/auto_capture_controller.dart';
import 'package:exbf_camera/product/auto_capture_use_case.dart';
import 'package:exbf_camera/product/composition_session.dart';
import 'package:exbf_camera/product/saved_shot_history.dart';
import 'package:exbf_camera/product/shot_mode_policy.dart';
import 'package:exbf_camera/rules/composition_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('shot mode policy exposes the focused MVP modes', () {
    expect(ShotModePolicy.visibleModes, [
      ShotMode.portrait,
      ShotMode.group,
      ShotMode.selfie,
    ]);
    expect(
      ShotModePolicy.normalizeVisibleMode(ShotMode.landscape),
      ShotMode.portrait,
    );
    expect(ShotModePolicy.canAutoCapture(ShotMode.portrait), isTrue);
    expect(ShotModePolicy.canAutoCapture(ShotMode.selfie), isFalse);
    expect(ShotModePolicy.nativeAnalysisModeFor(ShotMode.selfie), 'face_only');
    expect(
      ShotModePolicy.nativeAnalysisModeFor(ShotMode.object),
      'object_only',
    );
  });

  test('auto capture waits for a stable ready frame before capture', () {
    final controller = AutoCaptureController();
    final start = DateTime(2026);

    var decision = controller.evaluate(
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    expect(decision, AutoCaptureDecision.wait);

    decision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 900)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    expect(decision, AutoCaptureDecision.wait);

    decision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.51,
      subjectY: 0.35,
      lastShotAt: null,
    );
    expect(decision, AutoCaptureDecision.capture);
  });

  test('auto capture resets when subject is lost', () {
    final controller = AutoCaptureController();
    final start = DateTime(2026);

    controller.evaluate(
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    controller.evaluate(
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: false,
      compositionReady: false,
      eyesOpen: true,
      subjectX: null,
      subjectY: null,
      lastShotAt: null,
    );
    final decision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 2200)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );

    expect(decision, AutoCaptureDecision.wait);
  });

  test('auto capture waits when the frame moves too much', () {
    final controller = AutoCaptureController();
    final start = DateTime(2026);

    controller.evaluate(
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.50,
      subjectY: 0.35,
      lastShotAt: null,
    );
    final shakyDecision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.62,
      subjectY: 0.35,
      lastShotAt: null,
    );
    final stableAgainDecision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 2200)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.62,
      subjectY: 0.35,
      lastShotAt: null,
    );

    expect(shakyDecision, AutoCaptureDecision.wait);
    expect(stableAgainDecision, AutoCaptureDecision.capture);
  });

  test('auto capture waits when detected eyes are closed', () {
    final controller = AutoCaptureController();
    final start = DateTime(2026);

    controller.evaluate(
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    final decision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: false,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );

    expect(decision, AutoCaptureDecision.wait);
  });

  test('auto capture respects cooldown edge cases', () {
    final start = DateTime(2026);
    final blockedByCooldown = _primeAutoCapture(
      AutoCaptureController(),
      start,
      lastShotAt: start.subtract(const Duration(milliseconds: 3300)),
    );
    final afterCooldown = _primeAutoCapture(
      AutoCaptureController(),
      start,
      lastShotAt: start.subtract(const Duration(milliseconds: 3500)),
    );

    expect(blockedByCooldown, AutoCaptureDecision.wait);
    expect(afterCooldown, AutoCaptureDecision.capture);
  });

  test('auto capture resets when AI is disabled', () {
    final controller = AutoCaptureController();
    final start = DateTime(2026);

    controller.evaluate(
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    controller.evaluate(
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: false,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    final decision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 2200)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );

    expect(decision, AutoCaptureDecision.wait);
  });

  test('auto capture waits for selfie mode', () {
    final decision = _primeAutoCapture(
      AutoCaptureController(),
      DateTime(2026),
      canAutoCaptureMode: ShotModePolicy.canAutoCapture(ShotMode.selfie),
    );

    expect(decision, AutoCaptureDecision.wait);
  });

  test('auto capture resets when camera is suspended', () {
    final controller = AutoCaptureController();
    final start = DateTime(2026);

    controller.evaluate(
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    controller.evaluate(
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: true,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );
    final decision = controller.evaluate(
      now: start.add(const Duration(milliseconds: 2200)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      hasFreshAnalysis: true,
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: true,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );

    expect(decision, AutoCaptureDecision.wait);
  });

  test('auto capture waits when analysis frame is stale', () {
    final useCase = AutoCaptureUseCase();
    final staleController = AutoCaptureController();
    final freshController = AutoCaptureController();
    final rules = compositionRules[ShotMode.portrait]!;
    final composition = CompositionSession.evaluate(
      rules: rules,
      liveEstimate: CompositionSession.idleEstimateFor(rules),
      hasReliableEstimate: true,
    );
    final start = DateTime(2026);

    useCase.evaluate(
      controller: staleController,
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      composition: composition,
      visionResult: null,
      lastAnalysisFrameAt: start.subtract(const Duration(milliseconds: 700)),
      lastShotAt: null,
    );
    final staleDecision = useCase.evaluate(
      controller: staleController,
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      composition: composition,
      visionResult: null,
      lastAnalysisFrameAt: start.add(const Duration(milliseconds: 299)),
      lastShotAt: null,
    );

    useCase.evaluate(
      controller: freshController,
      now: start,
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      composition: composition,
      visionResult: null,
      lastAnalysisFrameAt: start.subtract(const Duration(milliseconds: 700)),
      lastShotAt: null,
    );
    final freshDecision = useCase.evaluate(
      controller: freshController,
      now: start.add(const Duration(milliseconds: 1100)),
      enabled: true,
      aiEnabled: true,
      canAutoCaptureMode: true,
      isPhotoMode: true,
      isBusy: false,
      isCameraSuspended: false,
      composition: composition,
      visionResult: null,
      lastAnalysisFrameAt: start.add(const Duration(milliseconds: 300)),
      lastShotAt: null,
    );

    expect(staleDecision, AutoCaptureDecision.wait);
    expect(freshDecision, AutoCaptureDecision.capture);
  });
  test('auto capture use case combines composition and eye state', () {
    final useCase = AutoCaptureUseCase();
    final controller = AutoCaptureController();
    final rules = compositionRules[ShotMode.portrait]!;
    final composition = CompositionSession.evaluate(
      rules: rules,
      liveEstimate: CompositionSession.idleEstimateFor(rules),
      hasReliableEstimate: true,
    );
    final start = DateTime(2026);

    expect(
      useCase.evaluate(
        controller: controller,
        now: start,
        enabled: true,
        aiEnabled: true,
        canAutoCaptureMode: true,
        isPhotoMode: true,
        isBusy: false,
        isCameraSuspended: false,
        composition: composition,
        visionResult: null,
        lastAnalysisFrameAt: start,
        lastShotAt: null,
      ),
      AutoCaptureDecision.wait,
    );
    expect(
      useCase.evaluate(
        controller: controller,
        now: start.add(const Duration(milliseconds: 1100)),
        enabled: true,
        aiEnabled: true,
        canAutoCaptureMode: true,
        isPhotoMode: true,
        isBusy: false,
        isCameraSuspended: false,
        composition: composition,
        visionResult: null,
        lastAnalysisFrameAt: start.add(const Duration(milliseconds: 1100)),
        lastShotAt: null,
      ),
      AutoCaptureDecision.capture,
    );
  });

  test('composition session waits without fake ready score', () {
    final rules = compositionRules[ShotMode.portrait]!;
    final session = CompositionSession.evaluate(
      rules: rules,
      liveEstimate: null,
      hasReliableEstimate: false,
    );

    expect(session.hasReliableEstimate, isFalse);
    expect(session.result, isNull);
    expect(session.ready, isFalse);
    expect(session.cue, isNotEmpty);
    expect(session.estimate.bodyCenterX, rules.bodyCenterX);
  });

  test('composition session scores reliable estimates', () {
    final rules = compositionRules[ShotMode.portrait]!;
    final session = CompositionSession.evaluate(
      rules: rules,
      liveEstimate: CompositionSession.idleEstimateFor(rules),
      hasReliableEstimate: true,
    );

    expect(session.hasReliableEstimate, isTrue);
    expect(session.result, isNotNull);
    expect(session.ready, isTrue);
  });

  test('saved shot history stores newest records and feedback', () async {
    SharedPreferences.setMockInitialValues({});
    const store = SavedShotHistoryStore(maxRecords: 3);
    final first = SavedShotRecord(
      id: 'one',
      path: '/tmp/one.jpg',
      shotMode: ShotMode.portrait,
      capturedAt: DateTime(2026),
      compositionScore: 91,
      compositionCue: '珥ъ쁺 OK',
      hadReliableEstimate: true,
      bodyCenterX: 0.48,
      faceCenterY: 0.31,
      eyeLineY: 0.35,
      footLineY: 0.92,
      horizonTiltDeg: 1.2,
      subjectConfidence: 0.86,
      poseConfidence: 0.74,
      autoCaptured: true,
    );
    final second = SavedShotRecord(
      id: 'two',
      path: '/tmp/two.jpg',
      shotMode: ShotMode.group,
      capturedAt: DateTime(2026, 1, 2),
      compositionScore: null,
      compositionCue: 'Finding subject',
      hadReliableEstimate: false,
    );
    final third = SavedShotRecord(
      id: 'three',
      path: '/tmp/three.jpg',
      shotMode: ShotMode.selfie,
      capturedAt: DateTime(2026, 1, 3),
      compositionScore: 88,
      compositionCue: '珥ъ쁺 OK',
      hadReliableEstimate: true,
    );

    await store.add(first);
    await store.add(second);
    await store.add(third);
    await store.markFeedback('three', liked: true);
    final records = await store.load();

    expect(records.map((record) => record.id), ['three', 'two', 'one']);
    expect(records.first.liked, isTrue);
    expect(records[1].hadReliableEstimate, isFalse);
    expect(records[1].autoCaptured, isFalse);
    expect(records.last.bodyCenterX, 0.48);
    expect(records.last.faceCenterY, 0.31);
    expect(records.last.eyeLineY, 0.35);
    expect(records.last.footLineY, 0.92);
    expect(records.last.horizonTiltDeg, 1.2);
    expect(records.last.subjectConfidence, 0.86);
    expect(records.last.poseConfidence, 0.74);
    expect(records.last.autoCaptured, isTrue);
  });
}

AutoCaptureDecision _primeAutoCapture(
  AutoCaptureController controller,
  DateTime start, {
  DateTime? lastShotAt,
  bool canAutoCaptureMode = true,
}) {
  controller.evaluate(
    now: start,
    enabled: true,
    aiEnabled: true,
    canAutoCaptureMode: canAutoCaptureMode,
    isPhotoMode: true,
    isBusy: false,
    isCameraSuspended: false,
    hasFreshAnalysis: true,
    hasReliableSubject: true,
    compositionReady: true,
    eyesOpen: true,
    subjectX: 0.5,
    subjectY: 0.35,
    lastShotAt: lastShotAt,
  );
  return controller.evaluate(
    now: start.add(const Duration(milliseconds: 1100)),
    enabled: true,
    aiEnabled: true,
    canAutoCaptureMode: canAutoCaptureMode,
    isPhotoMode: true,
    isBusy: false,
    isCameraSuspended: false,
    hasFreshAnalysis: true,
    hasReliableSubject: true,
    compositionReady: true,
    eyesOpen: true,
    subjectX: 0.5,
    subjectY: 0.35,
    lastShotAt: lastShotAt,
  );
}
