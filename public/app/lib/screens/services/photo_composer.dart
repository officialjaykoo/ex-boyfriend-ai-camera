part of 'package:exbf_camera/screens/camera_screen.dart';

extension _PhotoComposer on _CameraScreenState {
  Future<String> _composeEditedPhoto(String path) async {
    final decoded = img.decodeImage(await File(path).readAsBytes());
    if (decoded == null) return path;

    final photo = img.bakeOrientation(decoded);
    final framed = _cropPhotoToSelectedAspect(photo);
    final freshVision = _isVisionFrameFresh
        ? transformVisionForViewport(_visionResult, _previewAspectRatio())
        : null;
    final estimate = _composition
        .evaluate(
          mode: _shotMode,
          liveEstimate: _composition.estimateForMode(
            mode: _shotMode,
            viewportVisionResult: freshVision,
          ),
          hasReliableEstimate: false,
        )
        .estimate;
    final anchors = _FaceStickerAnchor.from(
      freshVision,
      estimate,
      Size(framed.width.toDouble(), framed.height.toDouble()),
      _shotMode,
    );
    final anchor = anchors.first;
    _PhotoEffectProcessor.apply(
      framed,
      style: _ui.styleEffect,
      set: _ui.setEffect,
      retouch: _ui.retouchEffect,
      anchor: anchor,
    );

    if (_ui.stickerEffect != StickerEffect.none) {
      _drawStickerOnPhoto(framed, _ui.stickerEffect, anchors);
    }

    final timestamp = _captureTimestamp();
    final extension = _imageOutputFormat == ImageOutputFormat.jpg
        ? 'jpg'
        : 'png';
    final output = File(
      '${Directory.systemTemp.path}/EXBF_$timestamp.$extension',
    );
    final bytes = _imageOutputFormat == ImageOutputFormat.jpg
        ? img.encodeJpg(framed, quality: _imageQuality)
        : img.encodePng(framed);
    await output.writeAsBytes(bytes);
    return output.path;
  }

  img.Image _cropPhotoToSelectedAspect(img.Image source) {
    final targetAspect = _previewAspectRatio();
    if (targetAspect == null || targetAspect <= 0) return source;
    final sourceAspect = source.width / source.height;
    if ((sourceAspect - targetAspect).abs() < 0.01) return source;

    int x = 0;
    int y = 0;
    int width = source.width;
    int height = source.height;
    if (sourceAspect > targetAspect) {
      width = (source.height * targetAspect).round().clamp(1, source.width);
      x = ((source.width - width) / 2).round();
    } else {
      height = (source.width / targetAspect).round().clamp(1, source.height);
      y = ((source.height - height) / 2).round();
    }
    return img.copyCrop(source, x: x, y: y, width: width, height: height);
  }

  bool get _isVisionFrameFresh {
    return _vision.isAnalysisFresh();
  }

  String _captureTimestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  void _drawStickerOnPhoto(
    img.Image photo,
    StickerEffect sticker,
    List<_FaceStickerAnchor> anchors,
  ) {
    for (final anchor in anchors.take(3)) {
      switch (sticker) {
        case StickerEffect.bunnyEars:
          _RasterStickerArt.drawBunnyEars(
            photo,
            anchor.eyeCenter.translate(0, -anchor.faceWidth * 0.37),
            anchor.faceWidth * 0.80,
          );
        case StickerEffect.sunglasses:
          _RasterStickerArt.drawSunglasses(
            photo,
            anchor.eyeCenter,
            anchor.faceWidth * 0.72,
          );
        case StickerEffect.pigNose:
          _RasterStickerArt.drawPigNose(
            photo,
            anchor.noseCenter,
            anchor.faceWidth * 0.62,
          );
        case StickerEffect.none:
          break;
      }
    }
  }
}
