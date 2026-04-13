import 'dart:typed_data';
import 'package:flutter/material.dart';

class StreamView extends StatelessWidget {
  const StreamView({
    super.key,
    required this.frame,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
  });

  final ValueNotifier<Uint8List?> frame;
  final void Function(Offset position, Size size) onPointerDown;
  final void Function(Offset position, Size size) onPointerMove;
  final void Function(Offset position, Size size) onPointerUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: frame,
      builder: (context, bytes, _) {
        if (bytes == null) {
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
              onPointerDown: (e) => onPointerDown(e.localPosition, widgetSize),
              onPointerMove: (e) => onPointerMove(e.localPosition, widgetSize),
              onPointerUp: (e) => onPointerUp(e.localPosition, widgetSize),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    gaplessPlayback: true,
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
