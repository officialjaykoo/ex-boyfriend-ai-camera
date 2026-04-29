import 'package:exbf_camera/models/camera_modes.dart';
import 'package:exbf_camera/product/auto_capture_controller.dart';
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
      hasReliableSubject: true,
      compositionReady: true,
      eyesOpen: false,
      subjectX: 0.5,
      subjectY: 0.35,
      lastShotAt: null,
    );

    expect(decision, AutoCaptureDecision.wait);
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
    expect(session.cue, '사람을 찾는 중');
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
    const store = SavedShotHistoryStore(maxRecords: 2);
    final first = SavedShotRecord(
      id: 'one',
      path: '/tmp/one.jpg',
      shotMode: ShotMode.portrait,
      capturedAt: DateTime(2026),
      compositionScore: 91,
      compositionCue: '촬영 OK',
      hadReliableEstimate: true,
    );
    final second = SavedShotRecord(
      id: 'two',
      path: '/tmp/two.jpg',
      shotMode: ShotMode.group,
      capturedAt: DateTime(2026, 1, 2),
      compositionScore: null,
      compositionCue: '사람을 찾는 중',
      hadReliableEstimate: false,
    );
    final third = SavedShotRecord(
      id: 'three',
      path: '/tmp/three.jpg',
      shotMode: ShotMode.selfie,
      capturedAt: DateTime(2026, 1, 3),
      compositionScore: 88,
      compositionCue: '촬영 OK',
      hadReliableEstimate: true,
    );

    await store.add(first);
    await store.add(second);
    await store.add(third);
    await store.markFeedback('three', liked: true);
    final records = await store.load();

    expect(records.map((record) => record.id), ['three', 'two']);
    expect(records.first.liked, isTrue);
    expect(records.last.hadReliableEstimate, isFalse);
  });
}
