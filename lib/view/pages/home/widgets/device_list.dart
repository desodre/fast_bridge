import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/view/pages/home/widgets/device_card.dart';
import 'package:fast_bridge_front/view/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({
    super.key,
    required this.devices,
    required this.isLoading,
  });

  final List<DeviceInfo> devices;
  final ValueNotifier<bool> isLoading;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoading,
      builder: (context, loading, _) {
        if (loading && devices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (devices.isEmpty) {
          return const EmptyState(
            icon: Icons.phonelink_off_rounded,
            title: 'No devices found',
            subtitle: 'Connect a device via USB and tap refresh',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: devices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => DeviceCard(device: devices[index]),
        );
      },
    );
  }
}
