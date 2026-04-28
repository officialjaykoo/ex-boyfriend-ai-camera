import 'dart:math' as math;

import '../rules/composition_rules.dart';

class SubjectEstimate {
  const SubjectEstimate({
    required this.bodyCenterX,
    required this.faceCenterY,
    required this.eyeLineY,
    required this.footLineY,
    required this.horizonTiltDeg,
    required this.limbsInsideFrame,
    this.subjectConfidence = 0,
    this.poseConfidence = 0,
  });

  final double bodyCenterX;
  final double faceCenterY;
  final double eyeLineY;
  final double footLineY;
  final double horizonTiltDeg;
  final bool limbsInsideFrame;
  final double subjectConfidence;
  final double poseConfidence;
}

class CompositionResult {
  const CompositionResult({
    required this.score,
    required this.ready,
    required this.cue,
    required this.breakdown,
  });

  final int score;
  final bool ready;
  final String cue;
  final CompositionBreakdown breakdown;
}

class CompositionBreakdown {
  const CompositionBreakdown({
    required this.subjectPosition,
    required this.facePosition,
    required this.eyeLine,
    required this.horizon,
    required this.footSafety,
    required this.limbSafety,
    required this.detectionConfidence,
  });

  final double subjectPosition;
  final double facePosition;
  final double eyeLine;
  final double horizon;
  final double footSafety;
  final double limbSafety;
  final double detectionConfidence;
}

double _clampUnit(double value) => value.clamp(0, 1).toDouble();

double _proximity(double actual, double target, double tolerance) {
  final distance = (actual - target).abs();
  return _clampUnit(1 - distance / tolerance);
}

CompositionResult scoreComposition(
  SubjectEstimate estimate,
  CompositionRuleSet rules,
) {
  final subjectPosition = _proximity(
    estimate.bodyCenterX,
    rules.bodyCenterX,
    0.22,
  );
  final facePosition = _proximity(
    estimate.faceCenterY,
    rules.faceCenterY,
    0.18,
  );
  final eyeLine = _proximity(estimate.eyeLineY, rules.eyeLineY, 0.14);
  final footSafety = _proximity(estimate.footLineY, rules.footLineY, 0.12);
  final horizon = _clampUnit(1 - estimate.horizonTiltDeg.abs() / 8);
  final limbSafety = estimate.limbsInsideFrame ? 1.0 : 0.35;
  final detectionConfidence =
      estimate.subjectConfidence == 0 && estimate.poseConfidence == 0
      ? 1.0
      : estimate.poseConfidence == 0
      ? _clampUnit(estimate.subjectConfidence)
      : _clampUnit(
          0.55 * estimate.subjectConfidence + 0.45 * estimate.poseConfidence,
        );

  final rawScore =
      100 *
      (rules.scoreWeight('subjectPosition') * subjectPosition +
          rules.scoreWeight('facePosition') * facePosition +
          rules.scoreWeight('eyeLine') * eyeLine +
          rules.scoreWeight('horizon') * horizon +
          rules.scoreWeight('footSafety') * footSafety +
          rules.scoreWeight('limbSafety') * limbSafety +
          rules.scoreWeight('detectionConfidence') * detectionConfidence);
  final score = rawScore.round();

  return CompositionResult(
    score: score,
    ready: score >= rules.autoCaptureThreshold,
    cue: _compositionCue(estimate, rules, score),
    breakdown: CompositionBreakdown(
      subjectPosition: subjectPosition,
      facePosition: facePosition,
      eyeLine: eyeLine,
      horizon: horizon,
      footSafety: footSafety,
      limbSafety: limbSafety,
      detectionConfidence: detectionConfidence,
    ),
  );
}

String _compositionCue(
  SubjectEstimate estimate,
  CompositionRuleSet rules,
  int score,
) {
  if (score >= rules.autoCaptureThreshold) return '촬영 OK';

  return switch (rules.guideType) {
    'horizon_thirds' => _landscapeCue(estimate, rules),
    'subject_thirds' || 'subject_viewpoint' => _subjectCue(estimate, rules),
    'stable_level' => _lowLightCue(estimate, rules),
    _ => _peopleCue(estimate, rules),
  };
}

String _peopleCue(SubjectEstimate estimate, CompositionRuleSet rules) {
  final positionCue = _cameraPositionCue(estimate, rules);
  if (positionCue != null) return positionCue;
  if (!estimate.limbsInsideFrame) return '카메라를 뒤로 빼요';
  if (estimate.horizonTiltDeg.abs() > 2.5) return '카메라 각도를 바로 세워요';
  return _firstAdvice(rules, '카메라를 가까이 대요');
}

String _landscapeCue(SubjectEstimate estimate, CompositionRuleSet rules) {
  if (estimate.horizonTiltDeg.abs() > 1.6) return '카메라 각도를 바로 세워요';
  return _firstAdvice(rules, '지평선을 1/3에 맞춰요');
}

String _subjectCue(SubjectEstimate estimate, CompositionRuleSet rules) {
  final positionCue = _cameraPositionCue(estimate, rules);
  if (positionCue != null) return positionCue;
  if (!estimate.limbsInsideFrame) return '카메라를 살짝 뒤로 빼요';
  return _firstAdvice(rules, '피사체가 더 잘 보이게 해요');
}

String _lowLightCue(SubjectEstimate estimate, CompositionRuleSet rules) {
  if (estimate.horizonTiltDeg.abs() > 1.6) return '카메라 각도를 바로 세워요';
  if (!estimate.limbsInsideFrame) return '카메라를 몸에 붙여 고정해요';
  final positionCue = _cameraPositionCue(estimate, rules);
  if (positionCue != null) return positionCue;
  return _firstAdvice(rules, '잠깐 멈추고 촬영해요');
}

String? _cameraPositionCue(SubjectEstimate estimate, CompositionRuleSet rules) {
  if (estimate.faceCenterY < rules.faceCenterY - 0.06) {
    return '카메라를 위로 올리세요';
  }
  if (estimate.faceCenterY > rules.faceCenterY + 0.06) {
    return '카메라를 아래로 내리세요';
  }
  if (estimate.bodyCenterX < rules.bodyCenterX - 0.08) {
    return '카메라를 왼쪽으로 옮겨요';
  }
  if (estimate.bodyCenterX > rules.bodyCenterX + 0.08) {
    return '카메라를 오른쪽으로 옮겨요';
  }
  return null;
}

String _firstAdvice(CompositionRuleSet rules, String fallback) {
  return rules.captureAdvice.isNotEmpty ? rules.captureAdvice.first : fallback;
}

SubjectEstimate makePreviewEstimate(int tick) {
  final drift = math.sin(tick / 1200);
  final settle = 1 - math.min(tick / 9000, 1);

  return SubjectEstimate(
    bodyCenterX: 0.42 + 0.12 * drift * settle,
    faceCenterY: 0.31 + 0.08 * math.cos(tick / 1500) * settle,
    eyeLineY: 0.34 + 0.06 * math.sin(tick / 1700) * settle,
    footLineY: 0.91 - 0.04 * math.cos(tick / 1300) * settle,
    horizonTiltDeg: 5 * math.sin(tick / 1800) * settle,
    limbsInsideFrame: tick % 7000 > 900,
    subjectConfidence: 0.92,
    poseConfidence: 0.86,
  );
}
