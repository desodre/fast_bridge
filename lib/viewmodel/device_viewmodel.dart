import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/foundation.dart';

class DeviceViewModel {
  final String serial;
  final DeviceRepository _repository = DeviceRepository();

  DeviceViewModel({required this.serial});

  final ValueNotifier<ScreenInfo?> screenInfo = ValueNotifier(null);
  final ValueNotifier<Uint8List?> screenshot = ValueNotifier(null);
  final ValueNotifier<UiHierarchy?> hierarchy = ValueNotifier(null);
  final ValueNotifier<UiNode?> selectedNode = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingScreenInfo = ValueNotifier(false);
  final ValueNotifier<bool> isLoadingScreenshot = ValueNotifier(false);
  final ValueNotifier<bool> isLoadingHierarchy = ValueNotifier(false);
  final ValueNotifier<String> erro = ValueNotifier('');

  Future<void> init() async {
    await Future.wait([_loadScreenInfo(), refresh()]);
  }

  Future<void> refresh() async {
    await Future.wait([_loadScreenshot(), _loadHierarchy()]);
  }

  Future<void> _loadScreenInfo() async {
    isLoadingScreenInfo.value = true;
    try {
      screenInfo.value = await _repository.getScreenInfo(serial: serial);
    } catch (e) {
      erro.value = e.toString();
    } finally {
      isLoadingScreenInfo.value = false;
    }
  }

  Future<void> _loadScreenshot() async {
    isLoadingScreenshot.value = true;
    try {
      screenshot.value = await _repository.getScreenshot(serial: serial);
    } catch (e) {
      erro.value = e.toString();
    } finally {
      isLoadingScreenshot.value = false;
    }
  }

  Future<void> _loadHierarchy() async {
    isLoadingHierarchy.value = true;
    try {
      hierarchy.value = await _repository.getUiHierarchy(serial: serial);
    } catch (e) {
      erro.value = e.toString();
    } finally {
      isLoadingHierarchy.value = false;
    }
  }

  void selectNode(UiNode? node) {
    selectedNode.value = node;
  }

  void dispose() {
    screenInfo.dispose();
    screenshot.dispose();
    hierarchy.dispose();
    selectedNode.dispose();
    isLoadingScreenInfo.dispose();
    isLoadingScreenshot.dispose();
    isLoadingHierarchy.dispose();
    erro.dispose();
  }
}
