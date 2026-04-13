import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel {
  final DeviceRepository _repository = DeviceRepository();

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<DeviceInfo>> devices = ValueNotifier([]);
  final ValueNotifier<String> erro = ValueNotifier('');

  Future<void> getDevices() async {
    isLoading.value = true;
    erro.value = '';
    try {
      devices.value = await _repository.getDevices();
    } catch (e) {
      erro.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    devices.dispose();
    erro.dispose();
  }
}
