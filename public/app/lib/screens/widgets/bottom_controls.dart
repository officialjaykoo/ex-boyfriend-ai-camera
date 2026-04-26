part of 'package:exbf_camera/screens/camera_screen.dart';

const _accentPink = Color(0xffe84db8);

class _BottomControls extends StatefulWidget {
  const _BottomControls({
    required this.shotMode,
    required this.mediaMode,
    required this.toolPanel,
    required this.isRecording,
    required this.isBusy,
    required this.onShotModeChanged,
    required this.onMediaModeChanged,
    required this.onToolSelected,
    required this.onGalleryTap,
    required this.onShutterTap,
  });

  final ShotMode shotMode;
  final MediaMode mediaMode;
  final ToolPanel toolPanel;
  final bool isRecording;
  final bool isBusy;
  final ValueChanged<ShotMode> onShotModeChanged;
  final ValueChanged<MediaMode> onMediaModeChanged;
  final ValueChanged<ToolPanel> onToolSelected;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;

  @override
  State<_BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<_BottomControls> {
  late final PageController _modeController;

  @override
  void initState() {
    super.initState();
    _modeController = PageController(
      viewportFraction: 0.24,
      initialPage: ShotMode.values.indexOf(widget.shotMode),
    );
  }

  @override
  void didUpdateWidget(covariant _BottomControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shotMode != widget.shotMode && _modeController.hasClients) {
      final target = ShotMode.values.indexOf(widget.shotMode);
      final current = (_modeController.page ?? _modeController.initialPage)
          .round();
      if (target != current) {
        _modeController.animateToPage(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _modeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: PageView.builder(
              controller: _modeController,
              itemCount: ShotMode.values.length,
              padEnds: true,
              onPageChanged: (index) =>
                  widget.onShotModeChanged(ShotMode.values[index]),
              itemBuilder: (context, index) {
                final mode = ShotMode.values[index];
                final selected = mode == widget.shotMode;
                return Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _modeController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                      widget.onShotModeChanged(mode);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: selected ? 34 : 28,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accentPink.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        mode.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? _accentPink : Colors.black45,
                          fontSize: selected ? 14 : 12,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ToolButton(
                icon: Icons.mood_outlined,
                label: '스티커',
                selected: widget.toolPanel == ToolPanel.sticker,
                onTap: () => widget.onToolSelected(ToolPanel.sticker),
              ),
              _ToolButton(
                icon: Icons.auto_awesome_outlined,
                label: '색감',
                selected: widget.toolPanel == ToolPanel.style,
                onTap: () => widget.onToolSelected(ToolPanel.style),
              ),
              _ShutterButton(
                mediaMode: widget.mediaMode,
                isRecording: widget.isRecording,
                isBusy: widget.isBusy,
                onTap: widget.onShutterTap,
              ),
              _ToolButton(
                icon: Icons.filter_vintage_outlined,
                label: '무드',
                selected: widget.toolPanel == ToolPanel.set,
                onTap: () => widget.onToolSelected(ToolPanel.set),
              ),
              _ToolButton(
                icon: Icons.brush_outlined,
                label: '리터치',
                selected: widget.toolPanel == ToolPanel.retouch,
                onTap: () => widget.onToolSelected(ToolPanel.retouch),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MediaTextButton(
                icon: Icons.photo_outlined,
                label: '앨범',
                selected: false,
                onTap: widget.onGalleryTap,
              ),
              _MediaTextButton(
                icon: Icons.videocam_outlined,
                label: '동영상',
                selected: widget.mediaMode == MediaMode.video,
                onTap: () => widget.onMediaModeChanged(MediaMode.video),
              ),
              _MediaTextButton(
                icon: Icons.camera_alt_outlined,
                label: '사진',
                selected: widget.mediaMode == MediaMode.photo,
                onTap: () => widget.onMediaModeChanged(MediaMode.photo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? _accentPink : Colors.black54,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? _accentPink : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTextButton extends StatelessWidget {
  const _MediaTextButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? _accentPink : Colors.black45;
    final textColor = selected ? _accentPink : Colors.black45;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: iconColor),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({
    required this.mediaMode,
    required this.isRecording,
    required this.isBusy,
    required this.onTap,
  });

  final MediaMode mediaMode;
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 210),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.88), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.05), weight: 24),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1), weight: 28),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _glow = Tween<double>(
      begin: 0.16,
      end: 0.42,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _press() async {
    if (widget.isBusy) return;
    widget.onTap();
    await _controller.forward(from: 0);
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _press,
      onTapDown: widget.isBusy ? null : (_) => _controller.forward(from: 0),
      onTapCancel: widget.isBusy ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: widget.isBusy ? 0.56 : 1,
              child: Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (widget.isRecording
                                  ? const Color(0xffff4a4a)
                                  : _accentPink)
                              .withValues(alpha: _glow.value),
                      blurRadius: 22 + 12 * _controller.value,
                      spreadRadius: 2 + 3 * _controller.value,
                    ),
                  ],
                ),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isRecording
                          ? const [Color(0xffff4a4a), Color(0xffb90000)]
                          : const [Color(0xffff94d1), Color(0xffe66bff)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    widget.mediaMode == MediaMode.video
                        ? Icons.videocam
                        : Icons.camera_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
