import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:fast_bridge_front/data/http/ws_client.dart';
import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/repositories/device_repository.dart';
import 'package:flutter/material.dart';

enum _ConnState { idle, fetchingInfo, connectingWs, streaming, error }

class FullControlWindow extends StatefulWidget {
  const FullControlWindow({super.key, required this.serial});
  final String serial;

  @override
  State<FullControlWindow> createState() => _FullControlWindowState();
}

class _FullControlWindowState extends State<FullControlWindow> {
  final DeviceRepository _repository = DeviceRepository();
  WsClient? _wsClient;
  StreamSubscription? _streamSub;
  final ValueNotifier<Uint8List?> _frameNotifier = ValueNotifier(null);
  Timer? _pingTimer;
  ScreenInfo? _screenInfo;
  _ConnState _state = _ConnState.idle;
  String? _error;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    _cleanup();
    if (mounted) setState(() { _state = _ConnState.fetchingInfo; _error = null; });

    try {
      _screenInfo = await _repository.getScreenInfo(serial: widget.serial)
          .timeout(const Duration(seconds: 8));
      dev.log('ScreenInfo: ${_screenInfo!.width}x${_screenInfo!.height}');
    } catch (e) {
      if (mounted) setState(() { _state = _ConnState.error; _error = 'Failed to get screen info: $e'; });
      return;
    }

    if (mounted) setState(() { _state = _ConnState.connectingWs; });

    try {
      _wsClient = await _repository.connectScreenStream(serial: widget.serial)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (mounted) setState(() { _state = _ConnState.error; _error = 'WebSocket connection failed: $e'; });
      return;
    }

    if (mounted) setState(() { _state = _ConnState.streaming; });

    _streamSub = _wsClient!.stream.listen(
      (event) {
        if (event is Uint8List) {
          _frameNotifier.value = event;
        } else if (event is List<int>) {
          _frameNotifier.value = Uint8List.fromList(event);
        }
        // String messages (e.g. pong) are ignored for rendering
      },
      onDone: () {
        dev.log('WS stream done');
        if (mounted) setState(() { _state = _ConnState.error; _error = 'Connection closed by server'; });
      },
      onError: (e) {
        dev.log('WS stream error: $e');
        if (mounted) setState(() { _state = _ConnState.error; _error = 'Stream error: $e'; });
      },
    );

    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      try { _wsClient?.send(jsonEncode({'type': 'ping'})); } catch (_) {}
    });
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _streamSub?.cancel();
    _streamSub = null;
    _wsClient?.close();
    _wsClient = null;
    _frameNotifier.value = null;
  }

  void _sendTouch(String type, Offset localPosition, Size widgetSize) {
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

    _wsClient!.send(jsonEncode({
      'type': type,
      'xP': xP,
      'yP': yP,
    }));
  }

  void _sendKeyEvent(int keycode) {
    _wsClient?.send(jsonEncode({
      'type': 'keyEvent',
      'data': {'eventNumber': keycode},
    }));
  }

  void _sendText(String text) {
    if (text.isEmpty) return;
    _wsClient?.send(jsonEncode({
      'type': 'text',
      'detail': text,
    }));
  }

  @override
  void dispose() {
    _cleanup();
    _textController.dispose();
    _frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cast_connected_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(widget.serial, style: const TextStyle(fontSize: 15)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (_state == _ConnState.streaming ? Colors.green : Colors.red).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8,
                    color: _state == _ConnState.streaming ? Colors.green : Colors.red),
                const SizedBox(width: 6),
                Text(
                  _state == _ConnState.streaming ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: _state == _ConnState.streaming ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    switch (_state) {
      case _ConnState.idle:
      case _ConnState.fetchingInfo:
        return Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary)),
            const SizedBox(height: 16),
            Text('Getting device info...', style: theme.textTheme.bodyMedium),
          ],
        ));
      case _ConnState.connectingWs:
        return Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary)),
            const SizedBox(height: 16),
            Text('Connecting to device stream...', style: theme.textTheme.bodyMedium),
          ],
        ));
      case _ConnState.error:
        return Center(child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: cs.error, size: 48),
                const SizedBox(height: 14),
                Text(_error ?? 'Unknown error',
                    style: TextStyle(color: cs.error), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ));
      case _ConnState.streaming:
        return Column(
          children: [
            Expanded(child: _buildVideoArea()),
            _buildControlBar(),
          ],
        );
    }
  }

  Widget _buildVideoArea() {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: _frameNotifier,
      builder: (context, frame, _) {
        if (frame == null) {
          final cs = Theme.of(context).colorScheme;
          return Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary)),
              const SizedBox(height: 16),
              Text('Waiting for video frames...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Listener(
              onPointerDown: (e) => _sendTouch('touchDown', e.localPosition, widgetSize),
              onPointerMove: (e) => _sendTouch('touchMove', e.localPosition, widgetSize),
              onPointerUp: (e) => _sendTouch('touchUp', e.localPosition, widgetSize),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    frame,
                    gaplessPlayback: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControlBar() {
    final cs = Theme.of(context).colorScheme;

    Widget ctrlBtn({required IconData icon, required String tip, required VoidCallback onTap}) {
      return Tooltip(
        message: tip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          ctrlBtn(icon: Icons.arrow_back_rounded, tip: 'Back', onTap: () => _sendKeyEvent(4)),
          ctrlBtn(icon: Icons.circle_outlined, tip: 'Home', onTap: () => _sendKeyEvent(3)),
          ctrlBtn(icon: Icons.crop_square_rounded, tip: 'Recent', onTap: () => _sendKeyEvent(187)),
          Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 4),
              color: cs.primary.withAlpha(40)),
          ctrlBtn(icon: Icons.volume_down_rounded, tip: 'Vol −', onTap: () => _sendKeyEvent(25)),
          ctrlBtn(icon: Icons.volume_up_rounded, tip: 'Vol +', onTap: () => _sendKeyEvent(24)),
          ctrlBtn(icon: Icons.power_settings_new_rounded, tip: 'Power', onTap: () => _sendKeyEvent(26)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type text...',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(Icons.send_rounded, size: 18, color: cs.primary),
                  onPressed: () {
                    _sendText(_textController.text);
                    _textController.clear();
                  },
                ),
              ),
              onSubmitted: (text) {
                _sendText(text);
                _textController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}