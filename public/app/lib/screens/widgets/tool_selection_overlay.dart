part of 'package:exbf_camera/screens/camera_screen.dart';

class _ToolSelectionOverlay extends StatelessWidget {
  const _ToolSelectionOverlay({
    required this.panel,
    required this.options,
    required this.selectedSticker,
    required this.selectedStyle,
    required this.selectedSet,
    required this.selectedRetouch,
    required this.onStickerSelected,
    required this.onStyleSelected,
    required this.onSetSelected,
    required this.onRetouchSelected,
    required this.onClose,
  });

  final ToolPanel panel;
  final List<String> options;
  final StickerEffect selectedSticker;
  final StyleEffect selectedStyle;
  final SetEffect selectedSet;
  final RetouchEffect selectedRetouch;
  final ValueChanged<StickerEffect> onStickerSelected;
  final ValueChanged<StyleEffect> onStyleSelected;
  final ValueChanged<SetEffect> onSetSelected;
  final ValueChanged<RetouchEffect> onRetouchSelected;
  final VoidCallback onClose;

  String get _title {
    return switch (panel) {
      ToolPanel.sticker => '스티커',
      ToolPanel.style => '색감',
      ToolPanel.set => '무드',
      ToolPanel.retouch => '리터치',
      ToolPanel.none => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 238,
      child: Container(
        color: Colors.white.withValues(alpha: 0.96),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      tooltip: '닫기',
                      padding: EdgeInsets.zero,
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Expanded(child: _buildPanel()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return switch (panel) {
      ToolPanel.sticker => _StickerPicker(
        selectedSticker: selectedSticker,
        onStickerSelected: onStickerSelected,
      ),
      ToolPanel.style => _StylePicker(
        selectedStyle: selectedStyle,
        onStyleSelected: onStyleSelected,
      ),
      ToolPanel.set => _SetPicker(
        selectedSet: selectedSet,
        onSetSelected: onSetSelected,
      ),
      ToolPanel.retouch => _RetouchPicker(
        selectedRetouch: selectedRetouch,
        onRetouchSelected: onRetouchSelected,
      ),
      ToolPanel.none => _GenericToolChoices(
        options: options,
        onSelected: onClose,
      ),
    };
  }
}

class _GenericToolChoices extends StatelessWidget {
  const _GenericToolChoices({required this.options, required this.onSelected});

  final List<String> options;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return _ToolGrid(
      children: options.map((name) {
        return _ToolTileShell(
          selected: false,
          onTap: onSelected,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        );
      }).toList(),
    );
  }
}

class _StickerPicker extends StatelessWidget {
  const _StickerPicker({
    required this.selectedSticker,
    required this.onStickerSelected,
  });

  final StickerEffect selectedSticker;
  final ValueChanged<StickerEffect> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    const stickers = [
      StickerEffect.none,
      StickerEffect.bunnyEars,
      StickerEffect.sunglasses,
      StickerEffect.pigNose,
    ];

    return _ToolGrid(
      children: stickers.map((sticker) {
        return _StickerChoice(
          sticker: sticker,
          selected: selectedSticker == sticker,
          onTap: () => onStickerSelected(sticker),
        );
      }).toList(),
    );
  }
}

class _StickerChoice extends StatelessWidget {
  const _StickerChoice({
    required this.sticker,
    required this.selected,
    required this.onTap,
  });

  final StickerEffect sticker;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ToolTileShell(
      selected: selected,
      onTap: onTap,
      child: CustomPaint(painter: _StickerSamplePainter(sticker)),
    );
  }
}

class _StylePicker extends StatelessWidget {
  const _StylePicker({
    required this.selectedStyle,
    required this.onStyleSelected,
  });

  final StyleEffect selectedStyle;
  final ValueChanged<StyleEffect> onStyleSelected;

  @override
  Widget build(BuildContext context) {
    const styles = [
      StyleEffect.none,
      StyleEffect.vivid,
      StyleEffect.warm,
      StyleEffect.cool,
      StyleEffect.film,
      StyleEffect.mono,
    ];
    return _EffectChoiceWrap(
      children: styles.map((style) {
        return _EffectChoice(
          selected: selectedStyle == style,
          onTap: () => onStyleSelected(style),
          label: style.label,
          painter: _StyleSamplePainter(style),
        );
      }).toList(),
    );
  }
}

