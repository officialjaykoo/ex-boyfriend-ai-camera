part of 'package:exbf_camera/screens/camera_screen.dart';

class _CompositionController {
  Map<ShotMode, CompositionRuleSet> rules = compositionRules;

  CompositionRuleSet rulesFor(ShotMode mode) {
    return rules[mode] ?? compositionRules[ShotMode.portrait]!;
  }

  CompositionSession evaluate({
    required ShotMode mode,
    required SubjectEstimate? liveEstimate,
    required bool hasReliableEstimate,
  }) {
    return CompositionSession.evaluate(
      rules: rulesFor(mode),
      liveEstimate: liveEstimate,
      hasReliableEstimate: hasReliableEstimate,
    );
  }
}
