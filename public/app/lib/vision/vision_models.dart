import 'dart:ui' show Offset;

class VisionModelAssets {
  const VisionModelAssets._();

  static const yolo = 'assets/models/yolo11n_float32.tflite';
  static const moveNetThunder = 'assets/models/movenet_thunder_float16.tflite';
}

class VisionModelStatus {
  const VisionModelStatus({
    required this.yoloInputShape,
    required this.yoloOutputShape,
    required this.moveNetInputShape,
    required this.moveNetOutputShape,
  });

  final List<int> yoloInputShape;
  final List<int> yoloOutputShape;
  final List<int> moveNetInputShape;
  final List<int> moveNetOutputShape;
}

class DetectedObject {
  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  factory DetectedObject.fromMap(Map<dynamic, dynamic> map) {
    return DetectedObject(
      label: '${map['label'] ?? 'object'}',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
    );
  }

  DetectedObject copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return DetectedObject(
      label: label,
      confidence: confidence,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

class PoseKeypoint {
  const PoseKeypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  final String name;
  final double x;
  final double y;
  final double confidence;

  factory PoseKeypoint.fromMap(Map<dynamic, dynamic> map) {
    return PoseKeypoint(
      name: '${map['name'] ?? 'point'}',
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  PoseKeypoint copyWith({double? x, double? y}) {
    return PoseKeypoint(
      name: name,
      x: x ?? this.x,
      y: y ?? this.y,
      confidence: confidence,
    );
  }
}

class DetectedFace {
  const DetectedFace({
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.leftEye,
    this.rightEye,
    this.nose,
    this.headEulerY = 0,
    this.headEulerZ = 0,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });

  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
  final Offset? leftEye;
  final Offset? rightEye;
  final Offset? nose;
  final double headEulerY;
  final double headEulerZ;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  factory DetectedFace.fromMap(Map<dynamic, dynamic> map) {
    final landmarks = map['landmarks'] is Map<dynamic, dynamic>
        ? map['landmarks'] as Map<dynamic, dynamic>
        : const <dynamic, dynamic>{};
    return DetectedFace(
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1,
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      leftEye: _offsetFromLandmark(landmarks['leftEye']),
      rightEye: _offsetFromLandmark(landmarks['rightEye']),
      nose: _offsetFromLandmark(landmarks['nose']),
      headEulerY: (map['headEulerY'] as num?)?.toDouble() ?? 0,
      headEulerZ: (map['headEulerZ'] as num?)?.toDouble() ?? 0,
      leftEyeOpenProbability: _optionalProbability(
        map['leftEyeOpenProbability'],
      ),
      rightEyeOpenProbability: _optionalProbability(
        map['rightEyeOpenProbability'],
      ),
    );
  }

  DetectedFace copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    Offset? leftEye,
    Offset? rightEye,
    Offset? nose,
  }) {
    return DetectedFace(
      confidence: confidence,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      leftEye: leftEye ?? this.leftEye,
      rightEye: rightEye ?? this.rightEye,
      nose: nose ?? this.nose,
      headEulerY: headEulerY,
      headEulerZ: headEulerZ,
      leftEyeOpenProbability: leftEyeOpenProbability,
      rightEyeOpenProbability: rightEyeOpenProbability,
    );
  }

  bool get hasEyeOpenProbabilities =>
      leftEyeOpenProbability != null || rightEyeOpenProbability != null;

  bool get eyesLikelyOpen {
    final probabilities = [
      leftEyeOpenProbability,
      rightEyeOpenProbability,
    ].whereType<double>().toList(growable: false);
    if (probabilities.isEmpty) return true;
    return probabilities.every((value) => value >= 0.45);
  }
}

double? _optionalProbability(dynamic value) {
  final probability = (value as num?)?.toDouble();
  if (probability == null || probability < 0) return null;
  return probability.clamp(0, 1).toDouble();
}

Offset? _offsetFromLandmark(dynamic value) {
  if (value is! Map<dynamic, dynamic>) return null;
  return Offset(
    (value['x'] as num?)?.toDouble() ?? 0,
    (value['y'] as num?)?.toDouble() ?? 0,
  );
}

class VisionFrameResult {
  const VisionFrameResult({
    required this.objects,
    required this.pose,
    this.faces = const [],
    required this.processingMs,
    this.rotationDegrees = 0,
    this.sourceWidth = 0,
    this.sourceHeight = 0,
    this.mirrored = false,
  });

  final List<DetectedObject> objects;
  final List<PoseKeypoint> pose;
  final List<DetectedFace> faces;
  final int processingMs;
  final int rotationDegrees;
  final int sourceWidth;
  final int sourceHeight;
  final bool mirrored;

  factory VisionFrameResult.fromNativeMap(Map<dynamic, dynamic> map) {
    final objects = (map['objects'] as List? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(DetectedObject.fromMap)
        .toList(growable: false);
    final pose = (map['pose'] as List? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(PoseKeypoint.fromMap)
        .toList(growable: false);
    final faces = (map['faces'] as List? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(DetectedFace.fromMap)
        .toList(growable: false);
    return VisionFrameResult(
      objects: objects,
      pose: pose,
      faces: faces,
      processingMs: (map['processingMs'] as num?)?.toInt() ?? 0,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toInt() ?? 0,
      sourceWidth: (map['sourceWidth'] as num?)?.toInt() ?? 0,
      sourceHeight: (map['sourceHeight'] as num?)?.toInt() ?? 0,
      mirrored: map['mirrored'] == true,
    );
  }

  VisionFrameResult copyWith({
    List<DetectedObject>? objects,
    List<PoseKeypoint>? pose,
    List<DetectedFace>? faces,
  }) {
    return VisionFrameResult(
      objects: objects ?? this.objects,
      pose: pose ?? this.pose,
      faces: faces ?? this.faces,
      processingMs: processingMs,
      rotationDegrees: rotationDegrees,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      mirrored: mirrored,
    );
  }
}
