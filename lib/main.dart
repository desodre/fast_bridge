import 'package:fast_bridge_front/view/pages/home/home_page.dart';
import 'package:fast_bridge_front/view/pages/device_page/device_page.dart';
import 'package:fast_bridge_front/view/pages/file_manager/file_manager_page.dart';
import 'package:fast_bridge_front/view/pages/full_control_window/full_control_window.dart';
import 'package:fast_bridge_front/view/pages/settings/settings_page.dart';
import 'package:fast_bridge_front/view/ui/theme.dart';
import 'package:flutter/material.dart';
// import 'dart:io';
// import 'dart:developer' as dev;

// void startBackend() async {
//   try {
//     Process backProcess = await Process.start('./lib/exec/adb_sidecar_api', []);
//     dev.log("Backend started");
//     dev.log("Backend PID: ${backProcess.pid}");
//   } catch (e) {
//     dev.log('Erro ao inciar o back');
//     dev.log(e.toString());
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // startBackend();
  runApp(FastBridgeApp());
}

class FastBridgeApp extends StatelessWidget {
  const FastBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Fast Bridge',
          debugShowCheckedModeBanner: false,
          theme: customLightTheme,
          darkTheme: customTheme,
          themeMode: mode,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');

            if (uri.pathSegments.length == 1 && uri.pathSegments[0] == 'settings') {
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
                builder: (BuildContext context) => FullControlWindow(serial: serial),
                settings: settings,
              );
            }

            if (uri.pathSegments.length == 3 &&
                uri.pathSegments[0] == 'device' &&
                uri.pathSegments[2] == 'file_manager') {
              final serial = uri.pathSegments[1];
              return MaterialPageRoute(
                builder: (BuildContext context) => FileManagerPage(serial: serial),
                settings: settings,
              );
            }

            if (uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'device') {
              final serial = uri.pathSegments.last;

              return MaterialPageRoute(
                builder: (BuildContext context) => DevicePage(serial: serial),
                settings: settings,
              );
            }

            return MaterialPageRoute(
              builder: (context) => HomePage(),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
