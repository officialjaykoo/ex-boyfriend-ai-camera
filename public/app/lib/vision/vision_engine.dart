import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'vision_models.dart';

class VisionEngine {
  VisionEngine({
    this.yoloAsset = VisionModelAssets.yolo,
    this.moveNetAsset = VisionModelAssets.moveNetThunder,
  });

  static const _cocoLabels = [
    'person',
    'bicycle',
    'car',
    'motorcycle',
    'airplane',
    'bus',
    'train',
    'truck',
    'boat',
    'traffic light',
    'fire hydrant',
    'stop sign',
    'parking meter',
    'bench',
    'bird',
    'cat',
    'dog',
    'horse',
    'sheep',
    'cow',
    'elephant',
    'bear',
    'zebra',
    'giraffe',
    'backpack',
    'umbrella',
    'handbag',
    'tie',
    'suitcase',
    'frisbee',
    'skis',
    'snowboard',
    'sports ball',
    'kite',
    'baseball bat',
    'baseball glove',
    'skateboard',
    'surfboard',
    'tennis racket',
    'bottle',
    'wine glass',
    'cup',
    'fork',
    'knife',
    'spoon',
    'bowl',
    'banana',
    'apple',
    'sandwich',
    'orange',
    'broccoli',
    'carrot',
    'hot dog',
    'pizza',
    'donut',
    'cake',
    'chair',
    'couch',
    'potted plant',
    'bed',
    'dining table',
    'toilet',
    'tv',
    'laptop',
    'mouse',
    'remote',
    'keyboard',
    'cell phone',
    'microwave',
    'oven',
    'toaster',
    'sink',
    'refrigerator',
    'book',
    'clock',
    'vase',
    'scissors',
    'teddy bear',
    'hair drier',
    'toothbrush',
  ];

  static const _poseNames = [
    'nose',
    'left_eye',
    'right_eye',
    'left_ear',
    'right_ear',
    'left_shoulder',
    'right_shoulder',
    'left_elbow',
    'right_elbow',
    'left_wrist',
    'right_wrist',
    'left_hip',
    'right_hip',
    'left_knee',
    'right_knee',
    'left_ankle',
    'right_ankle',
  ];

  final String yoloAsset;
  final String moveNetAsset;

  Interpreter? _yolo;
  Interpreter? _moveNet;
  VisionModelStatus? _status;
  List<DetectedObject> _lastObjects = const [];
  int _analysisCount = 0;

  bool get isLoaded => _yolo != null && _moveNet != null;
  VisionModelStatus? get status => _status;

  Future<void> load() async {
    final options = InterpreterOptions()..threads = 2;
    _yolo = await Interpreter.fromAsset(yoloAsset, options: options);
    _moveNet = await Interpreter.fromAsset(moveNetAsset, options: options);
    _status = VisionModelStatus(
      yoloInputShape: List<int>.from(_yolo!.getInputTensor(0).shape),
      yoloOutputShape: List<int>.from(_yolo!.getOutputTensor(0).shape),
      moveNetInputShape: List<int>.from(_moveNet!.getInputTensor(0).shape),
      moveNetOutputShape: List<int>.from(_moveNet!.getOutputTensor(0).shape),
    );
  }

  Future<void> close() async {
    _yolo?.close();
    _moveNet?.close();
    _yolo = null;
    _moveNet = null;
    _status = null;
  }

  Future<VisionFrameResult> analyzeImage(img.Image rgb) async {
    final yolo = _yolo;
    final moveNet = _moveNet;
    if (yolo == null || moveNet == null) {
      return const VisionFrameResult(objects: [], pose: [], processingMs: 0);
    }

    final started = DateTime.now();

    _analysisCount += 1;
    final shouldRunYolo = _analysisCount == 1 || _analysisCount % 3 == 0;
    final objects = shouldRunYolo ? _runYolo(yolo, rgb) : _lastObjects;
    if (shouldRunYolo) {
      _lastObjects = objects;
    }
    final pose = _runMoveNet(moveNet, rgb);

    return VisionFrameResult(
      objects: objects,
      pose: pose,
      processingMs: DateTime.now().difference(started).inMilliseconds,
    );
  }

