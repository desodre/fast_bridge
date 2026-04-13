import 'dart:typed_data';

import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:flutter/material.dart';

class ScreenshotPanel extends StatelessWidget {
  const ScreenshotPanel({
    super.key,
    required this.screenshot,
    required this.isLoading,
    required this.nativeWidth,
    required this.nativeHeight,
    required this.selectedNode,
  });

  final ValueNotifier<Uint8List?> screenshot;
  final ValueNotifier<bool> isLoading;
  final double nativeWidth;
  final double nativeHeight;
  final ValueNotifier<UiNode?> selectedNode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, _) {
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ValueListenableBuilder<Uint8List?>(
              valueListenable: screenshot,
              builder: (context, bytes, _) {
                if (bytes == null) {
                  return const Center(child: Text('Could not load screenshot.'));
                }
                return ValueListenableBuilder<UiNode?>(
                  valueListenable: selectedNode,
                  builder: (context, node, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final availW = constraints.maxWidth;
                        final availH = constraints.maxHeight;
                        final nativeAspect = nativeWidth / nativeHeight;
                        final availAspect = availW / availH;

                        final double dispW;
                        final double dispH;
                        if (nativeAspect > availAspect) {
                          dispW = availW;
                          dispH = dispW / nativeAspect;
                        } else {
                          dispH = availH;
                          dispW = dispH * nativeAspect;
                        }

                        final scale = dispW / nativeWidth;

                        return Center(
                          child: SizedBox(
                            width: dispW,
                            height: dispH,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.memory(
                                    bytes,
                                    gaplessPlayback: true,
                                  ),
                                ),
                                if (node != null)
                                  Positioned(
                                    left: node.bounds.x1 * scale,
                                    top: node.bounds.y1 * scale,
                                    width: node.bounds.width * scale,
                                    height: node.bounds.height * scale,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: cs.primary,
                                          width: 2,
                                        ),
                                        color: cs.primary.withAlpha(25),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
