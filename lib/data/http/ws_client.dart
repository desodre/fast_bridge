import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class IWsClient {
  Future<void> connect({required String url});
  Stream get stream;
  void send(dynamic data);
  void close();
  bool get isConnected;
}

class WsClient implements IWsClient {
  WebSocketChannel? _channel;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect({required String url}) async {
    _channel = WebSocketChannel.connect(
      Uri.parse(url),
    );
    await _channel!.ready;
    _connected = true;
    log('WS CONNECTED: $url');
  }

  @override
  Stream get stream {
    if (_channel == null) throw Exception('WebSocket not connected');
    return _channel!.stream;
  }

  @override
  void send(dynamic data) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(data);
  }

  @override
  void close() {
    _connected = false;
    _channel?.sink.close();
    _channel = null;
    log('WS CLOSED');
  }
}