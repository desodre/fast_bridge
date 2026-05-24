import 'dart:async';
import 'dart:ui';

import 'package:fast_bridge_front/core/logging/app_logger.dart';
import 'package:fast_bridge_front/view/pages/home/home_page.dart';
import 'package:fast_bridge_front/view/pages/device_page/device_page.dart';
import 'package:fast_bridge_front/view/pages/file_manager/file_manager_page.dart';
import 'package:fast_bridge_front/view/pages/full_control_window/full_control_window.dart';
import 'package:fast_bridge_front/view/pages/settings/settings_page.dart';
import 'package:fast_bridge_front/view/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:toastification/toastification.dart';
import 'core/services/device_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.instance.initialize();
  await AppLogger.instance.cleanupOldLogs();
  MediaKit.ensureInitialized();

  // Inicia o monitoramento de dispositivos
  DeviceMonitorService().startMonitoring();

  FlutterError.onError = (details) {
    AppLogger.instance.error(
      'Flutter framework error',
      context: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.fatal(
      'Uncaught platform dispatcher error',
      context: 'flutter',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  runZonedGuarded(
    () => runApp(const FastBridgeApp()),
    (error, stackTrace) => AppLogger.instance.fatal(
      'Uncaught zoned error',
      context: 'flutter',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}

class FastBridgeApp extends StatelessWidget {
  const FastBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, _) {
          return TalkerWrapper(
            talker: AppLogger.instance.talker,
            child: MaterialApp(
              title: 'Fast Bridge',
              debugShowCheckedModeBanner: false,
              theme: customLightTheme,
              darkTheme: customTheme,
              themeMode: mode,
              initialRoute: '/',
              navigatorObservers: [
                TalkerRouteObserver(AppLogger.instance.talker),
              ],
              onGenerateRoute: (settings) {
                final uri = Uri.parse(settings.name ?? '/');

                if (uri.pathSegments.length == 1 &&
                    uri.pathSegments[0] == 'logs') {
                  return MaterialPageRoute(
                    builder: (context) => TalkerScreen(
                      talker: AppLogger.instance.talker,
                      appBarTitle: 'Fast Bridge Logs',
                    ),
                    settings: settings,
                  );
                }

                if (uri.pathSegments.length == 1 &&
                    uri.pathSegments[0] == 'settings') {
                  return MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                    settings: settings,
                  );
                }

                if (uri.pathSegments.length == 3 &&
                    uri.pathSegments[0] == 'device' &&
                    uri.pathSegments[2] == 'full_control') {
                  final serial = uri.pathSegments[1];
                  return MaterialPageRoute(
                    builder: (BuildContext context) =>
                        FullControlWindow(serial: serial),
                    settings: settings,
                  );
                }

                if (uri.pathSegments.length == 3 &&
                    uri.pathSegments[0] == 'device' &&
                    uri.pathSegments[2] == 'file_manager') {
                  final serial = uri.pathSegments[1];
                  return MaterialPageRoute(
                    builder: (BuildContext context) =>
                        FileManagerPage(serial: serial),
                    settings: settings,
                  );
                }

                if (uri.pathSegments.length == 2 &&
                    uri.pathSegments.first == 'device') {
                  final serial = uri.pathSegments.last;

                  return MaterialPageRoute(
                    builder: (BuildContext context) =>
                        DevicePage(serial: serial),
                    settings: settings,
                  );
                }

                return MaterialPageRoute(
                  builder: (context) => HomePage(),
                  settings: settings,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
