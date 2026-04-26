import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../vision/vision_models.dart';
import 'composition_engine.dart';

VisionFrameResult? transformVisionForViewport(
  VisionFrameResult? result,
  double? viewportAspectRatio,
) {
  if (result == null || viewportAspectRatio == null) return result;
  if (result.sourceWidth <= 0 || result.sourceHeight <= 0) return result;

  final rotation = ((result.rotationDegrees % 360) + 360) % 360;
  final displayWidth = rotation == 90 || rotation == 270
      ? result.sourceHeight.toDouble()
      : result.sourceWidth.toDouble();
  final displayHeight = rotation == 90 || rotation == 270
      ? result.sourceWidth.toDouble()
      : result.sourceHeight.toDouble();
  if (displayWidth <= 0 || displayHeight <= 0) return result;

  final imageAspect = displayWidth / displayHeight;
  final mapper = _ViewportMapper(imageAspect, viewportAspectRatio);
  return result.copyWith(
    objects: result.objects
        .map((object) => mapper.mapObject(object))
        .where((object) => object.width > 0.01 && object.height > 0.01)
        .toList(growable: false),
    faces: result.faces
        .map((face) => mapper.mapFace(face))
        .where((face) => face.width > 0.01 && face.height > 0.01)
        .toList(growable: false),
    pose: result.pose
        .map(
          (point) =>
              point.copyWith(x: mapper.mapX(point.x), y: mapper.mapY(point.y)),
        )
        .toList(growable: false),
  );
}

SubjectEstimate? estimateSelfieFaceFromVision(VisionFrameResult? result) {
  if (result == null || result.faces.isEmpty) return null;
  final faces = [...result.faces]
    ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
  final face = faces.first;
  final eyeLineY = _averageOffsetY([face.leftEye, face.rightEye]);
  final centerX = face.nose?.dx ?? face.x + face.width / 2;
  final centerY = face.nose?.dy ?? face.y + face.height * 0.48;
  return SubjectEstimate(
    bodyCenterX: centerX.clamp(0, 1).toDouble(),
    faceCenterY: centerY.clamp(0, 1).toDouble(),
    eyeLineY: (eyeLineY ?? (face.y + face.height * 0.38))
        .clamp(0, 1)
        .toDouble(),
    footLineY: (face.y + face.height * 1.85).clamp(0, 1).toDouble(),
    horizonTiltDeg: face.headEulerZ,
    limbsInsideFrame: true,
    subjectConfidence: face.confidence.clamp(0, 1).toDouble(),
    poseConfidence: 0,
  );
}

SubjectEstimate? estimateObjectFromVision(VisionFrameResult? result) {
  if (result == null || result.objects.isEmpty) return null;
  final objects = [...result.objects]
    ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
  final object = objects.firstWhere(
    (item) => item.label != 'person',
    orElse: () => objects.first,
  );
  final centerX = object.x + object.width / 2;
  final centerY = object.y + object.height / 2;
  return SubjectEstimate(
    bodyCenterX: centerX.clamp(0, 1).toDouble(),
    faceCenterY: centerY.clamp(0, 1).toDouble(),
    eyeLineY: centerY.clamp(0, 1).toDouble(),
    footLineY: (object.y + object.height).clamp(0, 1).toDouble(),
    horizonTiltDeg: 0,
    limbsInsideFrame:
        object.x > 0.02 &&
        object.y > 0.02 &&
        object.x + object.width < 0.98 &&
        object.y + object.height < 0.98,
    subjectConfidence: object.confidence.clamp(0, 1).toDouble(),
    poseConfidence: 0,
  );
}

SubjectEstimate? estimateSubjectFromVision(VisionFrameResult? result) {
  if (result == null) return null;

  final person = _bestPerson(result.objects);
  final pose = {for (final point in result.pose) point.name: point};
  final visiblePose = result.pose
      .where((point) => point.confidence >= 0.20)
      .toList();
  if (person == null && visiblePose.length < 4) return null;

  final leftEye = pose['left_eye'];
  final rightEye = pose['right_eye'];
  final nose = pose['nose'];
  final leftShoulder = pose['left_shoulder'];
  final rightShoulder = pose['right_shoulder'];
  final leftAnkle = pose['left_ankle'];
  final rightAnkle = pose['right_ankle'];

  final bodyCenterX = person != null
      ? person.x + person.width / 2
      : _averageX(visiblePose).clamp(0, 1).toDouble();
  final faceCenterY =
      _averageVisibleY([nose, leftEye, rightEye]) ??
      (person != null ? person.y + person.height * 0.18 : 0.32);
  final eyeLineY = _averageVisibleY([leftEye, rightEye]) ?? faceCenterY;
  final footLineY =
      _averageVisibleY([leftAnkle, rightAnkle]) ??
      (person != null ? person.y + person.height : 0.90);
  final limbsInsideFrame = _limbsInsideFrame([leftAnkle, rightAnkle], person);
  final shoulderTilt = _tiltDegrees(leftShoulder, rightShoulder);
  final subjectConfidence = person?.confidence ?? 0.0;
  final poseConfidence = visiblePose.isEmpty
      ? 0.0
      : visiblePose.map((point) => point.confidence).reduce((a, b) => a + b) /
            visiblePose.length;

  return SubjectEstimate(
    bodyCenterX: bodyCenterX.clamp(0, 1).toDouble(),
    faceCenterY: faceCenterY.clamp(0, 1).toDouble(),
    eyeLineY: eyeLineY.clamp(0, 1).toDouble(),
    footLineY: footLineY.clamp(0, 1).toDouble(),
    horizonTiltDeg: shoulderTilt,
    limbsInsideFrame: limbsInsideFrame,
    subjectConfidence: subjectConfidence,
    poseConfidence: poseConfidence,
  );
}

