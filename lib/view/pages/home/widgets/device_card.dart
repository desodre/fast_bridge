import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/view/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.device});

  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = device.state == 'device';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/device/${device.serialNo}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.serialNo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      device.devPath,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(isOnline: isOnline, label: device.state),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
