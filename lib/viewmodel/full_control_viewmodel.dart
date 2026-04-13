import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:fast_bridge_front/data/http/ws_client.dart';
import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/foundation.dart';

enum ConnState { idle, fetchingInfo, connectingWs, streaming, error }

class FullControlViewModel {
  final String serial;
  final DeviceRepository _repository = DeviceRepository();

  FullControlViewModel({required this.serial});

  WsClient? _wsClient;
  StreamSubscription? _streamSub;
  Timer? _pingTimer;
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

    state.value = ConnState.connectingWs;

    try {
      _wsClient = await _repository
          .connectScreenStream(serial: serial)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      state.value = ConnState.error;
      error.value = 'WebSocket connection failed: $e';
      return;
    }

    state.value = ConnState.streaming;

    _streamSub = _wsClient!.stream.listen(
      (event) {
        if (event is Uint8List) {
          frame.value = event;
        } else if (event is List<int>) {
          frame.value = Uint8List.fromList(event);
        }
      },
      onDone: () {
        dev.log('WS stream done');
        state.value = ConnState.error;
        error.value = 'Connection closed by server';
      },
      onError: (e) {
        dev.log('WS stream error: $e');
        state.value = ConnState.error;
        error.value = 'Stream error: $e';
      },
    );

    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      try {
        _wsClient?.send(jsonEncode({'type': 'ping'}));
      } catch (_) {}
    });
  }

  void sendTouch(String type, Offset localPosition, Size widgetSize) {
    if (_screenInfo == null || _wsClient == null) return;

    final deviceW = _screenInfo!.width.toDouble();
    final deviceH = _screenInfo!.height.toDouble();
    final deviceAspect = deviceW / deviceH;
    final widgetAspect = widgetSize.width / widgetSize.height;

    double imgW, imgH, imgX, imgY;
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

    if (xP < 0 || xP > 1 || yP < 0 || yP > 1) return;

    _wsClient!.send(jsonEncode({'type': type, 'xP': xP, 'yP': yP}));
  }

  void sendKeyEvent(int keycode) {
    _wsClient?.send(jsonEncode({
      'type': 'keyEvent',
      'data': {'eventNumber': keycode},
    }));
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    await _repository.sendText(serial: serial, text: text);
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _streamSub?.cancel();
    _streamSub = null;
    _wsClient?.close();
    _wsClient = null;
    frame.value = null;
  }

  void dispose() {
    _cleanup();
    state.dispose();
    frame.dispose();
    error.dispose();
  }
}
