enum ShotMode {
  portrait('인물'),
  selfie('셀피'),
  group('2인'),
  landscape('풍경'),
  stillLife('정물'),
  object('사물'),
  candid('스냅'),
  lowLight('저조도');

  const ShotMode(this.label);
  final String label;
}

enum ToolPanel { none, sticker, style, set, retouch }

enum CaptureMode { manual, auto }

enum MediaMode { photo, video }

enum StickerEffect { none, bunnyEars, sunglasses, pigNose }

enum StyleEffect { none, vivid, warm, cool, film, mono }

enum SetEffect { none, solo, cafe, travel, food, night }

enum RetouchEffect { none, skin, bright, jaw, eyes, nose }

enum ImageOutputFormat { jpg, png }
