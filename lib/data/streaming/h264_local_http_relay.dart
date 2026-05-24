import 'dart:async';
import 'dart:io';

class H264LocalHttpRelay {
  H264LocalHttpRelay({
    required Stream<List<int>> source,
    this.path = '/live.h264',
  }) : _source = source;

  final Stream<List<int>> _source;
  final String path;
  final Set<HttpResponse> _clients = {};

  HttpServer? _server;
  StreamSubscription<List<int>>? _sourceSubscription;
  StreamSubscription<HttpRequest>? _serverSubscription;

  bool get isRunning => _server != null;

  Uri get url {
    final server = _server;
    if (server == null) {
      throw StateError('Local relay server not started.');
    }
    return Uri.parse('http://127.0.0.1:${server.port}$path');
  }

  Future<Uri> start() async {
    if (_server != null) {
      return url;
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    _serverSubscription = server.listen(_handleRequest);
    _sourceSubscription = _source.listen(
      _broadcastChunk,
      onError: _handleSourceError,
      onDone: _closeAllClients,
      cancelOnError: false,
    );
    return url;
  }

  void _handleRequest(HttpRequest request) {
    final response = request.response;
    if (request.uri.path != path || request.method != 'GET') {
      response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      unawaited(response.close());
      return;
    }

    response.headers
      ..set(HttpHeaders.contentTypeHeader, 'video/h264')
      ..set(
        HttpHeaders.cacheControlHeader,
        'no-cache, no-store, must-revalidate',
      )
      ..set(HttpHeaders.connectionHeader, 'keep-alive')
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*');
    response.bufferOutput = false;
    response.headers.chunkedTransferEncoding = true;

    _clients.add(response);
    response.done.whenComplete(() => _clients.remove(response));
  }

  void _broadcastChunk(List<int> chunk) {
    if (_clients.isEmpty) {
      return;
    }

    final deadClients = <HttpResponse>[];
    for (final client in _clients) {
      try {
        client.add(chunk);
      } catch (_) {
        deadClients.add(client);
      }
    }

    if (deadClients.isEmpty) {
      return;
    }

    for (final deadClient in deadClients) {
      _clients.remove(deadClient);
      unawaited(deadClient.close());
    }
  }

  void _handleSourceError(Object error, StackTrace stackTrace) {
    for (final client in _clients) {
      client.addError(error, stackTrace);
      unawaited(client.close());
    }
    _clients.clear();
  }

  void _closeAllClients() {
    for (final client in _clients) {
      unawaited(client.close());
    }
    _clients.clear();
  }

  Future<void> stop() async {
    _closeAllClients();
    await _sourceSubscription?.cancel();
    await _serverSubscription?.cancel();
    await _server?.close(force: true);
    _sourceSubscription = null;
    _serverSubscription = null;
    _server = null;
  }
}
