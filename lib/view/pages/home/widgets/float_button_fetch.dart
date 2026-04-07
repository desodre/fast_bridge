import 'package:fast_bridge_front/view/pages/home/store/device_store.dart';
import 'package:flutter/material.dart';

class FloatButtonFetch extends StatelessWidget {
  const FloatButtonFetch({super.key, required this.deviceStore});
  final DeviceStore deviceStore;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Refresh devices',
      onPressed: () async {
        await deviceStore.getDevices();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sync, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Device list refreshed',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: const Icon(Icons.refresh_rounded, size: 26),
    );
  }
}
