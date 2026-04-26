import 'dart:io';

import 'package:exbf_camera/vision/vision_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vision model assets exist in the Flutter project', () {
    expect(File(VisionModelAssets.yolo).existsSync(), isTrue);
    expect(File(VisionModelAssets.moveNetThunder).existsSync(), isTrue);
  });
}
