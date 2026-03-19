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
    
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: .center,
          spacing: 5,
          children: [
          Icon(Icons.android_outlined),
            SelectableText(
              widget.serial,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
            IconButton(
            onPressed: () {
              setState(() {
                refresh();
              });
            },
            icon: Icon(Icons.change_circle_outlined),
          ),

        ],
        ),
        actions: [
          FutureBuilder(
            future: screenInfo,
            builder: (context, asyncSnapshot) {
              return  asyncSnapshot.hasData ?  SelectableText("${asyncSnapshot.data!.height.toString()} x ${asyncSnapshot.data!.width.toString()}") : const Text('No data') ;
            }
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<ScreenInfo>(
            future: screenInfo,
            builder: (context, screenInfoSnapshot) {
              if (screenInfoSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (screenInfoSnapshot.hasError || !screenInfoSnapshot.hasData) {
                return const Center(
                    child: Text('Could not load screen info.'));
              }
              final screenData = screenInfoSnapshot.data!;
              final nativeWidth = screenData.width.toDouble();
              final nativeHeight = screenData.height.toDouble();

              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: FutureBuilder<Uint8List>(
                      future: deviceScreenshot,
                      builder: (context, screenshotSnapshot) {
                        if (screenshotSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (screenshotSnapshot.hasError ||
                            !screenshotSnapshot.hasData) {
                          return const Center(
                              child: Text('Could not load screenshot.'));
                        }
                        final screenshotBytes = screenshotSnapshot.data!;

                        return LayoutBuilder(builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final availableHeight = constraints.maxHeight;
                          final nativeAspectRatio = nativeWidth / nativeHeight;
                          final availableAspectRatio =
                              availableWidth / availableHeight;

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
                                    child: Image.memory(screenshotBytes,
                                        gaplessPlayback: true),
                                  ),
                                  if (selectedUiNode != null)
                                    Positioned(
                                      left: selectedUiNode!.bounds.x1 * scale,
                                      top: selectedUiNode!.bounds.y1 * scale,
                                      width:
                                          selectedUiNode!.bounds.width * scale,
                                      height: selectedUiNode!.bounds.height *
                                          scale,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.red, width: 2),
                                          color: Colors.red.withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: NodePreviewData(node: selectedUiNode),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: FutureBuilder(
                      future: deviceUiHierarchy,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return HierarchyTreeView(
                            hierarchy: snapshot.data!,
                            selectedNode: selectedUiNode,
                            onNodeSelected: (value) {
                              setState(() {
                                selectedUiNode = value;
                              });
                            },
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