class _SetPicker extends StatelessWidget {
  const _SetPicker({required this.selectedSet, required this.onSetSelected});

  final SetEffect selectedSet;
  final ValueChanged<SetEffect> onSetSelected;

  @override
  Widget build(BuildContext context) {
    const sets = [
      SetEffect.none,
      SetEffect.solo,
      SetEffect.cafe,
      SetEffect.travel,
      SetEffect.food,
      SetEffect.night,
    ];
    return _EffectChoiceWrap(
      children: sets.map((set) {
        return _EffectChoice(
          selected: selectedSet == set,
          onTap: () => onSetSelected(set),
          label: set.label,
          painter: _SetSamplePainter(set),
        );
      }).toList(),
    );
  }
}

class _RetouchPicker extends StatelessWidget {
  const _RetouchPicker({
    required this.selectedRetouch,
    required this.onRetouchSelected,
  });

  final RetouchEffect selectedRetouch;
  final ValueChanged<RetouchEffect> onRetouchSelected;

  @override
  Widget build(BuildContext context) {
    const retouches = [
      RetouchEffect.none,
      RetouchEffect.skin,
      RetouchEffect.bright,
      RetouchEffect.jaw,
      RetouchEffect.eyes,
      RetouchEffect.nose,
    ];
    return _EffectChoiceWrap(
      children: retouches.map((retouch) {
        return _EffectChoice(
          selected: selectedRetouch == retouch,
          onTap: () => onRetouchSelected(retouch),
          label: retouch.label,
          painter: _RetouchSamplePainter(retouch),
        );
      }).toList(),
    );
  }
}

class _EffectChoiceWrap extends StatelessWidget {
  const _EffectChoiceWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _ToolGrid(children: children);
  }
}

