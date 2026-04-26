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
  if (score >= rules.autoCaptureThreshold) return '지금 촬영';
  if (estimate.faceCenterY < rules.faceCenterY - 0.06) return '폰을 아래로';
  if (estimate.faceCenterY > rules.faceCenterY + 0.06) return '폰을 위로';
  if (estimate.bodyCenterX < rules.bodyCenterX - 0.08) return '오른쪽으로';
  if (estimate.bodyCenterX > rules.bodyCenterX + 0.08) return '왼쪽으로';
  if (estimate.horizonTiltDeg.abs() > 2) return '수평 맞추기';
  if (!estimate.limbsInsideFrame) return '한 걸음 뒤로';
  return rules.captureAdvice.isNotEmpty ? rules.captureAdvice.first : '조금 가까이';
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
