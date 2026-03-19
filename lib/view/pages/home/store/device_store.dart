import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/material.dart';

class DeviceStore {
  final DeviceRepository repository = DeviceRepository();

  //loagind
  final ValueNotifier<bool>  isLoading = ValueNotifier<bool>(false);


  //state

  final ValueNotifier<List<DeviceInfo>> devices = ValueNotifier<List<DeviceInfo>>([]);


  //erro

  final ValueNotifier<String> erro  = .new('');


  Future<void> getDevices() async {
    isLoading.value = true;

    try {
      final result = await repository.getDevices();
      devices.value = result;
    } catch (e) {
      erro.value = e.toString();
    } finally {
      isLoading.value = false;

    }

  }
}