class _EffectChoice extends StatelessWidget {
  const _EffectChoice({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.painter,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return _ToolTileShell(
      selected: selected,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: painter),
            Positioned(
              left: 3,
              right: 3,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.08,
      children: children,
    );
  }
}

class _ToolTileShell extends StatelessWidget {
  const _ToolTileShell({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accentPink : const Color(0xffdedee4),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

class _StyleSamplePainter extends CustomPainter {
  const _StyleSamplePainter(this.style);

  final StyleEffect style;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = switch (style) {
      StyleEffect.vivid => const [Color(0xff18c37e), Color(0xffffd447)],
      StyleEffect.warm => const [Color(0xffffb36a), Color(0xffff7eb3)],
      StyleEffect.cool => const [Color(0xff41c7ff), Color(0xffd6fff5)],
      StyleEffect.film => const [Color(0xff476a58), Color(0xffd7c39b)],
      StyleEffect.mono => const [Color(0xff111111), Color(0xffeeeeee)],
      StyleEffect.none => const [Color(0xfff1f1f3), Color(0xffd7d7dc)],
    };
    _SampleArt.drawGradientScene(canvas, size, colors);
    if (style == StyleEffect.none) {
      _StickerArt.drawNone(
        canvas,
        Offset(size.width / 2, size.height / 2),
        math.min(size.width, size.height) * 0.62,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StyleSamplePainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _SetSamplePainter extends CustomPainter {
  const _SetSamplePainter(this.set);

  final SetEffect set;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = switch (set) {
      SetEffect.solo => const [Color(0xff5f8cc7), Color(0xfff5d6d6)],
      SetEffect.cafe => const [Color(0xff8d5a3b), Color(0xffffd7a8)],
      SetEffect.travel => const [Color(0xff42a5f5), Color(0xffffd54f)],
      SetEffect.food => const [Color(0xffff7043), Color(0xfffff3b0)],
      SetEffect.night => const [Color(0xff151a33), Color(0xff7b61ff)],
      SetEffect.none => const [Color(0xfff1f1f3), Color(0xffd7d7dc)],
    };
    _SampleArt.drawGradientScene(canvas, size, colors);
    _SampleArt.drawSetIcon(canvas, size, set);
  }

  @override
  bool shouldRepaint(covariant _SetSamplePainter oldDelegate) {
    return oldDelegate.set != set;
  }
}

class _RetouchSamplePainter extends CustomPainter {
  const _RetouchSamplePainter(this.retouch);

  final RetouchEffect retouch;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = switch (retouch) {
      RetouchEffect.skin => const [Color(0xffffc0d9), Color(0xffffefe8)],
      RetouchEffect.bright => const [Color(0xfffff59d), Color(0xffffffff)],
      RetouchEffect.jaw => const [Color(0xffc9f0ff), Color(0xffffeef8)],
      RetouchEffect.eyes => const [Color(0xffe6ddff), Color(0xffffffff)],
      RetouchEffect.nose => const [Color(0xffffdf9e), Color(0xfffff7e8)],
      RetouchEffect.none => const [Color(0xfff1f1f3), Color(0xffd7d7dc)],
    };
    _SampleArt.drawGradientScene(canvas, size, colors);
    _SampleArt.drawFace(canvas, size);
    if (retouch == RetouchEffect.none) {
      _StickerArt.drawNone(
        canvas,
        Offset(size.width / 2, size.height / 2),
        math.min(size.width, size.height) * 0.62,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RetouchSamplePainter oldDelegate) {
    return oldDelegate.retouch != retouch;
  }
}

class _SampleArt {
  const _SampleArt._();

  static void drawGradientScene(Canvas canvas, Size size, List<Color> colors) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final sun = Paint()..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.24), 9, sun);
    final hill = Paint()..color = Colors.black.withValues(alpha: 0.12);
    final path = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.48,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hill);
  }

  static void drawSetIcon(Canvas canvas, Size size, SetEffect set) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    switch (set) {
      case SetEffect.solo:
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.43),
          12,
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.72),
            width: 44,
            height: 34,
          ),
          math.pi * 1.08,
          math.pi * 0.84,
          false,
          paint,
        );
      case SetEffect.cafe:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.30, size.height * 0.42, 28, 20),
            const Radius.circular(5),
          ),
          paint,
        );
        canvas.drawArc(
          Rect.fromLTWH(size.width * 0.58, size.height * 0.45, 16, 14),
          -math.pi / 2,
          math.pi,
          false,
          paint,
        );
      case SetEffect.travel:
        canvas.drawLine(
          Offset(size.width * 0.28, size.height * 0.66),
          Offset(size.width * 0.72, size.height * 0.36),
          paint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.36),
          6,
          paint,
        );
      case SetEffect.food:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.56),
            width: size.width * 0.48,
            height: size.height * 0.30,
          ),
          paint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.46, size.height * 0.54),
          8,
          paint,
        );
      case SetEffect.night:
        canvas.drawCircle(
          Offset(size.width * 0.44, size.height * 0.42),
          13,
          paint,
        );
        canvas.drawCircle(
          Offset(size.width * 0.50, size.height * 0.37),
          13,
          Paint()..color = Colors.white.withValues(alpha: 0.38),
        );
      case SetEffect.none:
        _StickerArt.drawNone(
          canvas,
          Offset(size.width / 2, size.height / 2),
          44,
        );
    }
  }

  static void drawFace(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.82);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.53),
        width: 36,
        height: 46,
      ),
      paint,
    );
    final blush = Paint()..color = _accentPink.withValues(alpha: 0.36);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.58), 5, blush);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.58), 5, blush);
  }
}

extension _StyleEffectLabel on StyleEffect {
  String get label {
    return switch (this) {
      StyleEffect.none => '없음',
      StyleEffect.vivid => '선명',
      StyleEffect.warm => '따뜻',
      StyleEffect.cool => '청량',
      StyleEffect.film => '필름',
      StyleEffect.mono => '흑백',
    };
  }
}

extension _SetEffectLabel on SetEffect {
  String get label {
    return switch (this) {
      SetEffect.none => '없음',
      SetEffect.solo => '인물',
      SetEffect.cafe => '카페',
      SetEffect.travel => '여행',
      SetEffect.food => '음식',
      SetEffect.night => '야간',
    };
  }
}

extension _RetouchEffectLabel on RetouchEffect {
  String get label {
    return switch (this) {
      RetouchEffect.none => '없음',
      RetouchEffect.skin => '피부',
      RetouchEffect.bright => '밝게',
      RetouchEffect.jaw => '턱선',
      RetouchEffect.eyes => '눈',
      RetouchEffect.nose => '코',
    };
  }
}
