import '../engine/composition_engine.dart';
import '../rules/composition_rules.dart';

class CompositionSession {
  const CompositionSession({
    required this.estimate,
    required this.result,
    required this.hasReliableEstimate,
  });

  final SubjectEstimate estimate;
  final CompositionResult? result;
  final bool hasReliableEstimate;

  bool get ready => result?.ready ?? false;

  String get cue => result?.cue ?? '사람을 찾는 중';

  static CompositionSession evaluate({
    required CompositionRuleSet rules,
    required SubjectEstimate? liveEstimate,
    required bool hasReliableEstimate,
  }) {
    final estimate = liveEstimate ?? idleEstimateFor(rules);
    return CompositionSession(
      estimate: estimate,
      hasReliableEstimate: hasReliableEstimate,
      result: hasReliableEstimate && liveEstimate != null
          ? scoreComposition(liveEstimate, rules)
          : null,
    );
  }

  static SubjectEstimate idleEstimateFor(CompositionRuleSet rules) {
    return SubjectEstimate(
      bodyCenterX: rules.bodyCenterX,
      faceCenterY: rules.faceCenterY,
      eyeLineY: rules.eyeLineY,
      footLineY: rules.footLineY,
      horizonTiltDeg: 0,
      limbsInsideFrame: true,
    );
  }
}
