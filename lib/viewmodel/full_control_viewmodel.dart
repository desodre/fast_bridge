import 'dart:async';
import 'dart:ui';

import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:fast_bridge_front/data/streaming/h264_local_http_relay.dart';
import 'package:flutter/foundation.dart';

enum ConnState { idle, fetchingInfo, connectingWs, streaming, error }

class FullControlViewModel {
  final String serial;
  final DeviceRepository _repository = DeviceRepository();

  FullControlViewModel({required this.serial});

  H264LocalHttpRelay? _relay;
  ScreenInfo? _screenInfo;

  final ValueNotifier<ConnState> state = ValueNotifier(ConnState.idle);
  final ValueNotifier<Uri?> streamUrl = ValueNotifier(null);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<void> connect() async {
    await _cleanup();
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

    state.value = ConnState.connectingWs;
    try {
      final source = _repository.getH264VideoStream(serial: serial);
      final relay = H264LocalHttpRelay(source: source);
      final localUrl = await relay.start();
      _relay = relay;
      streamUrl.value = localUrl;
    } catch (e) {
      state.value = ConnState.error;
      error.value = 'Failed to start local stream relay: $e';
      return;
    }

    state.value = ConnState.streaming;
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

  Future<void> _cleanup() async {
    streamUrl.value = null;
    final relay = _relay;
    _relay = null;
    if (relay != null) {
      await relay.stop();
    }
  }

  void dispose() {
    unawaited(_cleanup());
    state.dispose();
    streamUrl.dispose();
    error.dispose();
  }
}
