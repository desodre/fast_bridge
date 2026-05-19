import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adb_utils/adb_utils.dart' as adb;
// ignore: implementation_imports
import 'package:adb_utils/src/phantom/phantom_client.dart';
import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/data/models/file_node.dart';
import 'package:fast_bridge_front/data/models/screen_info.dart';
import 'package:fast_bridge_front/data/models/ui_hierarchy.dart';

extension _PhantomAccess on adb.AdbDevice {
  PhantomClient get phantom => PhantomClient(device: this);
}

class DeviceRepository {
  DeviceRepository._internal();

  static final DeviceRepository _instance = DeviceRepository._internal();

  factory DeviceRepository() => _instance;

  final adb.AdbClient _adb = adb.AdbClient();
  final Map<String, adb.AdbDevice> _deviceCache = {};
  final Set<String> _initializedUiAgents = {};
  (String targetApkPath, String agentApkPath)? _phantomApkPaths;

  Future<List<adb.DeviceInfo>> fetchDevicesSerials() async {
    final devices = await _adb.deviceList();
    _deviceCache.clear();
    for (final deviceInfo in devices) {
      _deviceCache[deviceInfo.serial] = await _adb.device(
        serial: deviceInfo.serial,
      );
    }
    return devices;
  }

  Future<List<DeviceInfo>> getDevices() async {
    final devices = await fetchDevicesSerials();
    return devices
        .map(
          (device) => DeviceInfo.fromAdb(
            serial: device.serial,
            state: device.state.name,
            product: device.product,
            model: device.model,
            device: device.device,
          ),
        )
        .toList();
  }

  Future<adb.AdbDevice> _resolveDevice(String serial) async {
    final cached = _deviceCache[serial];
    if (cached != null) {
      return cached;
    }

    final resolved = await _adb.device(serial: serial);
    _deviceCache[serial] = resolved;
    return resolved;
  }

  Future<void> initializeUiAgent(String serial) async {
    await _startUiAgent(serial, forceRestart: true);
    _initializedUiAgents.add(serial);
  }

  Future<void> _startUiAgent(String serial, {bool forceRestart = false}) async {
    final device = await _resolveDevice(serial);
    final (targetApkPath, agentApkPath) = await _resolveBundledPhantomApks();
    if (forceRestart) {
      try {
        await device.forwardRemove('tcp:9008');
      } catch (_) {
        // ignore forward cleanup errors; startAgent will set it again.
      }
    }
    await device.phantom.startAgent(targetApkPath, agentApkPath);
    await Future.delayed(const Duration(seconds: 2));
  }

  bool _isTransientPhantomError(Object error) {
    final message = error.toString();
    return message.contains('Empty response from Phantom agent') ||
        message.contains('Connection refused') ||
        message.contains('Connection reset') ||
        message.contains('timed out');
  }

  Future<void> _ensureUiAgentReady(String serial) async {
    if (_initializedUiAgents.contains(serial)) {
      return;
    }
    await initializeUiAgent(serial);
  }

  Future<(String targetApkPath, String agentApkPath)>
  _resolveBundledPhantomApks() async {
    final cached = _phantomApkPaths;
    if (cached != null) {
      return cached;
    }

    final targetApk = await _resolveAdbUtilsApkPath('target.apk');
    final agentApk = await _resolveAdbUtilsApkPath('agent.apk');

    if (!File(targetApk).existsSync() || !File(agentApk).existsSync()) {
      throw Exception(
        'Bundled Phantom APKs were not found in adb_utils package.',
      );
    }

    _phantomApkPaths = (targetApk, agentApk);
    return _phantomApkPaths!;
  }

