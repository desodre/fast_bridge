import 'package:fast_bridge_front/view/pages/home/store/device_store.dart';
import 'package:flutter/material.dart';

class FloatButtonFetch extends StatelessWidget {
  const FloatButtonFetch({super.key, required this.deviceStore});
  final DeviceStore deviceStore;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(tooltip: 'Refresh',
      child: SizedBox(
        width: 50,
        height: 50,
        child: Image.asset('assets/icons/refresh_icon.gif'),
      ),
      onPressed: () async {
        deviceStore.getDevices();
        deviceStore.devices.addListener(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: .floating, content: Text('Devices updated')),
        );
      },
    );
  }
}
