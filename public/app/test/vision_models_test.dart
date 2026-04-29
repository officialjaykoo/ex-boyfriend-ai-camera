import 'dart:io';

import 'package:exbf_camera/vision/vision_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vision model assets exist in the Flutter project', () {
    expect(File(VisionModelAssets.yolo).existsSync(), isTrue);
    expect(File(VisionModelAssets.moveNetThunder).existsSync(), isTrue);
  });

  test(
    'detected face treats missing eye probabilities as unknown not closed',
    () {
      final face = DetectedFace.fromMap(const {
        'x': 0.2,
        'y': 0.2,
        'width': 0.3,
        'height': 0.3,
      });

      expect(face.hasEyeOpenProbabilities, isFalse);
      expect(face.eyesLikelyOpen, isTrue);
    },
  );

  test('detected face blocks auto capture when eye probability is low', () {
    final face = DetectedFace.fromMap(const {
      'x': 0.2,
      'y': 0.2,
      'width': 0.3,
      'height': 0.3,
      'leftEyeOpenProbability': 0.9,
      'rightEyeOpenProbability': 0.2,
    });

    expect(face.hasEyeOpenProbabilities, isTrue);
    expect(face.eyesLikelyOpen, isFalse);
  });
}
