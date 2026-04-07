import 'dart:typed_data';
import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/hierarchy_tree_view.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/node_preview_data.dart';
import 'package:flutter/material.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key, required this.serial});
  final String serial;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final DeviceRepository repository = DeviceRepository();
  Future<Uint8List>? deviceScreenshot;
  Future<UiHierarchy>? deviceUiHierarchy;
  UiNode? selectedUiNode;
  Future<ScreenInfo>? screenInfo;

  void refresh() {
    deviceScreenshot = repository.getScreenshot(serial: widget.serial);
    deviceUiHierarchy = repository.getUiHierarchy(serial: widget.serial);
  }

  @override
  void initState() {
    screenInfo = repository.getScreenInfo(serial: widget.serial);
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.android_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(widget.serial, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() => refresh()),
            icon: const Icon(Icons.refresh_rounded),
          ),
          FutureBuilder<ScreenInfo>(
            future: screenInfo,
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  avatar: Icon(Icons.aspect_ratio_rounded, size: 16, color: cs.primary),
                  label: Text('${snap.data!.width} × ${snap.data!.height}',
                      style: const TextStyle(fontSize: 12)),
                  side: BorderSide(color: cs.primary.withAlpha(60)),
                  backgroundColor: cs.primary.withAlpha(20),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Full Control',
            onPressed: () => Navigator.pushNamed(context, '/device/${widget.serial}/full_control'),
            icon: Icon(Icons.cast_connected_rounded, color: cs.primary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<ScreenInfo>(
          future: screenInfo,
          builder: (context, screenInfoSnapshot) {
            if (screenInfoSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (screenInfoSnapshot.hasError || !screenInfoSnapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    const Text('Could not load screen info.'),
                  ],
                ),
              );
            }
            final screenData = screenInfoSnapshot.data!;
            final nativeWidth = screenData.width.toDouble();
            final nativeHeight = screenData.height.toDouble();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Screenshot panel
                Expanded(
                  flex: 1,
                  child: Card(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FutureBuilder<Uint8List>(
                        future: deviceScreenshot,
                        builder: (context, screenshotSnapshot) {
                          if (screenshotSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (screenshotSnapshot.hasError || !screenshotSnapshot.hasData) {
                            return const Center(child: Text('Could not load screenshot.'));
                          }
                          final screenshotBytes = screenshotSnapshot.data!;

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final availableHeight = constraints.maxHeight;
                              final nativeAspectRatio = nativeWidth / nativeHeight;
                              final availableAspectRatio = availableWidth / availableHeight;

                              double displayWidth;
                              double displayHeight;

                              if (nativeAspectRatio > availableAspectRatio) {
                                displayWidth = availableWidth;
                                displayHeight = displayWidth / nativeAspectRatio;
                              } else {
                                displayHeight = availableHeight;
                                displayWidth = displayHeight * nativeAspectRatio;
                              }

                              final scale = displayWidth / nativeWidth;

                              return Center(
                                child: SizedBox(
                                  width: displayWidth,
                                  height: displayHeight,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.memory(screenshotBytes, gaplessPlayback: true),
                                      ),
                                      if (selectedUiNode != null)
                                        Positioned(
                                          left: selectedUiNode!.bounds.x1 * scale,
                                          top: selectedUiNode!.bounds.y1 * scale,
                                          width: selectedUiNode!.bounds.width * scale,
                                          height: selectedUiNode!.bounds.height * scale,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: cs.primary, width: 2),
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
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Node properties panel
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
                              const SizedBox(width: 6),
                              Text('Node Properties', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const Divider(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              child: NodePreviewData(node: selectedUiNode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Hierarchy tree panel
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_tree_rounded, size: 18, color: cs.primary),
                              const SizedBox(width: 6),
                              Text('UI Hierarchy', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const Divider(height: 20),
                          Expanded(
                            child: FutureBuilder<UiHierarchy>(
                              future: deviceUiHierarchy,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return HierarchyTreeView(
                                    hierarchy: snapshot.data!,
                                    selectedNode: selectedUiNode,
                                    onNodeSelected: (value) {
                                      setState(() { selectedUiNode = value; });
                                    },
                                  );
                                } else {
                                  return const Center(child: CircularProgressIndicator());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