  Future<String> _resolveAdbUtilsApkPath(String apkName) async {
    // 1) Prefer package_config when running from project workspace.
    final packageConfig = File('.dart_tool/package_config.json');
    if (packageConfig.existsSync()) {
      final configJson =
          jsonDecode(await packageConfig.readAsString())
              as Map<String, dynamic>;
      final packages = (configJson['packages'] as List<dynamic>? ?? const []);
      String? rootUriRaw;
      for (final pkg in packages) {
        if (pkg is Map<String, dynamic> && pkg['name'] == 'adb_utils') {
          rootUriRaw = pkg['rootUri'] as String?;
          break;
        }
      }
      if (rootUriRaw != null && rootUriRaw.isNotEmpty) {
        final normalized = rootUriRaw.endsWith('/')
            ? rootUriRaw
            : '$rootUriRaw/';
        final uri = Uri.parse(normalized);
        if (uri.scheme == 'file') {
          final rootPath = Directory.fromUri(uri).path;
          return '$rootPath/lib/src/phantom/apks/$apkName';
        }
      }
    }

    // 2) Fallback to PUB_CACHE conventional path.
    final pubCache = Platform.environment['PUB_CACHE'];
    final home = Platform.environment['HOME'];
    final base = pubCache ?? (home != null ? '$home/.pub-cache' : null);
    if (base != null) {
      return '$base/hosted/pub.dev/adb_utils-0.3.2/lib/src/phantom/apks/$apkName';
    }

    throw Exception('Could not resolve adb_utils package path for $apkName.');
  }

  Future<UiHierarchy> getScreenHierarchy(String serial) async {
    await _ensureUiAgentReady(serial);
    final device = await _resolveDevice(serial);

    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final xmlDump = await device.phantom.dumpWindow();
        return UiHierarchy.fromXmlString(xmlDump);
      } catch (error) {
        lastError = error;
        if (!_isTransientPhantomError(error) || attempt == maxAttempts) {
          rethrow;
        }

        await _startUiAgent(serial, forceRestart: true);
      }
    }

    throw Exception('Failed to load screen hierarchy: $lastError');
  }

  Future<bool> clickElementByText(String serial, String text) async {
    final device = await _resolveDevice(serial);
    return device.phantom.clickByText(text);
  }

  Future<UiHierarchy> getUiHierarchy({
    required String serial,
    String format = 'xml',
  }) async {
    return getScreenHierarchy(serial);
  }

  Future<ScreenInfo> getScreenInfo({required String serial}) async {
    final device = await _resolveDevice(serial);
    final (width, height) = await device.windowSize();
    return ScreenInfo(width: width, height: height);
  }

  Future<Uint8List> getScreenshot({required String serial, int id = 0}) async {
    final device = await _resolveDevice(serial);
    return device.screenshot();
  }

  Future<void> sendText({required String serial, required String text}) async {
    final device = await _resolveDevice(serial);
    await device.sendKeys(text);
  }

  Future<void> sendKeyEvent({
    required String serial,
    required int keycode,
  }) async {
    final device = await _resolveDevice(serial);
    await device.keyEvent('$keycode');
  }

  Future<void> tap({
    required String serial,
    required double x,
    required double y,
  }) async {
    final device = await _resolveDevice(serial);
    await device.click(x, y);
  }

  Future<String> sendShell(String serial, List<String> commands) async {
    final device = await _resolveDevice(serial);
    return device.shell(commands);
  }

  Future<FileListResponse> listFiles({
    required String serial,
    required String path,
  }) async {
    final device = await _resolveDevice(serial);
    final safePath = _escapeShellArg(path);
    final output = await device.shell('ls -la $safePath');

    final entries = output
        .split('\n')
        .map(_parseLsEntry)
        .whereType<FileNode>()
        .where((entry) => entry.name != '.' && entry.name != '..')
        .toList();

    return FileListResponse(path: path, entries: entries);
  }

  FileNode? _parseLsEntry(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('total ')) {
      return null;
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 9) {
      return null;
    }

    final permissions = parts[0];
    final owner = parts[2];
    final group = parts[3];
    final size = int.tryParse(parts[4]) ?? 0;
    final modifiedAt = '${parts[5]} ${parts[6]} ${parts[7]}';
    final nameChunk = parts.sublist(8).join(' ');

    final symlinkParts = nameChunk.split(' -> ');
    final name = symlinkParts.first.trim();
    final symlinkTarget = symlinkParts.length > 1
        ? symlinkParts.sublist(1).join(' -> ')
        : null;

    return FileNode(
      name: name,
      permissions: permissions,
      isDir: permissions.startsWith('d'),
      isSymlink: permissions.startsWith('l'),
      owner: owner,
      group: group,
      size: size,
      modifiedAt: modifiedAt,
      symlinkTarget: symlinkTarget,
    );
  }

  String _escapeShellArg(String value) {
    final escaped = value.replaceAll("'", r"'\''");
    return "'$escaped'";
  }

  Future<bool> healthCheck() async {
    try {
      final version = await _adb.serverVersion();
      return version > 0;
    } catch (_) {
      return false;
    }
  }
}
