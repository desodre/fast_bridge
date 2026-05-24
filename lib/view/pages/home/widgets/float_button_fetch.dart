import 'package:fast_bridge_front/view/pages/home/store/device_store.dart';
import 'package:fast_bridge_front/view/ui/toast_service.dart';
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
        ToastService.info('Device list refreshed', context: context);
      },
      child: const Icon(Icons.refresh_rounded, size: 26),
    );
  }
}
