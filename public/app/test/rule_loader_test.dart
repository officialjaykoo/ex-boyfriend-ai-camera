import 'package:exbf_camera/models/camera_modes.dart';
import 'package:exbf_camera/rules/composition_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads RAG teacher rules from Flutter assets', () async {
    final document = await loadCompositionRuleDocumentFromAsset();

    expect(document.pipeline, contains('RAG-Anything'));
    expect(document.modes[ShotMode.portrait], isNotNull);
    expect(document.modes[ShotMode.selfie], isNotNull);
    expect(document.modes[ShotMode.stillLife]!.teacherNotes, isNotEmpty);
    expect(
      document.modes[ShotMode.landscape]!.scoreWeights['horizon'],
      greaterThan(0.30),
    );
    expect(document.modes[ShotMode.portrait]!.checklist, isNotEmpty);
    expect(document.modes[ShotMode.selfie]!.captureAdvice, isNotEmpty);
    expect(document.modes[ShotMode.object]!.guideAnchors, isNotEmpty);
  });
}