DetectedObject? _bestPerson(List<DetectedObject> objects) {
  final people = objects.where((object) => object.label == 'person').toList()
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  return people.isEmpty ? null : people.first;
}

double _averageX(List<PoseKeypoint> points) {
  if (points.isEmpty) return 0.5;
  return points.map((point) => point.x).reduce((a, b) => a + b) / points.length;
}

double? _averageVisibleY(List<PoseKeypoint?> points) {
  final visible = points
      .whereType<PoseKeypoint>()
      .where((point) => point.confidence >= 0.20)
      .toList();
  if (visible.isEmpty) return null;
  return visible.map((point) => point.y).reduce((a, b) => a + b) /
      visible.length;
}

double? _averageOffsetY(List<Offset?> points) {
  final visible = points.whereType<Offset>().toList();
  if (visible.isEmpty) return null;
  return visible.map((point) => point.dy).reduce((a, b) => a + b) /
      visible.length;
}

bool _limbsInsideFrame(List<PoseKeypoint?> points, DetectedObject? person) {
  final visible = points
      .whereType<PoseKeypoint>()
      .where((point) => point.confidence >= 0.20)
      .toList();
  if (visible.isNotEmpty) {
    return visible.every(
      (point) => point.y < 0.98 && point.x > 0.02 && point.x < 0.98,
    );
  }
  if (person == null) return false;
  return person.y > 0.01 && person.y + person.height < 0.99;
}

double _tiltDegrees(PoseKeypoint? left, PoseKeypoint? right) {
  if (left == null || right == null) return 0;
  if (left.confidence < 0.20 || right.confidence < 0.20) return 0;
  final radians = math.atan2(right.y - left.y, right.x - left.x);
  return radians * 180 / math.pi;
}

class _ViewportMapper {
  const _ViewportMapper(this.imageAspect, this.viewportAspect);

  final double imageAspect;
  final double viewportAspect;

  bool get _cropX => imageAspect > viewportAspect;

  double get _visibleX {
    if (!_cropX) return 1;
    return (viewportAspect / imageAspect).clamp(0.01, 1).toDouble();
  }

  double get _visibleY {
    if (_cropX) return 1;
    return (imageAspect / viewportAspect).clamp(0.01, 1).toDouble();
  }

  double mapX(double x) {
    if (!_cropX) return x.clamp(0, 1).toDouble();
    final crop = (1 - _visibleX) / 2;
    return ((x - crop) / _visibleX).clamp(0, 1).toDouble();
  }

  double mapY(double y) {
    if (_cropX) return y.clamp(0, 1).toDouble();
    final crop = (1 - _visibleY) / 2;
    return ((y - crop) / _visibleY).clamp(0, 1).toDouble();
  }

  DetectedObject mapObject(DetectedObject object) {
    final left = mapX(object.x);
    final top = mapY(object.y);
    final right = mapX(object.x + object.width);
    final bottom = mapY(object.y + object.height);
    return object.copyWith(
      x: math.min(left, right),
      y: math.min(top, bottom),
      width: (right - left).abs().clamp(0, 1).toDouble(),
      height: (bottom - top).abs().clamp(0, 1).toDouble(),
    );
  }

  Offset? mapOffset(Offset? point) {
    if (point == null) return null;
    return Offset(mapX(point.dx), mapY(point.dy));
  }

  DetectedFace mapFace(DetectedFace face) {
    final left = mapX(face.x);
    final top = mapY(face.y);
    final right = mapX(face.x + face.width);
    final bottom = mapY(face.y + face.height);
    return face.copyWith(
      x: math.min(left, right),
      y: math.min(top, bottom),
      width: (right - left).abs().clamp(0, 1).toDouble(),
      height: (bottom - top).abs().clamp(0, 1).toDouble(),
      leftEye: mapOffset(face.leftEye),
      rightEye: mapOffset(face.rightEye),
      nose: mapOffset(face.nose),
    );
  }
}
