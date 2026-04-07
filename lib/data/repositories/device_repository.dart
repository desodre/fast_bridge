import 'dart:convert';
import 'dart:typed_data';
import 'package:fast_bridge_front/data/http/ws_client.dart';
import 'package:fast_bridge_front/data/http/http_client.dart';
import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';
import 'package:fast_bridge_front/data/models/fetch_device_info.dart';


class DeviceRepository {
  final String baseUrl = 'http://127.0.0.1:8000';
  final client = HttpClient();

  Future<List<DeviceInfo>> getDevices() async {
    final response = await client.get(url: '$baseUrl/devices');

    if (response.statusCode == 200) {
      return FetchDeviceInfo.fromList(jsonDecode(response.body)).deviceInfos;
    }

    throw Exception('Erro on device list');
  }

  Future<String> sendShell(String serial, List<String> commands) async {
    final response = await client.post(
      url:'$baseUrl/$serial',
      body: jsonEncode(commands),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['stdout'];
    }

    throw Exception('Erro on send command');
  }

  Future<Uint8List> getScreenshot({required String serial, int id = 0}) async {
    final response = await client.get(url: '$baseUrl/device/$serial/screenshot?display_id=$id');
    if (response.statusCode == 200){
      return response.bodyBytes;
    }else{
      throw Exception('Erro on get screenshot');
    }
    
  }

  Future<UiHierarchy> getUiHierarchy({required String serial, String format = 'xml'}) async {
    final response = await client.get(url: '$baseUrl/device/$serial/window_dump?format=$format');
    if (response.statusCode == 200){
      return UiHierarchy.fromXmlString(response.body);
    }else{
      throw Exception('Erro on get ui hierarchy');
    }

  }

  Future<ScreenInfo> getScreenInfo({required String serial}) async {
    final response = await client.get(url: '$baseUrl/device/$serial/screen_info');
    if (response.statusCode == 200){
      return ScreenInfo.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Erro on get screen info');
    }    
  }

  Future<WsClient> connectScreenStream({required String serial}) async {
    final wsClient = WsClient();
    await wsClient.connect(url: 'ws://127.0.0.1:8000/ws/device/$serial/control');
    return wsClient;
  }

  Future<bool> healthCheck() async {
    try {
      final response = await client.get(url: '$baseUrl/health')
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
