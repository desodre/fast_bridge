import 'package:flutter/material.dart';

enum DeviceSection { device, terminal, fileManager, appManager,  fullControl }

extension DeviceSectionX on DeviceSection {
  String label() => switch (this) {
        DeviceSection.device => 'Device',
        DeviceSection.terminal => 'Terminal',
        DeviceSection.fileManager => 'File Manager',
        DeviceSection.appManager => 'App Manager',
        DeviceSection.fullControl => 'Full Control',
      };

  IconData icon() => switch (this) {
        DeviceSection.device => Icons.phone_android_rounded,
        DeviceSection.terminal => Icons.terminal_rounded,
        DeviceSection.fileManager => Icons.folder_rounded,
        DeviceSection.appManager => Icons.apps_rounded,
        DeviceSection.fullControl => Icons.fullscreen_rounded,
      };

  String? route(String serial) => switch (this) {
        DeviceSection.device => '/device/$serial',
        DeviceSection.fileManager => '/device/$serial/file_manager',
        DeviceSection.terminal => null,
        DeviceSection.appManager => null,
        DeviceSection.fullControl => '/device/$serial/full_control',
      };
}

class DeviceNavDropdown extends StatelessWidget {
  const DeviceNavDropdown({
    super.key,
    required this.serial,
    required this.current,
  });

  final String serial;
  final DeviceSection current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<DeviceSection>(
      initialValue: current,
      tooltip: 'Navigate',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(current.icon(), size: 18, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            current.label(),
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
      onSelected: (section) {
        if (section == current) return;

        final route = section.route(serial);
        if (route != null) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      itemBuilder: (context) => DeviceSection.values.map((section) {
        final isSelected = section == current;
        return PopupMenuItem(
          value: section,
          child: Row(
            children: [
              Icon(
                section.icon(),
                size: 18,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withAlpha(180),
              ),
              const SizedBox(width: 10),
              Text(
                section.label(),
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
