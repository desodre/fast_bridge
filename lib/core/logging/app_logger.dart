import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final _writer = _DailyLogWriter();
  Talker? _talker;
  StreamSubscription<LogRecord>? _rootLoggingSubscription;
  bool _initialized = false;

  Talker get talker {
    return _talker ??= Talker(
      settings: TalkerSettings(
        enabled: true,
        useHistory: true,
        useConsoleLogs: true,
        maxHistoryItems: 5000,
      ),
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _writer.initialize();
    _talker = Talker(
      observer: _PersistentTalkerObserver(_writer),
      settings: TalkerSettings(
        enabled: true,
        useHistory: true,
        useConsoleLogs: true,
        maxHistoryItems: 5000,
      ),
    );
    _bindPackageLogging();
    _initialized = true;

    info(
      'Sistema de logs inicializado',
      context: 'bootstrap',
      payload: 'Persistência diária ativa em ${_writer.logDirectory.path}',
    );
  }

  Future<void> dispose() async {
    await _rootLoggingSubscription?.cancel();
    await _writer.dispose();
  }

  Future<void> cleanupOldLogs() => _writer.deleteLogsOlderThan(days: 7);

  Future<File> exportLogsAsZip() => _writer.exportLastDaysAsZip(days: 3);

  void debug(
    String message, {
    String context = 'app',
    Object? payload,
    int maxPayloadChars = 200,
  }) {
    talker.debug(
      _formatMessage(
        message,
        context: context,
        payload: payload,
        maxPayloadChars: maxPayloadChars,
      ),
    );
  }

  void verbose(
    String message, {
    String context = 'app',
    Object? payload,
    int maxPayloadChars = 200,
  }) {
    talker.verbose(
      _formatMessage(
        message,
        context: context,
        payload: payload,
        maxPayloadChars: maxPayloadChars,
      ),
    );
  }

  void info(
    String message, {
    String context = 'app',
    Object? payload,
    int maxPayloadChars = 200,
  }) {
    talker.info(
      _formatMessage(
        message,
        context: context,
        payload: payload,
        maxPayloadChars: maxPayloadChars,
      ),
    );
  }

  void warning(
    String message, {
    String context = 'app',
    Object? error,
    StackTrace? stackTrace,
    Object? payload,
    int maxPayloadChars = 200,
  }) {
    talker.warning(
      _formatMessage(
        message,
        context: context,
        payload: payload,
        maxPayloadChars: maxPayloadChars,
      ),
      error,
      stackTrace,
    );
  }

  void error(
    String message, {
    String context = 'app',
    Object? error,
    StackTrace? stackTrace,
    String? diagnostics,
    Object? payload,
    int maxPayloadChars = 200,
  }) {
    final composedMessage = _formatMessage(
      message,
      context: context,
      payload: payload,
      maxPayloadChars: maxPayloadChars,
    );
    if (diagnostics == null || diagnostics.trim().isEmpty) {
      talker.error(composedMessage, error, stackTrace);
      return;
    }

    talker.error(
      '$composedMessage\n--- Android diagnostics ---\n${_trim(diagnostics, 3000)}',
      error,
      stackTrace,
    );
  }

  void fatal(
    String message, {
    String context = 'app',
    Object? error,
    StackTrace? stackTrace,
    String? diagnostics,
  }) {
    final composedMessage = '[FATAL][$context] $message';
    if (diagnostics == null || diagnostics.trim().isEmpty) {
      talker.critical(composedMessage, error, stackTrace);
      return;
    }
    talker.critical(
      '$composedMessage\n--- Android diagnostics ---\n${_trim(diagnostics, 3000)}',
      error,
      stackTrace,
    );
  }

  void _bindPackageLogging() {
    Logger.root.level = Level.ALL;
    _rootLoggingSubscription = Logger.root.onRecord.listen((record) {
      final message =
          '[package:logging][${record.loggerName}] ${record.message}';
      if (record.level >= Level.SEVERE) {
        error(
          message,
          context: 'package',
          error: record.error,
          stackTrace: record.stackTrace,
        );
      } else if (record.level >= Level.WARNING) {
        warning(
          message,
          context: 'package',
          error: record.error,
          stackTrace: record.stackTrace,
        );
      } else if (record.level >= Level.INFO) {
        info(message, context: 'package');
      } else {
        debug(message, context: 'package');
      }
    });
  }

  String _formatMessage(
    String message, {
    required String context,
    Object? payload,
    required int maxPayloadChars,
  }) {
    if (payload == null) {
      return '[$context] $message';
    }
    final safePayload = _sanitizePayload(payload, maxPayloadChars);
    return '[$context] $message | payload=$safePayload';
  }

  String _sanitizePayload(Object payload, int maxPayloadChars) {
    // Never expand raw binary buffers (e.g. H.264 NAL units from tcp:9009).
    if (payload is List<int>) {
      return '<binary payload omitted (${payload.length} bytes)>';
    }

    if (payload is String) {
      return _trim(payload, maxPayloadChars);
    }

    return _trim(payload.toString(), maxPayloadChars);
  }

  String _trim(String value, int maxChars) {
    final compact = value.replaceAll('\n', ' ').trim();
    if (compact.length <= maxChars) {
      return compact;
    }
    return '${compact.substring(0, maxChars)}...';
  }
}

