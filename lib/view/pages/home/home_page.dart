import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/view/pages/home/store/device_store.dart';
import 'package:fast_bridge_front/view/pages/home/widgets/custom_button.dart';
import 'package:fast_bridge_front/view/pages/home/widgets/float_button_fetch.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final deviceStore = DeviceStore();

  @override
  void initState() {
    super.initState();
    deviceStore.getDevices();
    deviceStore.devices.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Theme.of(context).primaryColor,
      floatingActionButton: FloatButtonFetch(deviceStore:deviceStore),
      body: DemoWindow(devices: deviceStore.devices.value,),
    );
  }
}


class DemoWindow extends StatelessWidget {
  const DemoWindow({super.key, required this.devices});
  final List<DeviceInfo> devices;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: devices.isNotEmpty ? List.generate(devices.length, (index){
          return PresetationWidget(device:devices[index]);
        }) : [Text('No devices found')],
      ),
    );
  }
}



class PresetationWidget extends StatelessWidget {
  final DeviceInfo device;
  const PresetationWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .center,
      spacing: 10,
      children: [
        SelectableText(device.state),
        SelectableText(device.devPath),
        CustomButton(serial: device.serialNo),
        
      ],
    );
  }
}