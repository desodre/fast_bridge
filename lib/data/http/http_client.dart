import 'dart:developer';
import 'package:http/http.dart' as http;

abstract class IhttpClient {
  Future get({required String url});
  Future post({required String url, required String body});
}

class HttpClient implements IhttpClient {
  final client = http.Client();

  @override
  Future<http.Response> get({required String url}) async {
    final response = await client.get(Uri.parse(url));
    log('GET: $url STATUS: ${response.statusCode}');
    return response;
  }

  @override
  Future<http.Response> post({required String url, required String body}) async {
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    log('POST: $url STATUS: ${response.statusCode}');
    return response;
  }
}
