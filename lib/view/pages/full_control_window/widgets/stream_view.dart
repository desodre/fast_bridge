import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class StreamView extends StatefulWidget {
  const StreamView({
    super.key,
    required this.streamUrl,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
  });

  final ValueNotifier<Uri?> streamUrl;
  final void Function(Offset position, Size size) onPointerDown;
  final void Function(Offset position, Size size) onPointerMove;
  final void Function(Offset position, Size size) onPointerUp;

  @override
  State<StreamView> createState() => _StreamViewState();
}

class _StreamViewState extends State<StreamView> {
  late final Player _player;
  late final VideoController _videoController;
  late final VoidCallback _streamUrlListener;
  Uri? _openedUrl;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _streamUrlListener = _handleStreamUrlChange;
    widget.streamUrl.addListener(_streamUrlListener);
    _handleStreamUrlChange();
  }

  @override
  void didUpdateWidget(covariant StreamView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl == widget.streamUrl) {
      return;
    }
    oldWidget.streamUrl.removeListener(_streamUrlListener);
    widget.streamUrl.addListener(_streamUrlListener);
    _openedUrl = null;
    _handleStreamUrlChange();
  }

  Future<void> _handleStreamUrlChange() async {
    final url = widget.streamUrl.value;
    if (url == null || url == _openedUrl) {
      return;
    }

    _openedUrl = url;
    await _player.open(Media(url.toString()));
  }

  @override
  void dispose() {
    widget.streamUrl.removeListener(_streamUrlListener);
    unawaited(_player.stop());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Uri?>(
      valueListenable: widget.streamUrl,
      builder: (context, url, _) {
        if (url == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for video frames...',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final widgetSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return Listener(
              onPointerDown: (e) =>
                  widget.onPointerDown(e.localPosition, widgetSize),
              onPointerMove: (e) =>
                  widget.onPointerMove(e.localPosition, widgetSize),
              onPointerUp: (e) =>
                  widget.onPointerUp(e.localPosition, widgetSize),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Video(
                    controller: _videoController,
                    controls: NoVideoControls,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
