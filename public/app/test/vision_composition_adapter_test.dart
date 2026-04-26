import 'package:exbf_camera/engine/vision_composition_adapter.dart';
import 'package:exbf_camera/vision/vision_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vision result converts to subject estimate', () {
    final estimate = estimateSubjectFromVision(
      const VisionFrameResult(
        objects: [
          DetectedObject(
            label: 'person',
            confidence: 0.92,
            x: 0.30,
            y: 0.10,
            width: 0.40,
            height: 0.82,
          ),
        ],
        pose: [
          PoseKeypoint(name: 'left_eye', x: 0.45, y: 0.28, confidence: 0.90),
          PoseKeypoint(name: 'right_eye', x: 0.55, y: 0.28, confidence: 0.91),
          PoseKeypoint(
            name: 'left_shoulder',
            x: 0.42,
            y: 0.42,
            confidence: 0.88,
          ),
          PoseKeypoint(
            name: 'right_shoulder',
            x: 0.58,
            y: 0.43,
            confidence: 0.88,
          ),
          PoseKeypoint(name: 'left_ankle', x: 0.44, y: 0.91, confidence: 0.80),
          PoseKeypoint(name: 'right_ankle', x: 0.56, y: 0.91, confidence: 0.80),
        ],
        processingMs: 120,
      ),
    );

    expect(estimate, isNotNull);
    expect(estimate!.bodyCenterX, closeTo(0.50, 0.01));
    expect(estimate.eyeLineY, closeTo(0.28, 0.01));
    expect(estimate.limbsInsideFrame, isTrue);
  });
}
