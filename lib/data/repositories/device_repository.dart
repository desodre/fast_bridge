import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adb_utils/adb_utils.dart' as adb;
import 'package:fast_bridge_front/core/logging/app_logger.dart';
import 'package:fast_bridge_front/data/models/fetch_device_info.dart';
import 'package:fast_bridge_front/data/models/file_node.dart';
import 'package:fast_bridge_front/data/models/screen_info.dart';

class DeviceRepository {
  DeviceRepository._internal();

  static final DeviceRepository _instance = DeviceRepository._internal();

  factory DeviceRepository() => _instance;

  final adb.AdbClient _adb = adb.AdbClient();
  final AppLogger _logger = AppLogger.instance;
  final Map<String, adb.AdbDevice> _deviceCache = {};
  final Map<String, adb.PhantomClient> _phantomCache = {};
  final Set<String> _initializedUiAgents = {};

  Future<List<adb.DeviceInfo>> fetchDevicesSerials() async {
    final devices = await _adb.deviceList();
    _deviceCache.clear();
    _phantomCache.clear();
    _initializedUiAgents.clear();
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

  Future<adb.PhantomClient> _resolvePhantom(String serial) async {
    final cached = _phantomCache[serial];
    if (cached != null) {
      return cached;
    }

    final device = await _resolveDevice(serial);
    final resolved = device.phantom;
    _phantomCache[serial] = resolved;
    return resolved;
  }

  Future<void> initializeUiAgent(String serial) async {
    _logger.info(
      'Inicializando agente UiAutomator',
      context: 'phantom',
      payload: 'serial=$serial',
    );
    try {
      await _startUiAgent(serial);
      _initializedUiAgents.add(serial);
      _logger.info(
        'Agente UiAutomator inicializado',
        context: 'phantom',
        payload: 'serial=$serial',
      );
    } catch (error, stackTrace) {
      final diagnostic = await _collectAndroidRuntimeDiagnostics(serial);
      _logger.error(
        'Falha ao inicializar agente UiAutomator',
        context: 'phantom',
        error: error,
        stackTrace: stackTrace,
        diagnostics: diagnostic,
        payload: 'serial=$serial',
      );
      rethrow;
    }
  }

  Future<void> _startUiAgent(String serial) async {
    final phantom = await _resolvePhantom(serial);
    await phantom.startAgent();
    await Future.delayed(const Duration(seconds: 2));
    _logger.info(
      'Túnel TCP do Phantom estabelecido',
      context: 'phantom',
      payload:
          'serial=$serial hostCmd=${phantom.hostCommandPort} hostVid=${phantom.hostVideoPort} '
          'deviceCmd=${phantom.deviceCommandPort} deviceVid=${phantom.deviceVideoPort}',
    );
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

  Future<adb.UiHierarchy> getScreenHierarchy(String serial) async {
    try {
      await _ensureUiAgentReady(serial);
      final phantom = await _resolvePhantom(serial);

      const maxAttempts = 3;
      Object? lastError;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          final hierarchy = await phantom.dumpWindowHierarchy();
          _logger.debug(
            'Dump de hierarquia recebido',
            context: 'uiautomator',
            payload: 'serial=$serial rotation=${hierarchy.rotation}',
          );
          return hierarchy;
        } catch (error, stackTrace) {
          lastError = error;
          if (!_isTransientPhantomError(error) || attempt == maxAttempts) {
            final diagnostics = await _collectAndroidRuntimeDiagnostics(serial);
            _logger.error(
              'Falha ao obter hierarquia via Phantom',
              context: 'uiautomator',
              error: error,
              stackTrace: stackTrace,
              diagnostics: diagnostics,
              payload: 'serial=$serial attempt=$attempt/$maxAttempts',
            );
            break;
          }

          _logger.warning(
            'Falha transitória no socket do Phantom, tentando reiniciar agente',
            context: 'uiautomator',
            payload: 'serial=$serial attempt=$attempt/$maxAttempts',
          );
          await _startUiAgent(serial);
        }
      }

      throw Exception(
        'Failed to load screen hierarchy via Phantom: $lastError',
      );
    } catch (error, stackTrace) {
      _logger.warning(
        'Fallback para uiautomator dump via shell',
        context: 'uiautomator',
        error: error,
        stackTrace: stackTrace,
        payload: 'serial=$serial',
      );
      return _getScreenHierarchyViaShell(serial);
    }
  }

  Future<adb.UiHierarchy> _getScreenHierarchyViaShell(String serial) async {
    final device = await _resolveDevice(serial);
    const remotePath = '/sdcard/window_dump.xml';
    await device.shell(
      'uiautomator dump $remotePath >/dev/null 2>&1 || uiautomator dump $remotePath',
    );
    final xmlDump = await device.shell('cat $remotePath');
    return adb.UiHierarchy.fromXmlString(xmlDump);
  }

  Future<bool> clickElementByText(String serial, String text) async {
    final phantom = await _resolvePhantom(serial);
    return phantom.clickByText(text);
  }

  Future<adb.UiHierarchy> getUiHierarchy({
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

  Stream<List<int>> getH264VideoStream({required String serial}) {
    final controller = StreamController<List<int>>();
    StreamSubscription<List<int>>? streamSubscription;

    controller.onListen = () async {
      try {
        await _ensureUiAgentReady(serial);
        final phantom = await _resolvePhantom(serial);
        final videoStream = await phantom.startVideoStream();
        _logger.info(
          'Stream de vídeo iniciada',
          context: 'video',
          payload: 'serial=$serial hostVid=${phantom.hostVideoPort}',
        );

        // Never log raw video chunks (List<int>) from Phantom TCP stream.
        streamSubscription = videoStream.listen(
          controller.add,
          onError: (error, stackTrace) {
            _logger.error(
              'Erro crítico no socket do stream H.264',
              context: 'video',
              error: error,
              stackTrace: stackTrace,
              payload: 'serial=$serial',
            );
            controller.addError(error, stackTrace);
          },
          onDone: () async {
            _logger.info(
              'Stream de vídeo encerrada',
              context: 'video',
              payload: 'serial=$serial',
            );
            if (!controller.isClosed) {
              await controller.close();
            }
          },
          cancelOnError: true,
        );
      } catch (error, stackTrace) {
        final diagnostics = await _collectAndroidRuntimeDiagnostics(serial);
        _logger.error(
          'Falha ao iniciar stream H.264',
          context: 'video',
          error: error,
          stackTrace: stackTrace,
          diagnostics: diagnostics,
          payload: 'serial=$serial',
        );
        controller.addError(error, stackTrace);
        await controller.close();
      }
    };

    controller.onCancel = () async {
      await streamSubscription?.cancel();
    };

    return controller.stream;
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

  Future<String?> _collectAndroidRuntimeDiagnostics(String serial) async {
    try {
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'logcat -d -s AndroidRuntime PhantomServer | tail -n 30',
      ]);
      final stdoutText = _decodeProcessOutput(result.stdout);
      final stderrText = _decodeProcessOutput(result.stderr);
      final combined = [
        stdoutText.trim(),
        stderrText.trim(),
      ].where((chunk) => chunk.isNotEmpty).join('\n');
      if (combined.isEmpty) {
        return null;
      }
      return combined;
    } catch (error, stackTrace) {
      _logger.warning(
        'Falha ao coletar logcat de diagnóstico',
        context: 'diagnostics',
        error: error,
        stackTrace: stackTrace,
        payload: 'serial=$serial',
      );
      return null;
    }
  }

  String _decodeProcessOutput(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is List<int>) {
      return utf8.decode(value, allowMalformed: true);
    }
    return value.toString();
  }
}
