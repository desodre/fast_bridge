import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/hierarchy_panel.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/node_properties_panel.dart';
import 'package:fast_bridge_front/view/pages/device_page/widgets/screenshot_panel.dart';
import 'package:fast_bridge_front/view/pages/full_control_window/full_control_window.dart';
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
          _DevicePageDropdown(serial: widget.serial),
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

enum _DevicePage { device, deviceFullControl, terminal, fileManager, appManager }

class _DevicePageDropdown extends StatelessWidget {
  const _DevicePageDropdown({required this.serial});

  final String serial;

  static const _items = [
    (value: _DevicePage.device, label: 'Device', icon: Icons.phone_android_rounded),
    (value: _DevicePage.deviceFullControl, label: 'Full Control', icon: Icons.videocam_rounded),
    (value: _DevicePage.terminal, label: 'Terminal', icon: Icons.terminal_rounded),
    (value: _DevicePage.fileManager, label: 'File Manager', icon: Icons.folder_rounded),
    (value: _DevicePage.appManager, label: 'App Manager', icon: Icons.apps_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_DevicePage>(
      initialValue: _DevicePage.device,
      tooltip: 'Navigate',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_android_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            'Device',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: cs.primary),
        ],
      ),
      onSelected: (page) {
        switch (page) {
          case _DevicePage.device:
            break;
          case _DevicePage.deviceFullControl:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullControlWindow(serial: serial),
              ),
            );
            break;
          case _DevicePage.terminal:
          case _DevicePage.fileManager:
          case _DevicePage.appManager:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
        }
      },
      itemBuilder: (context) => _items.map((item) {
        final isSelected = item.value == _DevicePage.device;
        return PopupMenuItem(
          value: item.value,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isSelected ? cs.primary : cs.onSurface.withAlpha(180),
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? cs.primary : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check_rounded, size: 16, color: cs.primary),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