class _PersistentTalkerObserver extends TalkerObserver {
  const _PersistentTalkerObserver(this._writer);

  final _DailyLogWriter _writer;

  @override
  void onError(TalkerError err) {
    unawaited(_writer.write(err));
  }

  @override
  void onException(TalkerException err) {
    unawaited(_writer.write(err));
  }

  @override
  void onLog(TalkerData log) {
    unawaited(_writer.write(log));
  }
}

class _DailyLogWriter {
  late final Directory logDirectory;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> initialize() async {
    logDirectory = await _resolveLogDirectory();
    await deleteLogsOlderThan(days: 7);
  }

  Future<void> dispose() async {
    await _writeQueue;
  }

  Future<void> write(TalkerData data) {
    return _enqueue(() async {
      final file = await _fileForDate(data.time);
      final line = _serializeLine(data);
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    });
  }

  Future<void> deleteLogsOlderThan({required int days}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final files = await _logFiles();
    for (final file in files) {
      final date = _extractDateFromFileName(file.uri.pathSegments.last);
      if (date == null) {
        continue;
      }
      if (date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))) {
        await file.delete();
      }
    }
  }

  Future<File> exportLastDaysAsZip({required int days}) async {
    final files = await _logFiles();
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final selected = files.where((file) {
      final date = _extractDateFromFileName(file.uri.pathSegments.last);
      if (date == null) {
        return false;
      }
      return !date.isBefore(cutoff);
    }).toList()..sort((a, b) => a.path.compareTo(b.path));

    final desktopDir = await _resolveDesktopDirectory();
    final zipFile = File(
      '${desktopDir.path}${Platform.pathSeparator}'
      'fast_bridge_logs_${_stampForFile(DateTime.now())}.zip',
    );
    if (zipFile.existsSync()) {
      await zipFile.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    for (final file in selected) {
      encoder.addFile(file, file.uri.pathSegments.last);
    }
    encoder.close();

    return zipFile;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _writeQueue = _writeQueue.then((_) => action()).catchError((_) {});
    return _writeQueue;
  }

  Future<Directory> _resolveLogDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final home = Platform.environment['HOME'];
    final targetPath = (home != null && home.isNotEmpty)
        ? '$home${Platform.pathSeparator}.fast_bridge${Platform.pathSeparator}logs'
        : '${supportDir.path}${Platform.pathSeparator}.fast_bridge'
              '${Platform.pathSeparator}logs';
    final directory = Directory(targetPath);
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _resolveDesktopDirectory() async {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final desktop = Directory('$home${Platform.pathSeparator}Desktop');
      if (desktop.existsSync()) {
        return desktop;
      }
      return Directory(home);
    }

    return getApplicationSupportDirectory();
  }

  Future<List<File>> _logFiles() async {
    if (!logDirectory.existsSync()) {
      return const [];
    }

    final entities = logDirectory.listSync().whereType<File>().toList();
    return entities
        .where(
          (file) =>
              file.path.endsWith('.log') &&
              file.uri.pathSegments.last.startsWith('fast_bridge_'),
        )
        .toList();
  }

  Future<File> _fileForDate(DateTime date) async {
    final fileName = 'fast_bridge_${_dateForFile(date)}.log';
    final path = '${logDirectory.path}${Platform.pathSeparator}$fileName';
    final file = File(path);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    return file;
  }

  String _serializeLine(TalkerData data) {
    final timestamp = data.time.toIso8601String();
    final level = (data.logLevel?.name ?? data.title ?? 'log').toUpperCase();
    final message = (data.message ?? '').trim();
    final error = data.error?.toString();
    final exception = data.exception?.toString();
    final stack = data.stackTrace?.toString();
    final buffer = StringBuffer('$timestamp [$level] $message');
    if (error != null && error.isNotEmpty) {
      buffer.write(' | error=$error');
    }
    if (exception != null && exception.isNotEmpty) {
      buffer.write(' | exception=$exception');
    }
    if (stack != null && stack.isNotEmpty) {
      buffer.write('\n$stack');
    }
    return buffer.toString();
  }

  DateTime? _extractDateFromFileName(String fileName) {
    final match = RegExp(
      r'^fast_bridge_(\d{4})-(\d{2})-(\d{2})\.log$',
    ).firstMatch(fileName);
    if (match == null) {
      return null;
    }

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _dateForFile(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _stampForFile(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');
    return '$y$m$d-$hh$mm$ss';
  }
}
