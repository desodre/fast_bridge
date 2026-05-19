import 'dart:async';
import 'dart:ui';

import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/foundation.dart';

enum ConnState { idle, fetchingInfo, connectingWs, streaming, error }

class FullControlViewModel {
  final String serial;
  final DeviceRepository _repository = DeviceRepository();

  FullControlViewModel({required this.serial});

  Timer? _frameTimer;
  ScreenInfo? _screenInfo;

  final ValueNotifier<ConnState> state = ValueNotifier(ConnState.idle);
  final ValueNotifier<Uint8List?> frame = ValueNotifier(null);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<void> connect() async {
    _cleanup();
    state.value = ConnState.fetchingInfo;
    error.value = null;

    try {
      _screenInfo = await _repository
          .getScreenInfo(serial: serial)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      state.value = ConnState.error;
      error.value = 'Failed to get screen info: $e';
      return;
    }

    state.value = ConnState.streaming;
    await _captureFrame();
    _frameTimer = Timer.periodic(const Duration(milliseconds: 350), (_) async {
      await _captureFrame();
    });
  }

  Future<void> _captureFrame() async {
    try {
      frame.value = await _repository.getScreenshot(serial: serial);
    } catch (e) {
      state.value = ConnState.error;
      error.value = 'Failed to capture frame: $e';
      _frameTimer?.cancel();
      _frameTimer = null;
    }
  }

  Future<void> sendTouch(
    String type,
    Offset localPosition,
    Size widgetSize,
  ) async {
    if (_screenInfo == null) {
      return;
    }

    final deviceW = _screenInfo!.width.toDouble();
    final deviceH = _screenInfo!.height.toDouble();
    final deviceAspect = deviceW / deviceH;
    final widgetAspect = widgetSize.width / widgetSize.height;

    double imgW;
    double imgH;
    double imgX;
    double imgY;

    if (deviceAspect > widgetAspect) {
      imgW = widgetSize.width;
      imgH = imgW / deviceAspect;
      imgX = 0;
      imgY = (widgetSize.height - imgH) / 2;
    } else {
      imgH = widgetSize.height;
      imgW = imgH * deviceAspect;
      imgY = 0;
      imgX = (widgetSize.width - imgW) / 2;
    }

    final xP = (localPosition.dx - imgX) / imgW;
    final yP = (localPosition.dy - imgY) / imgH;

    if (xP < 0 || xP > 1 || yP < 0 || yP > 1) {
      return;
    }

    final tapX = xP * deviceW;
    final tapY = yP * deviceH;

    try {
      if (type == 'touchDown' || type == 'touchUp') {
        await _repository.tap(serial: serial, x: tapX, y: tapY);
      }
    } catch (e) {
      state.value = ConnState.error;
      error.value = 'Touch command failed: $e';
    }
  }

  Future<void> sendKeyEvent(int keycode) async {
    try {
      await _repository.sendKeyEvent(serial: serial, keycode: keycode);
    } catch (e) {
      state.value = ConnState.error;
      error.value = 'Key event failed: $e';
    }
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty) {
      return;
    }
    await _repository.sendText(serial: serial, text: text);
  }

  void _cleanup() {
    _frameTimer?.cancel();
    _frameTimer = null;
    frame.value = null;
  }

  void dispose() {
    _cleanup();
    state.dispose();
    frame.dispose();
    error.dispose();
  }
}