  List<DetectedObject> _runYolo(Interpreter interpreter, img.Image rgb) {
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final inputSize = inputShape.length >= 3 ? inputShape[1] : 640;
    final resized = img.copyResize(rgb, width: inputSize, height: inputSize);
    final input = _imageToFloatInput(resized, normalize: true);
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List<double>.filled(outputShape[2], 0),
      ),
    );

    interpreter.run(input.buffer, output);
    return _decodeYolo(output.first, inputSize);
  }

  List<PoseKeypoint> _runMoveNet(Interpreter interpreter, img.Image rgb) {
    final inputTensor = interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];
    final resized = img.copyResize(rgb, width: inputWidth, height: inputHeight);
    final input = switch (inputTensor.type) {
      TensorType.uint8 => _imageToUint8Input(resized),
      TensorType.float16 ||
      TensorType.float32 => _imageToFloatInput(resized, normalize: false),
      _ => _imageToFloatInput(resized, normalize: false),
    };
    final output = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(17, (_) => List<double>.filled(3, 0)),
      ),
    );

    interpreter.run(input.buffer, output);
    return _decodeMoveNet(output.first.first);
  }

  List<DetectedObject> _decodeYolo(List<List<double>> output, int inputSize) {
    if (output.length < 5) return const [];
    final boxes = output[0].length;
    final detections = <DetectedObject>[];

    for (var i = 0; i < boxes; i++) {
      var bestScore = 0.0;
      var bestClass = 0;
      for (var classIndex = 4; classIndex < output.length; classIndex++) {
        final score = output[classIndex][i];
        if (score > bestScore) {
          bestScore = score;
          bestClass = classIndex - 4;
        }
      }
      if (bestScore < 0.35 || bestClass >= _cocoLabels.length) continue;

      final rawCx = output[0][i];
      final rawCy = output[1][i];
      final rawWidth = output[2][i];
      final rawHeight = output[3][i];
      final scale =
          math.max(math.max(rawCx, rawCy), math.max(rawWidth, rawHeight)) <= 2
          ? 1.0
          : inputSize.toDouble();
      final cx = rawCx / scale;
      final cy = rawCy / scale;
      final width = rawWidth / scale;
      final height = rawHeight / scale;
      if (width <= 0.01 || height <= 0.01) continue;
      detections.add(
        DetectedObject(
          label: _cocoLabels[bestClass],
          confidence: bestScore,
          x: (cx - width / 2).clamp(0, 1).toDouble(),
          y: (cy - height / 2).clamp(0, 1).toDouble(),
          width: width.clamp(0, 1).toDouble(),
          height: height.clamp(0, 1).toDouble(),
        ),
      );
    }

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections.take(20).toList(growable: false);
  }

  List<PoseKeypoint> _decodeMoveNet(List<List<double>> output) {
    final keypoints = <PoseKeypoint>[];
    for (var i = 0; i < math.min(output.length, _poseNames.length); i++) {
      final point = output[i];
      keypoints.add(
        PoseKeypoint(
          name: _poseNames[i],
          y: point[0].clamp(0, 1).toDouble(),
          x: point[1].clamp(0, 1).toDouble(),
          confidence: point[2].clamp(0, 1).toDouble(),
        ),
      );
    }
    return keypoints;
  }

  Float32List _imageToFloatInput(img.Image image, {required bool normalize}) {
    final input = Float32List(image.width * image.height * 3);
    var index = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final scale = normalize ? 255.0 : 1.0;
        input[index++] = pixel.r / scale;
        input[index++] = pixel.g / scale;
        input[index++] = pixel.b / scale;
      }
    }
    return input;
  }

  Uint8List _imageToUint8Input(img.Image image) {
    final input = Uint8List(image.width * image.height * 3);
    var index = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        input[index++] = pixel.r.toInt();
        input[index++] = pixel.g.toInt();
        input[index++] = pixel.b.toInt();
      }
    }
    return input;
  }
}
