import 'package:exbf_camera/engine/composition_engine.dart';
import 'package:exbf_camera/models/camera_modes.dart';
import 'package:exbf_camera/rules/composition_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition score is ready near the target guide', () {
    final rules = compositionRules[ShotMode.stillLife]!;
    final result = scoreComposition(
      SubjectEstimate(
        bodyCenterX: rules.bodyCenterX,
        faceCenterY: rules.faceCenterY,
        eyeLineY: rules.eyeLineY,
        footLineY: rules.footLineY,
        horizonTiltDeg: 0,
        limbsInsideFrame: true,
        subjectConfidence: 0.95,
        poseConfidence: 0.95,
      ),
      rules,
    );

    expect(result.ready, isTrue);
    expect(result.score, greaterThanOrEqualTo(rules.autoCaptureThreshold));
  });

  test('portrait guide uses measured solo portrait anchors', () {
    final rules = compositionRules[ShotMode.portrait]!;

    expect(rules.bodyCenterX, 0.50);
    expect(rules.eyeLineY, lessThan(rules.faceCenterY));
    expect(rules.eyeLineY, closeTo(0.31, 0.001));
    expect(rules.faceCenterY, closeTo(0.36, 0.001));
    expect(rules.footLineY, closeTo(0.90, 0.001));
    expect(rules.autoCaptureThreshold, 87);
  });

  test(
    'people cue tells user to move the camera when subject is off frame',
    () {
      final rules = compositionRules[ShotMode.portrait]!;
      final result = scoreComposition(
        SubjectEstimate(
          bodyCenterX: rules.bodyCenterX + 0.20,
          faceCenterY: rules.faceCenterY,
          eyeLineY: rules.eyeLineY,
          footLineY: rules.footLineY,
          horizonTiltDeg: 0,
          limbsInsideFrame: true,
          subjectConfidence: 0.90,
          poseConfidence: 0.90,
        ),
        rules,
      );

      expect(result.ready, isFalse);
      expect(result.cue, '카메라를 오른쪽으로 옮겨요');
    },
  );

  test('landscape cue prioritizes leveling the camera angle', () {
    final rules = compositionRules[ShotMode.landscape]!;
    final result = scoreComposition(
      SubjectEstimate(
        bodyCenterX: rules.bodyCenterX + 0.20,
        faceCenterY: rules.faceCenterY + 0.10,
        eyeLineY: rules.eyeLineY,
        footLineY: rules.footLineY,
        horizonTiltDeg: 4,
        limbsInsideFrame: true,
        subjectConfidence: 0.90,
        poseConfidence: 0.90,
      ),
      rules,
    );

    expect(result.ready, isFalse);
    expect(result.cue, '카메라 각도를 바로 세워요');
  });

  test('teacher weights make landscape more sensitive to tilted horizons', () {
    final landscapeRules = compositionRules[ShotMode.landscape]!;
    final stillLifeRules = compositionRules[ShotMode.stillLife]!;
    const tiltedEstimate = SubjectEstimate(
      bodyCenterX: 0.50,
      faceCenterY: 0.36,
      eyeLineY: 0.36,
      footLineY: 0.88,
      horizonTiltDeg: 7,
      limbsInsideFrame: true,
      subjectConfidence: 0.95,
      poseConfidence: 0.95,
    );

    final landscape = scoreComposition(tiltedEstimate, landscapeRules);
    final stillLife = scoreComposition(tiltedEstimate, stillLifeRules);

    expect(landscape.score, lessThan(stillLife.score));
  });
}
