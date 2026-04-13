import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/hierarchy_panel.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/node_properties_panel.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/screenshot_panel.dart';
import 'package:fast_bridge_front/view/widgets/device_nav_dropdown.dart';
import 'package:fast_bridge_front/view/widgets/loading_indicator.dart';
import 'package:fast_bridge_front/viewmodel/device_viewmodel.dart';
import 'package:flutter/material.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key, required this.serial});
  final String serial;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late final DeviceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DeviceViewModel(serial: widget.serial);
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
            Text(
              widget.serial,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _viewModel.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          ValueListenableBuilder<ScreenInfo?>(
            valueListenable: _viewModel.screenInfo,
            builder: (context, info, _) {
              if (info == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  avatar: Icon(
                    Icons.aspect_ratio_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  label: Text(
                    '${info.width} × ${info.height}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  side: BorderSide(color: cs.primary.withAlpha(60)),
                  backgroundColor: cs.primary.withAlpha(20),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
          DeviceNavDropdown(
            serial: widget.serial,
            current: DeviceSection.device,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ValueListenableBuilder<bool>(
          valueListenable: _viewModel.isLoadingScreenInfo,
          builder: (context, loading, _) {
            if (loading) {
              return const LoadingIndicator();
            }
            return ValueListenableBuilder<ScreenInfo?>(
              valueListenable: _viewModel.screenInfo,
              builder: (context, info, _) {
                if (info == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: cs.error,
                        ),
                        const SizedBox(height: 12),
                        const Text('Could not load screen info.'),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ScreenshotPanel(
                        screenshot: _viewModel.screenshot,
                        isLoading: _viewModel.isLoadingScreenshot,
                        nativeWidth: info.width.toDouble(),
                        nativeHeight: info.height.toDouble(),
                        selectedNode: _viewModel.selectedNode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NodePropertiesPanel(
                        selectedNode: _viewModel.selectedNode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: HierarchyPanel(
                        hierarchy: _viewModel.hierarchy,
                        isLoading: _viewModel.isLoadingHierarchy,
                        selectedNode: _viewModel.selectedNode,
                        onNodeSelected: _viewModel.selectNode,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
